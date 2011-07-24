float time;
float pixel_w = 1.0 / 512.0;
float pixel_h = 1.0 / 512.0;

sampler WaterSampler : register(s0);
sampler WaterSourceSampler : register(s1);
sampler GroundSampler : register(s2);
sampler FluxSampler : register(s3);

//=================================================================================
float4 WaterAdd(float2 texCoord: TEXCOORD0) : COLOR
{
	float4 ret = (float4)0;

	float water = tex2D(WaterSampler, texCoord).r;
	float water_add = tex2D(WaterSourceSampler, texCoord).r;

	ret.r = min(saturate(water + water_add * time * 0.1), 1);
	return ret;
}

//=================================================================================
float4 Flux(float2 texCoord: TEXCOORD0) : COLOR
{
	float4 ret = (float4)0;

	float water = tex2D(WaterSampler, texCoord).r;  
	float ground = tex2D(GroundSampler, texCoord).r;
	float height = (water + ground);
	float4 prev_flux = tex2D(FluxSampler, texCoord);
	
	// water around
	float w_up = tex2D(WaterSampler, float4(texCoord.x, texCoord.y + pixel_h, 0, 0)).r;  
	float w_down = tex2D(WaterSampler, float4(texCoord.x, texCoord.y - pixel_h, 0, 0)).r;
	float w_right = tex2D(WaterSampler, float4(texCoord.x + pixel_w, texCoord.y, 0, 0)).r;
	float w_left = tex2D(WaterSampler, float4(texCoord.x - pixel_w, texCoord.y, 0, 0)).r;

	// ground around
	float g_up = tex2D(GroundSampler, float4(texCoord.x, texCoord.y + pixel_h, 0, 0)).r;  
	float g_down = tex2D(GroundSampler, float4(texCoord.x, texCoord.y - pixel_h, 0, 0)).r;
	float g_right = tex2D(GroundSampler, float4(texCoord.x + pixel_w, texCoord.y, 0, 0)).r;
	float g_left = tex2D(GroundSampler, float4(texCoord.x - pixel_w, texCoord.y, 0, 0)).r;

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

    return flux;
}

//=================================================================================
float4 Water(float2 texCoord: TEXCOORD0) : COLOR
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

	float4 ret = (float4)0;
	float flux_in = f_up.a + f_right.r + f_down.g + f_left.b;
	float flux_out = flux.r + flux.g + flux.b + flux.a;

	float net_volume = time * (flux_in - flux_out);
	ret = (water + net_volume);
	ret.a = 0;
	return ret;
}

float4 Evaporation(float2 texCoord : TEXCOORD0) : COLOR
{
	float4 ret = (float4)0;
	float K_e = 0.01;

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