Shader "Unlit/SliceShader"
{
	Properties
	{
        _Threshold("Threshold", Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

        Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
            #define ChainLength 128

            StructuredBuffer<float3> _VariableDataBuffer;

            float4x4 _MasterMatrix;

			struct v2g
			{
                float3 pos : TEXCOORD0;
                float stripPos : TEXCOORD1;
            };

			struct g2f
			{
				float4 vertex : SV_POSITION;
                float2 uvs : TEXCOORD0;
			};
            
            v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
            {
                float3 pos = _VariableDataBuffer[instanceId * ChainLength + meshId];
                float stripPos = (float)meshId / ChainLength;
                pos.y *= 1 - pow(abs(stripPos - .5) * 2, 3);
                
                float2 unitSquarePos = abs(pos.xz) % 1;
                float2 distToCenter = pow(abs(unitSquarePos - .5) * 2, 5);
                float maxDist = max(distToCenter.x, distToCenter.y);
                pos.y *= 1 - maxDist;

				v2g o;
                o.pos = pos;
                o.stripPos = stripPos; 
				return o;
			}

            float4 GetTransformedPoint(float3 pos)
            {
                pos.xz -= .5;
                float4 transformedPos = mul(_MasterMatrix, pos);
                return UnityObjectToClipPos(transformedPos);
            }
            
			[maxvertexcount(8)]
			void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
			{
				float3 segmentStart = p[0].pos;
				float3 segmentEnd = p[1].pos;
                
                float2 midPoint = (segmentStart.xz + segmentStart.xz) / 2;
                float2 inUnitSquare = (midPoint + 10) % 1;
                float2 unitSquareOffset = inUnitSquare - midPoint;
                segmentStart.xz += unitSquareOffset;
                segmentEnd.xz += unitSquareOffset;

                float3 droppedStart = float3(segmentStart.x, 0, segmentStart.z);
                float3 droppedEnd = float3(segmentEnd.x, 0, segmentEnd.z);


				g2f o;
                
                o.uvs = float2(segmentEnd.y, p[1].stripPos);
				o.vertex = GetTransformedPoint(droppedEnd);
				triStream.Append(o);

                o.uvs = float2(segmentStart.y, p[0].stripPos);
				o.vertex = GetTransformedPoint(droppedStart);
				triStream.Append(o);

                o.uvs = float2(0, p[1].stripPos);
				o.vertex = GetTransformedPoint(segmentEnd);
				triStream.Append(o);
                
                o.uvs = float2(0, p[0].stripPos);
				o.vertex = GetTransformedPoint(segmentStart);
				triStream.Append(o);
            }
			float _Threshold;
			fixed4 frag (g2f i) : SV_Target
			{
                float valA = 1 - pow(1 - i.uvs.x, 2);
                float3 valB = lerp(1, float3(0, .5, 1), i.uvs.y);
                float3 col = valB * valA;
                //return pow(val, 10);
                return float4(col, 1);
			}
			ENDCG
		}
	}
}
