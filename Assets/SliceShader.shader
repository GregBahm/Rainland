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

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			
            struct FixedSliceData 
            {
                float2 StartLocation;
            };

            struct VariableSliceData
            {
                float2 CurrentLocation;
                float Velocity; 
                int LifeRemaining;
            };

            StructuredBuffer<FixedSliceData> _FixedDataBuffer;
            StructuredBuffer<VariableSliceData> _VariableDataBuffer;

			struct v2g
			{
                float4 pos : SV_POSITION;
            };

			struct g2f
			{
				float4 vertex : SV_POSITION;
			};
            
            v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
            {
                VariableSliceData variableData = _VariableDataBuffer[instanceId];

				v2g o;
                o.pos = float4(variableData.CurrentLocation.x,0,variableData.CurrentLocation.y, 1);
				return o;
			}

            float _Size;
            
			[maxvertexcount(4)]
			void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
			{
				float4 vertBase = p[0].pos;
				float4 vertBaseClip = UnityObjectToClipPos(vertBase);

				float4 leftScreenOffset = float4(_Size, 0, 0, 0);
				float4 rightScreenOffset = float4(-_Size, 0, 0, 0);
				float4 topScreenOffset = float4(0, -_Size, 0, 0);
				float4 bottomScreenOffset = float4(0, _Size, 0, 0); 

				float4 topVertA = leftScreenOffset + topScreenOffset + vertBaseClip;
				float4 topVertB = rightScreenOffset + topScreenOffset + vertBaseClip;
				float4 bottomVertA = leftScreenOffset + bottomScreenOffset + vertBaseClip;
				float4 bottomVertB = rightScreenOffset + bottomScreenOffset + vertBaseClip;

				g2f o;
				o.vertex = topVertB;
				triStream.Append(o);
				o.vertex = topVertA;
				triStream.Append(o);
				o.vertex = bottomVertB;
				triStream.Append(o);
				o.vertex = bottomVertA;
				triStream.Append(o);
            }
			
			fixed4 frag (g2f i) : SV_Target
			{
                return 1;
			}
			ENDCG
		}
	}
}
