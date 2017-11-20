using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MainScript : MonoBehaviour 
{
    public Texture2D NoiseSource;
    public ComputeShader Computer;
    public Material Mat;
    public int PointsCount;
    
    public float Dampener;
    [Range(0, 1)]
    public float HeightSmooth;
    public float TextureOffset;

    private const int ChainLength = 32;

    private ComputeBuffer _variableDataBuffer;
    private const int VariableDataStride = sizeof(float) * 3;

    private int _computeKernel;
    private int _groupsCount;

    private void Start()
    {
        _computeKernel = Computer.FindKernel("ComputeSlice");
        _variableDataBuffer = GetVariableDataBuffer();
        _groupsCount = Mathf.CeilToInt((float)PointsCount / 128);
    }

    private ComputeBuffer GetVariableDataBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(PointsCount * ChainLength, VariableDataStride);
        Vector3[] data = new Vector3[PointsCount * ChainLength];
        for (int i = 0; i < (PointsCount * ChainLength); i++)
        {
            float x = UnityEngine.Random.value;
            float z = UnityEngine.Random.value;
            Vector3 randomPoint = new Vector3(x, .1f, z);
            data[i] = randomPoint;
        }
        ret.SetData(data);
        return ret;
    }

    private void Update()
    {
        DispatchComputeShader();
        Mat.SetBuffer("_VariableDataBuffer", _variableDataBuffer);
        Mat.SetMatrix("_MasterMatrix", transform.localToWorldMatrix);
    }

    private void DispatchComputeShader()
    {
        Computer.SetFloat("_Dampener", Dampener);
        Computer.SetFloat("_HeightSmooth", HeightSmooth);
        Computer.SetFloat("_TextureOffset", TextureOffset);
        Computer.SetTexture(_computeKernel, "_SourceTexture", NoiseSource);
        Computer.SetBuffer(_computeKernel, "_VariableDataBuffer", _variableDataBuffer);
        Computer.Dispatch(_computeKernel, _groupsCount, 1, 1);
    }

    private void OnRenderObject()
    {
        Mat.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.LineStrip, ChainLength, PointsCount);
    }

    private void OnDestroy()
    {
        _variableDataBuffer.Release();
    }
}
