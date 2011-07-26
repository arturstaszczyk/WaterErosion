float time;
float pixel_w = 1.0 / 512.0;
float pixel_h = 1.0 / 512.0;

sampler WaterSampler : register(s0);
sampler WaterSourceSampler : register(s1);
sampler GroundSampler : register(s2);
sampler FluxSampler : register(s3);
sampler VelocitySampler : register(s4);
sampler SedimentSampler : register(s5);

float4 tex2Dlod_bilinear( sampler texSam, float2 uv )
{

float4 height00 = tex2D(texSam, float4(uv.x, uv.y, 0, 0));
float4 height10 = tex2D(texSam, float4(uv.x, uv.y, 0, 0) + float4(pixel_w, 0, 0, 0)); 
float4 height01 = tex2D(texSam, float4(uv.x, uv.y, 0, 0) + float4(0, pixel_h, 0, 0)); 
float4 height11 = tex2D(texSam, float4(uv.x, uv.y, 0, 0) + float4(pixel_w , pixel_h, 0, 0)); 

float2 f = frac( uv.xy * 512 );

float4 tA = lerp( height00, height10, f.x );
float4 tB = lerp( height01, height11, f.x );

return lerp( tA, tB, f.y );
}

//=================================================================================
float4 WaterAdd(float2 texCoord: TEXCOORD0) : COLOR
{
	float4 ret = (float4)0;

	float water = tex2D(WaterSampler, texCoord).r;
	float water_add = tex2D(WaterSourceSampler, texCoord).r;

	ret.r = min(saturate(water + water_add * time * 0.1), 1);
	return ret;
}

struct FluxOutput
{
	float4 Flux : COLOR0;
	float4 Debug : COLOR1;
};

//=================================================================================
FluxOutput Flux(float2 texCoord: TEXCOORD0) : COLOR
{
	
	FluxOutput ret = (FluxOutput)0;

	float4 half_pix = float4(pixel_w / 2.0f, pixel_h / 2.0f, 0, 0);
	float water = tex2D(WaterSampler, texCoord).r;  
	float ground = tex2Dlod_bilinear(GroundSampler, texCoord + half_pix).r;
	float height = (water + ground);
	float4 prev_flux = tex2D(FluxSampler, texCoord);
	
	// water around
	float w_up = tex2D(WaterSampler, float4(texCoord.x, texCoord.y + pixel_h, 0, 0)).r;  
	float w_down = tex2D(WaterSampler, float4(texCoord.x, texCoord.y - pixel_h, 0, 0)).r;
	float w_right = tex2D(WaterSampler, float4(texCoord.x + pixel_w, texCoord.y, 0, 0)).r;
	float w_left = tex2D(WaterSampler, float4(texCoord.x - pixel_w, texCoord.y, 0, 0)).r;

	// ground around
	float g_up = tex2D(GroundSampler, float4(texCoord.x, texCoord.y + pixel_h, 0, 0)+half_pix).r;  
	float g_down = tex2D(GroundSampler, float4(texCoord.x, texCoord.y - pixel_h, 0, 0)+half_pix).r;
	float g_right = tex2D(GroundSampler, float4(texCoord.x + pixel_w, texCoord.y, 0, 0)+half_pix).r;
	float g_left = tex2D(GroundSampler, float4(texCoord.x - pixel_w, texCoord.y, 0, 0)+half_pix).r;

	float4 height_around;
	height_around.x = (w_left + g_left);
	height_around.y = (w_up + g_up);
	height_around.z = (w_right + g_right);
	height_around.w = (w_down + g_down);

	float4 delta_height; // [-1..1]
	delta_height.x = (height - height_around.x);
	delta_height.y = (height - height_around.y);
	delta_height.z = (height - height_around.z);
	delta_height.w = (height - height_around.w);

	float4 flux;
	flux.x = max(0, prev_flux.x + time * delta_height.x * 20);
	flux.y = max(0, prev_flux.y + time * delta_height.y * 20);
	flux.z = max(0, prev_flux.z + time * delta_height.z * 20);
	flux.w = max(0, prev_flux.w + time * delta_height.w * 20);

	float K = min(1, (water) / ((flux.x + flux.y + flux.z + flux.w) * time));
	flux = K * flux;

	ret.Debug = abs(ground - g_up);
	ret.Debug.a = 1;

//	if(texCoord.x < pixel_w * 2)
//		flux.r = 0;
//	if(texCoord.x > (1 - pixel_w * 2))
//		flux.b = 0;
//	if(texCoord.y < pixel_h * 2)
//		flux.g = 0;
//	if(texCoord.y > (1 - pixel_h * 2))
//		flux.a = 0;

	ret.Flux = flux;
    return ret;
}

//=================================================================================
struct WaterOutput
{
	float4 Water : COLOR0;
	float4 Velocity : COLOR1;
};

