Shader "Unlit/SliceShader"
{
	Properties
	{
        _Size("Size", Float) = 1
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
            #define ChainLength 32

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
				v2g o;
                o.pos = _VariableDataBuffer[instanceId * ChainLength + meshId];
                o.stripPos = (float)meshId / ChainLength;
				return o;
			}

            float4 GetTransformedPoint(float3 pos)
            {
                pos.xz -= .5;
                float4 transformedPos = mul(_MasterMatrix, pos);
                return UnityObjectToClipPos(transformedPos);
            }
            
			[maxvertexcount(4)]
			void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
			{
				float3 segmentStart = p[0].pos;
				float3 segmentEnd = p[1].pos;
                
                float2 midPoint = (segmentStart.xz + segmentStart.xz) / 2;
                float2 inUnitSquare = (midPoint + 1) % 1;
                float2 unitSquareOffset = inUnitSquare - midPoint;
                //segmentStart.xz += unitSquareOffset;
                //segmentEnd.xz += unitSquareOffset;

                float3 droppedStart = float3(segmentStart.x, 0, segmentStart.z);
                float3 droppedEnd = float3(segmentEnd.x, 0, segmentEnd.z);

				g2f o;
                
                o.uvs = float2(0, p[1].stripPos);
				o.vertex = GetTransformedPoint(droppedEnd);
				triStream.Append(o);

                o.uvs = float2(0, p[0].stripPos);
				o.vertex = GetTransformedPoint(droppedStart);
				triStream.Append(o);

                o.uvs = float2(1, p[1].stripPos);
				o.vertex = GetTransformedPoint(segmentEnd);
				triStream.Append(o);
                
                o.uvs = float2(1, p[0].stripPos);
				o.vertex = GetTransformedPoint(segmentStart);
				triStream.Append(o);
            }
			
			fixed4 frag (g2f i) : SV_Target
			{
                return i.uvs.x;
                return float4(i.uvs, 0, 1);
			}
			ENDCG
		}
	}
}
