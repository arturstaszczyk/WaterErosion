float pixel_w = 1.0 / 512.0;
float pixel_h = 1.0 / 512.0;

sampler TexSampler : register(s0)
{
	MipFilter = Point;
    MinFilter = Point;
    MagFilter = Point;
};

float4 DebugShaderP0(float2 texCoord: TEXCOORD0) : COLOR
{

	float4 color = tex2D(TexSampler, texCoord) * 0.5;
	color.a = 1;
	return color;
}

float4 DebugShaderP1(float2 texCoord: TEXCOORD0) : COLOR
{

	float4 color = tex2D(TexSampler, texCoord + float2(pixel_w, pixel_h) * 1) * 0.5;
	color.a = 0.5;
	return color;
}

technique DebugTechnique
{
	pass P0
	{
		PixelShader = compile ps_2_0 DebugShaderP0();
	}
	pass P1
	{
		PixelShader = compile ps_2_0 DebugShaderP1();
	}
}