//=================================================================================
WaterOutput Water(float2 texCoord: TEXCOORD0) : COLOR
{
	float height_scale = 1;
	float flux_scale = 1;
	float water = tex2D(WaterSampler, texCoord).r * height_scale;  
	float ground = tex2D(GroundSampler, texCoord).r * height_scale;
	float4 flux = tex2D(FluxSampler, texCoord) * flux_scale;

	//flux around 
	float4 f_up = tex2D(FluxSampler, float4(texCoord.x, texCoord.y + pixel_h, 0, 0)) * flux_scale;  
	float4 f_down = tex2D(FluxSampler, float4(texCoord.x, texCoord.y - pixel_h, 0, 0)) * flux_scale;
	float4 f_right = tex2D(FluxSampler, float4(texCoord.x + pixel_w, texCoord.y, 0, 0)) * flux_scale;
	float4 f_left = tex2D(FluxSampler, float4(texCoord.x - pixel_w, texCoord.y, 0, 0)) * flux_scale;

	WaterOutput ret = (WaterOutput)0;
	float flux_in = f_up.a + f_right.r + f_down.g + f_left.b;
	float flux_out = flux.r + flux.g + flux.b + flux.a;

	float net_volume = time * (flux_in - flux_out);
	ret.Water = (water + net_volume);
	ret.Water.a = 0;

	float water_mean = (water + ret.Water) / 2.0;
	float flux_mean_h = (f_left.b - flux.r + flux.b - f_right.r) / 2.0;
	float flux_mean_v = (f_up.a - flux.g + flux.a - f_down.g) / 2.0;

	ret.Velocity.x = (flux_mean_h / water_mean * saturate(water_mean - 0.001));
	ret.Velocity.y = (flux_mean_v / water_mean * saturate(water_mean - 0.001));

	if(texCoord.x < pixel_w * 2)
		ret.Water = 0;
	if(texCoord.x > (1 - pixel_w * 2))
		ret.Water = 0;
	if(texCoord.y < pixel_h * 2)
		ret.Water = 0;
	if(texCoord.y > (1 - pixel_h * 2))
		ret.Water = 0;

	return ret;
}

//=================================================================================
struct SedimentOutput
{
	float4 Sediment : COLOR0;
	float4 Ground : COLOR1;
	float4 Debug : COLOR2;
};

//=================================================================================
SedimentOutput Diffusion(float2 texCoord : TEXCOORD0) : COLOR
{
	float K_c = 0.08;
	float K_s = 0.002;

	
	float ground = tex2D(GroundSampler, texCoord).r;
	float4 velocity = tex2D(VelocitySampler, texCoord);

	float2 sediment_uv = texCoord;
	sediment_uv.x +=(pixel_w * (velocity.x * time));
	sediment_uv.y +=( pixel_h * (velocity.y * time));

	float sediment = tex2D(SedimentSampler, sediment_uv).r;

	float g_up = tex2D(GroundSampler, float4(texCoord.x, texCoord.y + pixel_h, 0, 0)).r;  
	float g_down = tex2D(GroundSampler, float4(texCoord.x, texCoord.y - pixel_h, 0, 0)).r;
	float g_right = tex2D(GroundSampler, float4(texCoord.x + pixel_w, texCoord.y, 0, 0)).r;
	float g_left = tex2D(GroundSampler, float4(texCoord.x - pixel_w, texCoord.y, 0, 0)).r;

	float mean_h = (g_right - ground + ground - g_left) / 2.0;
	float mean_v = (g_down - ground + ground - g_up) / 2.0;

	float alpha = (mean_v + mean_h) / 2;
	alpha = min(alpha, 0.2);
	alpha = max(alpha, 0.009);
	alpha = 1;
	float len = length(velocity);
	//len = min(len, 1);
	float C = abs(K_c * len * alpha);

	SedimentOutput ret = (SedimentOutput)0;
	
	if(C - sediment > 0.00001)
	{
		ret.Sediment.r = abs(sediment + K_s * (C - sediment));
		ret.Ground = ground - K_s * (C - sediment);
		//ret.Debug.r = K_s * (C - sediment) * 20000;
	}
	else if(sediment - C > 0.00001)
	{
		ret.Sediment.r = abs(sediment - K_s * (sediment - C));
		ret.Ground = ground + K_s * (sediment - C);
		ret.Debug.g = K_s * (sediment - C) * 20000;
	}
	else
	{
		ret.Sediment.r = C;
		ret.Ground = ground;
	}

	//ret.Ground = ground;
	//ret.Debug = abs(C - ret.Sediment) * 1000;
	ret.Debug.a = 1;
	ret.Sediment.a = 1;

	return ret;
}

//=================================================================================
float4 Evaporation(float2 texCoord : TEXCOORD0) : COLOR
{
	float4 ret = (float4)0;
	float K_e = 0.03;

	float4 water = tex2D(WaterSampler, texCoord);
	ret = water * (1 - K_e * time);

	return ret;
}

//=================================================================================
float4 Clear(float2 texCoord: TEXCOORD0) : COLOR
{
	return (float4)0;
}

//=================================================================================
technique WaterAddCalc
{
	pass P0
	{
		PixelShader = compile ps_2_0 Clear();
	}
    pass P1
    {
        PixelShader = compile ps_2_0 WaterAdd();
    }
}

//=================================================================================
technique FluxCalculation
{
	pass P0
	{
		PixelShader = compile ps_2_0 Clear();
	}
    pass P1
    {
        PixelShader = compile ps_2_0 Flux();
    }
}

//=================================================================================
technique WaterCalculation
{
	pass P0
	{
		PixelShader = compile ps_2_0 Clear();
	}
	pass P1
	{
		PixelShader = compile ps_2_0 Water();
	}
}

//=================================================================================
technique EvaporationCalculation
{
	pass P0
	{
		PixelShader = compile ps_2_0 Evaporation();
	}
}

//=================================================================================
technique DiffusionCalculation
{
	pass P0
	{
		PixelShader = compile ps_2_0 Diffusion();
	}
}