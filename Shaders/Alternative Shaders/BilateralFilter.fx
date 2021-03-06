 ////--------------------//
 ///**Bilateral_Filter**///
 //-------------------////
 
 //---------------------------------------------------------------------------//
 // 	Bilateral Filter Made by mrharicot ported over to Reshade by BSD      //
 //		GitHub Link for sorce info github.com/SableRaf/Filters4Processing	  //
 // 	Shadertoy Link https://www.shadertoy.com/view/4dfGDH  Thank You.	  //
 //___________________________________________________________________________//

 
uniform int SIGMA <
	ui_type = "drag";
	ui_min = 1; ui_max = 50;
	ui_label = "SIGMA";
	ui_tooltip = "Place Holder.";
> = 5;

uniform int BilateralFilter <
	ui_type = "combo";
	ui_items = "Off\0Bilateral Filter On\0";
	ui_label = "Median Selection";
> = 0;

/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};

texture texBF { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F;};

sampler SamplerBF
	{
		Texture = texBF;
		AddressU = BORDER;
		AddressV = BORDER;
		AddressW = BORDER;
		MipFilter = Linear; 
		MinFilter = Linear; 
		MagFilter = Linear;
	};
	
#define BSIGMA 0.1
#define MSIZE 15

float normpdf(in float x, in float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

float normpdf3(in float3 v, in float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}
	
void Bilateral_Filter(float4 position : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
	float3 c = tex2Doffset(BackBuffer,texcoord,float2(0.0, 1.0)-(texcoord.xy )).rgb;
	
	const int kSize = (MSIZE-1)/2;	
	
	float weight[MSIZE] = 
	{  
	0.031225216, 
	0.033322271, 
	0.035206333, 
	0.036826804, 
	0.038138565, 
	0.039104044, 
	0.039695028, 
	0.039894000, 
	0.039695028, 
	0.039104044, 
	0.038138565, 
	0.036826804, 
	0.035206333, 
	0.033322271, 
	0.031225216
	};  
		float3 final_colour;
		float Z;
		[unroll]
		for (int j = 0; j <= kSize; ++j)
		{
			weight[kSize+j] = normpdf(float(j), SIGMA);
			weight[kSize-j] = normpdf(float(j), SIGMA);
		}
		
		float3 cc;
		float factor;
		float bZ = 1.0/normpdf(0.0, BSIGMA);

		for (int i=-kSize; i <= kSize; ++i)
		{
			for (int j=-kSize; j <= kSize; ++j)
			{
				cc = tex2Doffset(BackBuffer, texcoord , float2(0.0, 1.0)-(texcoord.xy+float2(float(i),float(j))) ).rgb;
				factor = normpdf3(cc-c, BSIGMA)*bZ*weight[kSize+j]*weight[kSize+i];
				Z += factor;
				final_colour += factor*cc;

			}
		}
		color = float4(final_colour/Z, 1.0);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void PS0(float4 position : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{

	if(BilateralFilter == 1)
	{
	color = tex2D(SamplerBF,float2(texcoord.x,texcoord.y));	
	}
	else
	{
	color = tex2D(BackBuffer,float2(texcoord.x,texcoord.y));
	}
}


///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

///////////////////////////////////////////////Depth Map View//////////////////////////////////////////////////////////////////////

//*Rendering passes*//

technique Bilateral_Filter
{
			pass BilateralFilterPass
		{
			VertexShader = PostProcessVS;
			PixelShader = Bilateral_Filter;
			RenderTarget = texBF;
		}
			pass OutputPass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS0;	
		}
}
