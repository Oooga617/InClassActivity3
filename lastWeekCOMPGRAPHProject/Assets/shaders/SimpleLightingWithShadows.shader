Shader "Custom/SimpleLightingWithShadows"
{
    Properties
    {
        //what can be modified in the inspector
        _MainTex ("Texture", 2D) = "white"{}
    }

    SubShader
    {
        //we are using URP
        Tags {"RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            //using HLSL, delcaring vertex and fragment Shader
            //we are importing core shader essentials, lighting but also shadow essentials
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            
            struct appdata
            {
                //we are more focused on gathering vertex position data
                float4 vertex : POSITION; //object space vertex POSITION
                float3 normal : NORMAL; //object space normals
                float2 uv : TEXCOORD0;

            };

            struct v2f
            {
                //interpolates what is in the appdata
                float4 pos : SV_POSITION; //clip space position
                float2 uv : TEXCOORD0; //UV COORDINATES
                half3 worldNormal : TEXCOORD1; //world space normals for lighting
                float3 worldPos : TEXCOORD2; //world space position for shadow casting
                float4 shadowCoord : TEXCOORD3; //shadow coordinates
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            //vertex shader
            v2f vert(appdata v)
            {
                v2f o;
                //transform vertex to clip space
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                //passing UV cooridnates to fragment Shader
                o.uv = v.uv;
                //transform object space normal to world space
                o.worldNormal = normalize(TransformObjectToWorldNormal(v.normal));
                //store world position (before the transformation to clipspace)
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldPos = worldPos;
                //compute shadow coordinates using world position
                o.shadowCoord = TransformWorldToShadowCoord(worldPos);
                return o;
            
            }

            //fragment shader
            half4 frag(v2f i) : SV_Target
            {
                //sample main Texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                //Get the main light direction and color
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                //lambertian lighting stuff
                half NdotL = max(0.0,dot(i.worldNormal,lightDirWS));
                half3 diffuseLight = NdotL*mainLight.color;

                //sample shadow attenuation for main Light
                half shadowAttenuation = MainLightRealtimeShadow(i.shadowCoord);
                //combine texture, diffuse lighting, and shadow attenuation
                col.rgb*=diffuseLight*shadowAttenuation;
                return col;

            }
            ENDHLSL
        }
    }
}
