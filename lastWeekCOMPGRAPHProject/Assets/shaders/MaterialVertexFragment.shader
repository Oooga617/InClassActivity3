Shader "Custom/MaterialVertexFragment"
{
    Properties
    {
        //factors of the shader that can be edited in the inspector
        _MainTex ("Texture", 2D) = "white" {} //base texture
        _ScaleUVX ("Scale X", Range(0.1,10)) = 1 //scaling the uv on the x
        _ScaleUVY ("Scale Y", Range(0.1,10)) = 1 //scale amount of the uv on the y
        _Speed ("speed", Range(0.001, 5)) = 1 //the speed of the animation
    }
    SubShader
    {
        //tags to set the render pipeline being used is URP
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //using HLSL along with declaring vertex and fragment functions

            //importing core shader libraries
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                //we are specifically and purely looking at the vertex data and uv coordinates
                float4 vertex : POSITION;   // Vertex position in object space
                float2 uv : TEXCOORD0;      // UV coordinates
            };

            struct v2f
            {
                //we are only passing on UV cooridnates and position for vertices in clip space
                float2 uv : TEXCOORD0;      // UV coordinates passed to fragment shader
                float4 pos : SV_POSITION;   // Clip space position
            };

            TEXTURE2D(_MainTex);            // Main texture
            SAMPLER(sampler_MainTex);       // Sampler for the texture
            float _ScaleUVX;
            float _ScaleUVY;
            float _Speed;

            // Vertex Shader
            v2f vert(appdata v)
            {
                v2f o;
                // Transform object space vertex to clip space
                o.pos = TransformObjectToHClip(v.vertex.xyz);

                // Scale UVs and apply sine transformation
                o.uv = v.uv;
                o.uv.x = sin(o.uv.x * _ScaleUVX);  // Scale and apply sine on X
                o.uv.y = sin(o.uv.y * _ScaleUVY);  // Scale and apply sine on Y

                return o;
            }

            // Fragment Shader
            half4 frag(v2f i) : SV_Target
            {
                // Sample the main texture with transformed UV coordinates
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return col;
            }

            ENDHLSL
        }
    }
}
