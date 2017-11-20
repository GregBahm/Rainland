Shader "Unlit/SliceShader"
{
	Properties
	{
        _Span("Span", Range(0, 0.1)) = 1
        _Powa("Powa", float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
            #define ChainLength 128
            
            struct SegmentData
            {
                float2 Position;
                float2 Tangent;
                float Velocity;
            };
            StructuredBuffer<SegmentData> _VariableDataBuffer;

            float4x4 _MasterMatrix;

			struct v2g
			{
                float3 pos : TEXCOORD0;
                float stripPos : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float2 sourceTanget : TEXCOORD3;
            };

			struct g2f
			{
				float4 vertex : SV_POSITION;
                float2 uvs : TEXCOORD0;
                float3 normal : TEXCOORD1;
			};
            
            float _Span;
            float _Powa;

            v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
            {
                SegmentData datum = _VariableDataBuffer[instanceId * ChainLength + meshId];

                float3 pos = float3(datum.Position.x, datum.Velocity, datum.Position.y);
                float stripPos = (float)meshId / ChainLength;
                pos.y *= 1 - pow(abs(stripPos - .5) * 2, 3);
                
                float2 unitSquarePos = abs(pos.xz) % 1;
                float2 distToCenter = pow(abs(unitSquarePos - .5) * 2, 5);
                float maxDist = max(distToCenter.x, distToCenter.y);
                pos.y *= 1 - maxDist;

                float3 tangent = float3(datum.Tangent.x, 0, datum.Tangent.y) * _Span * pos.y;

				v2g o;
                o.pos = pos;
                o.stripPos = stripPos; 
                o.tangent = tangent;
                o.sourceTanget = datum.Tangent;
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
				float3 tangentStart = p[0].tangent;
				float3 tangentEnd = p[1].tangent;
                float3 startNormal = float3(p[0].sourceTanget.x, p[0].pos.y, p[0].sourceTanget.y);
                float3 endNormal = float3(p[1].sourceTanget.x, p[1].pos.y, p[1].sourceTanget.y);
                
                float2 midPoint = (segmentStart.xz + segmentStart.xz) / 2;
                float2 inUnitSquare = (midPoint + 10) % 1;
                float2 unitSquareOffset = inUnitSquare - midPoint;
                segmentStart.xz += unitSquareOffset;
                segmentEnd.xz += unitSquareOffset;

                float3 droppedStart = float3(segmentStart.x, 0, segmentStart.z);
                float3 droppedEnd = float3(segmentEnd.x, 0, segmentEnd.z);
                
                float3 droppedStartA = droppedStart + tangentStart;
                float3 droppedEndA = droppedEnd + tangentEnd;
                float3 droppedStartB = droppedStart - tangentStart;
                float3 droppedEndB = droppedEnd - tangentEnd;

				g2f o;

                o.uvs = float2(0, p[0].stripPos);
				o.vertex = GetTransformedPoint(droppedStartA);
                o.normal = startNormal;
				triStream.Append(o);
                
                o.uvs = float2(0, p[1].stripPos);
				o.vertex = GetTransformedPoint(droppedEndA);
                o.normal = endNormal;
				triStream.Append(o);

                o.uvs = float2(segmentStart.y, p[0].stripPos);
				o.vertex = GetTransformedPoint(segmentStart);
                o.normal = startNormal;
				triStream.Append(o);
                
                o.uvs = float2(segmentEnd.y, p[1].stripPos);
				o.vertex = GetTransformedPoint(segmentEnd);
                o.normal = endNormal;
				triStream.Append(o);

                triStream.RestartStrip();

                o.uvs = float2(segmentStart.y, p[0].stripPos);
				o.vertex = GetTransformedPoint(segmentStart);
                o.normal = startNormal * float3(-1, 1, -1);
				triStream.Append(o);
                
                o.uvs = float2(segmentEnd.y, p[1].stripPos);
				o.vertex = GetTransformedPoint(segmentEnd);
                o.normal = endNormal * float3(-1, 1, -1);
				triStream.Append(o);
                
                o.uvs = float2(0, p[0].stripPos);
				o.vertex = GetTransformedPoint(droppedStartB);
                o.normal = startNormal * float3(-1, 1, -1);
				triStream.Append(o);
                
                o.uvs = float2(0, p[1].stripPos);
				o.vertex = GetTransformedPoint(droppedEndB);
                o.normal = endNormal * float3(-1, 1, -1);
				triStream.Append(o);
                
            }

			fixed4 frag (g2f i) : SV_Target
			{
                float heightVal = pow(i.uvs.x, _Powa);
                float shade = dot(normalize(i.normal), float3(.3, .7, 0)) / 2 + 1;
                return shade * heightVal;
			}
			ENDCG
		}
	}
}
