Shader "CandyShader/RimLight"
{
    Properties
    {
        _RimColor("RimColor", Color) = (0.5073529,0.3794856,0.2424849,0)
        _RimPower("RimPower", Range(0, 10)) = 0
        _Albedocolor("Albedo color", Color) = (1,1,1,0)
        _Albedo("Albedo", 2D) = "white" {}
        _Metallic("Metallic", 2D) = "white" {}
        _Metallicintensity("Metallic intensity", Range(0, 1)) = 0.5
        _Smoothness("Smoothness", 2D) = "white" {}
        _Smoothnessintensity("Smoothness intensity", Range(0, 1)) = 0.5
        _Normals("Normals", 2D) = "bump" {}
        _Normalintensity("Normal intensity", Float) = 1
        _Occlusion("Occlusion", 2D) = "white" {}
        _Occlusionintensity("Occlusion intensity", Range(0, 1)) = 0
        [HDR]_Emission_Albedo("Emission_Albedo", 2D) = "white" {}
        [HDR]_Emissionintensity("Emission intensity", Float) = 0
        [HDR]_Emission("Emission", Color) = (0,0,0,0)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "RenderPipeline"="UniversalPipeline"
            "IgnoreProjector"="True"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_Albedo);
        SAMPLER(sampler_Albedo);
        TEXTURE2D(_Metallic);
        SAMPLER(sampler_Metallic);
        TEXTURE2D(_Smoothness);
        SAMPLER(sampler_Smoothness);
        TEXTURE2D(_Normals);
        SAMPLER(sampler_Normals);
        TEXTURE2D(_Occlusion);
        SAMPLER(sampler_Occlusion);
        TEXTURE2D(_Emission_Albedo);
        SAMPLER(sampler_Emission_Albedo);

        CBUFFER_START(UnityPerMaterial)
            float4 _Albedo_ST;
            float4 _Metallic_ST;
            float4 _Smoothness_ST;
            float4 _Normals_ST;
            float4 _Occlusion_ST;
            float4 _Emission_Albedo_ST;
            half4 _RimColor;
            half4 _Albedocolor;
            half4 _Emission;
            half _RimPower;
            half _Metallicintensity;
            half _Smoothnessintensity;
            half _Normalintensity;
            half _Occlusionintensity;
            half _Emissionintensity;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode"="UniversalForward"
            }

            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                half fogFactor : TEXCOORD4;
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 5);
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = posInputs.positionCS;
                output.positionWS = posInputs.positionWS;
                output.uv = input.uv;
                output.normalWS = normalInputs.normalWS;
                real sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(normalInputs.tangentWS, sign);
                output.fogFactor = ComputeFogFactor(posInputs.positionCS.z);
                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                OUTPUT_SH(output.normalWS, output.vertexSH);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 uvAlbedo = TRANSFORM_TEX(input.uv, _Albedo);
                float2 uvNormal = TRANSFORM_TEX(input.uv, _Normals);
                float2 uvSmooth = TRANSFORM_TEX(input.uv, _Smoothness);
                float2 uvMetal = TRANSFORM_TEX(input.uv, _Metallic);
                float2 uvOcc = TRANSFORM_TEX(input.uv, _Occlusion);
                float2 uvEmit = TRANSFORM_TEX(input.uv, _Emission_Albedo);

                half4 smoothnessSample = SAMPLE_TEXTURE2D(_Smoothness, sampler_Smoothness, uvSmooth);
                half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normals, sampler_Normals, uvNormal), _Normalintensity);

                float sgn = input.tangentWS.w;
                float3 bitangentWS = sgn * cross(input.normalWS, input.tangentWS.xyz);
                float3x3 tangentToWorld = float3x3(input.tangentWS.xyz, bitangentWS, input.normalWS);
                float3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(normalTS, tangentToWorld));
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                float3 viewDirTS = TransformWorldToTangent(viewDirWS, tangentToWorld);

                half fresnel = pow(1.0h - saturate(dot(normalTS, normalize(viewDirTS))), _RimPower);
                half3 rim = fresnel * _RimColor.rgb * smoothnessSample.rgb;
                half3 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, uvAlbedo).rgb * _Albedocolor.rgb + rim;
                half metallic = _Metallicintensity * SAMPLE_TEXTURE2D(_Metallic, sampler_Metallic, uvMetal).r;
                half smoothness = smoothnessSample.r * _Smoothnessintensity;
                half occlusion = lerp(1.0h, SAMPLE_TEXTURE2D(_Occlusion, sampler_Occlusion, uvOcc).r, _Occlusionintensity);
                half3 emission = SAMPLE_TEXTURE2D(_Emission_Albedo, sampler_Emission_Albedo, uvEmit).rgb * _Emissionintensity * _Emission.rgb;

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = albedo;
                surfaceData.metallic = metallic;
                surfaceData.specular = half3(0.0h, 0.0h, 0.0h);
                surfaceData.smoothness = smoothness;
                surfaceData.normalTS = normalTS;
                surfaceData.emission = emission;
                surfaceData.occlusion = occlusion;
                surfaceData.alpha = 1.0h;
                surfaceData.clearCoatMask = 0.0h;
                surfaceData.clearCoatSmoothness = 0.0h;

                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.positionCS = input.positionCS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = viewDirWS;
                #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                #else
                inputData.shadowCoord = float4(0.0, 0.0, 0.0, 0.0);
                #endif
                inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
                inputData.vertexLighting = half3(0.0h, 0.0h, 0.0h);
                inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                inputData.tangentToWorld = tangentToWorld;

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings ShadowVert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
                #if UNITY_REVERSED_Z
                output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                return output;
            }

            half4 ShadowFrag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode"="DepthOnly"
            }

            ZWrite On
            ColorMask R
            Cull Back

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex DepthVert
            #pragma fragment DepthFrag

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings DepthVert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half DepthFrag(Varyings input) : SV_Target
            {
                return input.positionCS.z;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode"="Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex MetaVert
            #pragma fragment MetaFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings MetaVert(Attributes input)
            {
                Varyings output;
                output.positionCS = UnityMetaVertexPosition(input.positionOS.xyz, input.uv1, input.uv2);
                output.uv = TRANSFORM_TEX(input.uv0, _Albedo);
                return output;
            }

            half4 MetaFrag(Varyings input) : SV_Target
            {
                half3 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, TRANSFORM_TEX(input.uv, _Albedo)).rgb * _Albedocolor.rgb;
                half3 emission = SAMPLE_TEXTURE2D(_Emission_Albedo, sampler_Emission_Albedo, TRANSFORM_TEX(input.uv, _Emission_Albedo)).rgb * _Emissionintensity * _Emission.rgb;
                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = albedo;
                metaInput.Emission = emission;
                return UnityMetaFragment(metaInput);
            }
            ENDHLSL
        }
    }
}
