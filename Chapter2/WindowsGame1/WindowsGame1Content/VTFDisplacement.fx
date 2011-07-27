float4x4 world;
float4x4 view;
float4x4 proj;

float maxHeight = 128;

texture displacementMap;
sampler displacementSampler = sampler_state
{
    Texture   = <displacementMap>;
    MipFilter = Point;
    MinFilter = Point;
    MagFilter = Point;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

texture waterMap;
sampler waterSampler = sampler_state
{
    Texture   = <waterMap>;
    MipFilter = Point;
    MinFilter = Point;
    MagFilter = Point;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

texture sandMap;
sampler sandSampler = sampler_state
{
    Texture   = <sandMap>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
};

texture grassMap;
sampler grassSampler = sampler_state
{
    Texture   = <grassMap>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
};

texture rockMap;
sampler rockSampler = sampler_state
{
    Texture   = <rockMap>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
};

texture snowMap;
sampler snowSampler = sampler_state
{
    Texture   = <snowMap>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
};

struct VS_INPUT {
    float4 position	: POSITION;
    float4 uv : TEXCOORD0;
};
struct VS_OUTPUT
{
    float4 position  : POSITION;
	float3 normal : NORMAL0;
    float4 uv : TEXCOORD0;
    float4 worldPos : TEXCOORD1;
    float4 textureWeights : TEXCOORD2;
	float3 light : TEXCOORD3;
};

float textureSize = 256.0f;
float texelSize =  1.0f / 256.0f; //size of one texel;

float4 tex2Dlod_bilinear( sampler texSam, float4 uv )
{
	float4 height00 = tex2Dlod(texSam, uv);
	float4 height10 = tex2Dlod(texSam, uv + float4(texelSize, 0, 0, 0)); 
	float4 height01 = tex2Dlod(texSam, uv + float4(0, texelSize, 0, 0)); 
	float4 height11 = tex2Dlod(texSam, uv + float4(texelSize , texelSize, 0, 0)); 

	float2 f = frac( uv.xy * textureSize );

	float4 tA = lerp( height00, height10, f.x );
	float4 tB = lerp( height01, height11, f.x );

	return lerp( tA, tB, f.y );
}

 
VS_OUTPUT Transform(VS_INPUT In)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
    float4x4 viewProj = mul(view, proj);
    float4x4 worldViewProj= mul(world, viewProj);
       
    
    float ground = tex2Dlod_bilinear( displacementSampler, float4(In.uv.xy,0,0)).r;
	float water = tex2Dlod_bilinear( waterSampler, float4(In.uv.xy, 0, 0) ).r;
	float height = saturate(ground);//p + water);

    In.position.y = (height * maxHeight);
	//In.position.y = water * maxHeight;
    Out.worldPos = mul(In.position, world);
    Out.position = mul( In.position , worldViewProj);
    Out.uv = In.uv;
    float4 TexWeights = 0;
    
    TexWeights.x = saturate( 1.0f - abs(height - 0) / 0.2f);
    TexWeights.y = saturate( 1.0f - abs(height - 0.3) / 0.25f);
    TexWeights.z = saturate( 1.0f - abs(height - 0.6) / 0.25f);
    TexWeights.w = saturate( 1.0f - abs(height - 0.9) / 0.25f);
    float totalWeight = TexWeights.x + TexWeights.y + TexWeights.z + TexWeights.w;
    TexWeights /=totalWeight;
	Out.textureWeights = TexWeights;

	float texel_size = 1.0 / 128.0;
	float4 g_up = 0;
	float4 g_down = 0;
	float4 g_right = 0;
	float4 g_left = 0;
	g_up.g = tex2Dlod(displacementSampler, float4(In.uv.x, In.uv.y + texel_size, 0, 0)).r;
	g_down.g = tex2Dlod(displacementSampler, float4(In.uv.x, In.uv.y, 0, 0)).r;
	g_right.r = tex2Dlod(displacementSampler, In.uv + float4(texel_size, 0, 0, 0)).r;
	g_left.r = tex2Dlod(displacementSampler, In.uv).r;
	float4 left = float4(texel_size * 2, 0, g_left.r - g_right.r, 0);
	float4 right = float4(0, texel_size * 2, g_up.g - g_down.g, 0);
	
	float3 light = normalize(float3(20, 20, 20));
	

	float4x4 worldView = mul (world, view);
	light = mul (light, worldView);
	Out.normal = normalize(mul(cross(left, right), worldView)); 
    Out.light = light;

    return Out;

}

float4 PixelShader_f(in float3 normal: NORMAL0, in float4 uv : TEXCOORD0, in float4 weights : TEXCOORD2, in float3 light : TEXCOORD3) : COLOR
{
	float4 sand = tex2D(sandSampler,uv*8);
	float4 grass = tex2D(grassSampler,uv*8);
	float4 rock = tex2D(rockSampler,uv*8);
	float4 snow = tex2D(snowSampler,uv*8);

	float4 dbg = tex2D(waterSampler, uv);
	dbg = saturate((dbg - 0.0005) * 100);

	float d = dot(normalize(light), normalize(normal)) * 0.6 + 0.3;
	float4 ret = (sand * weights.x + grass * weights.y + rock * weights.z + snow * weights.w) * 0.8;
	ret.b += dbg;
	//ret.rgb *= d;
	//ret = d;
	ret.a = 1.0f;
	return ret;

}

technique GridDraw
{
    pass P0
    {
        vertexShader = compile vs_3_0 Transform();
        pixelShader  = compile ps_3_0 PixelShader_f();
    }
}
