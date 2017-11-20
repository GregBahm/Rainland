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

			struct v2g
			{
                float3 pos : TEXCOORD0;
            };

			struct g2f
			{
				float4 vertex : SV_POSITION;
                float val : TEXCOORD0;
			};
            
            v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
            {
				v2g o;
                o.pos = _VariableDataBuffer[instanceId * ChainLength + meshId];
				return o;
			}

            float _Size;
            
			[maxvertexcount(4)]
			void geo(line v2g p[2], inout TriangleStream<g2f> triStream)
			{
				float3 segmentStart = p[0].pos;
				float3 segmentEnd = p[1].pos;
                
                float3 droppedStart = float3(segmentStart.x, 0, segmentStart.z);
                float3 droppedEnd = float3(segmentEnd.x, 0, segmentEnd.z);

				g2f o;
                o.val = segmentStart.y;
				o.vertex = UnityObjectToClipPos(segmentStart);
				triStream.Append(o);
                o.val = segmentEnd.y;
				o.vertex = UnityObjectToClipPos(segmentEnd);
				triStream.Append(o);
                o.val = 0;
				o.vertex = UnityObjectToClipPos(droppedStart);
				triStream.Append(o);
				o.vertex = UnityObjectToClipPos(droppedEnd);
				triStream.Append(o);
            }
			
			fixed4 frag (g2f i) : SV_Target
			{
                return i.val;
			}
			ENDCG
		}
	}
}
