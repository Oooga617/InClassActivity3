Shader "Custom/WaterScrolling"
{
    Properties
    {
        _MainTex("Water",2D) = "white"{}
        _FoamTex("Foam",2D) = "white"{}
        _ScrollX ("Scroll X", Range(-5,5)) = 1
        _ScrollY ("Scroll Y", Range(-5,5)) = 1

        //stuff from the Water Alvaro script
        _Freq ("Wave Frequency", Range(0, 5)) = 3.0
        _Speed ("Wave Speed", Range(0, 10)) = 1.0
        _Amp ("Wave Amplitude", Range(0, 1)) = 0.1
        _BaseColor ("Base Color", Color) = (0, 1, 1, 1)  // Default is light blue
        _Transparency ("Transparency", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Transparency" "RenderPipeline" = "UniversalPipeline" }

        Blend DstColor SrcAlpha

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            //declare textures and samplers and Scrolling values
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_FoamTex);
            SAMPLER(sampler_FoamTex);

            float _ScrollX;
            float _ScrollY;

            float _Freq;
            float _Speed;
            float _Amp;

            float4 _BaseColor;

            float _Transparency;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                

                //manipulatiing the vertices
                //time based animation for water waves
                float wave = sin(_Time.y*_Speed + IN.positionOS.x *_Freq)*_Amp;

                //adjust vertex y positions for wave effect
                float3 displacedPos = IN.positionOS.xyz;
                displacedPos.y += wave;

                //transform displaced position to clipspace
                OUT.positionHCS = TransformObjectToHClip(displacedPos);
                
                //pass uv to fragment
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //scroll UVs overtime 
                float2 scrolledUV = IN.uv + float2(_ScrollX, _ScrollY)*_Time.y;
                
                //scroll uvs for foam texture at a different rate
                float2 scrolledFoamUV = IN.uv + float2(_ScrollX, _ScrollY)*(_Time.y*0.5);

                //sample both textures using the scroll UV cooridnates
                 half4 water = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, scrolledUV);
                half4 foam = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, scrolledFoamUV);

               half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                // Blend both textures
                half4 finalColor = (water + foam) * 0.5;

                texColor.a *= _Transparency;


                return finalColor * _BaseColor;
            }
            ENDHLSL
        }
    }
}
