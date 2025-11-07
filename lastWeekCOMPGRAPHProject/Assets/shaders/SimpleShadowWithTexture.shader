Shader "Custom/SimpleShadowWithTexture"
{
    Properties
    {
        //what can be modified in the inspector
        _MainTex ("Texture", 2D) = "white"{}
        _ShadowTint("Shadow Tin Color", Color) = (0,0,0,1)//tint color for shadows
    }

    SubShader
    {
        //we are using URP
        Tags {"RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            //main pass for receiving shadows and texture rendering
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //using HLSL, delcaring vertex and fragment Shader
            //we are importing core shader essentials, lighting but also shadow casscading essentials
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            //this is to make sure that the shadows can be processed

            //declare texture and sampler
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _ShadowTint;

            //declare the _MainTex_ST for texture tiling and offset
            float4 _MainTex_ST;

            struct Attributes
            {
                //vertex mesh data
                float3 positionOS : POSITION; //object space positiion
                float2 uv : TEXCOORD0; //uv coordinates for lighting
            };

            struct Varyings
            {
                //passes data to fragment
                float4 positionCS : SV_POSITION;
                float4 shadowCoords : TEXCOORD3;
                float2 uv : TEXCOORD0; //UV coordinates passed to fragment
            };

            Varyings vert(Attributes IN)
            {
                //we convert the vertices to clipspace and pass on remaining data to fragment
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                //get the VertexPositionInputs for the vertex position
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
                //Calculate shadow coordinates manually using a basic approach
                OUT.shadowCoords = TransformWorldToShadowCoord(positions.positionWS);
                //pass the UV cooridnates to the fragment Shader
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            //final pixel output
            half4 frag(Varyings IN): SV_Target
            {
                // Sample the main texture
                half4 textureColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // Calculate shadow amount from shadow map
                half shadowAmount = MainLightRealtimeShadow(IN.shadowCoords);

                // Tint only the shadow
                half4 tintedShadow = lerp(float4(1, 1, 1, 1), _ShadowTint, shadowAmount);

                // Combine the texture color with tinted shadow
                return textureColor * tintedShadow;

            }
            
            ENDHLSL
        }

        //shadow caster pass
        Pass
        {
            //we explain the name of this pass and it uses 
            //this time the ShadowCaster code for the rendering
            Name "ShadowCaster"
            Tags {"LightMode"="ShadowCaster"}

            HLSLPROGRAM
            //we use HLSL along with vertex, fragment and multi_compile_shadowcaster
            //functions
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            #pragma multi_compile_shadowcaster
            //importing essential shader code
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
            struct Attributes
            {
                //we only care about the vertex position 
                float4 vertex : POSITION; //object space
            };

            struct Varyings
            {
                //passes on this data from vertex to fragment
                float4 positionCS : SV_POSITION;
            };

            //vertex shader for shadow caster Pass
            Varyings vertShadowCaster(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.vertex.xyz);
                //transforms vertex positions into clipspace
                return OUT;
            }

            //fragment for shadow caster Pass
            float4 fragShadowCaster(Varyings i): SV_Target
            {
                return float4(0,0,0,1); //standard output for shadow casting
            }
        ENDHLSL
        }
    }
}
