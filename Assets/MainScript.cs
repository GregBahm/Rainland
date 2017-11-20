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

    public int Lifespan;
    public float Dampener;

    private ComputeBuffer _fixedDataBuffer;
    private const int FixedDataStride = sizeof(float) * 2; // Start Location 

    private ComputeBuffer _variableDataBuffer;
    private const int VariableDataStride = sizeof(float) * 2 // Current Location
                                                + sizeof(float) // Velocity
                                                + sizeof(int); // Life Remaining

    private int _computeKernel;
    private int _groupsCount;

    public struct FixedSliceData
    {
        public Vector2 StartLocation;
    }

    public struct VariableSliceData
    {
        public Vector2 CurrentLocation;
        public float Velocity; 
        public int LifeRemaining;
    }

    private void Start()
    {
        _computeKernel = Computer.FindKernel("ComputeSlice");
        _fixedDataBuffer = GetFixedDataBuffer();
        _variableDataBuffer = GetVariableDataBuffer();
        _groupsCount = Mathf.CeilToInt((float)PointsCount / 128);
    }

    private ComputeBuffer GetVariableDataBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(PointsCount, VariableDataStride);
        VariableSliceData[] data = new VariableSliceData[PointsCount];
        for (int i = 0; i < PointsCount; i++)
        {
            int lifetimeOffset = (int)(Lifespan * UnityEngine.Random.value);
            VariableSliceData newDatum = new VariableSliceData() { LifeRemaining = lifetimeOffset };
            data[i] = newDatum;
        }
        ret.SetData(data);
        return ret;
    }

    private ComputeBuffer GetFixedDataBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(PointsCount, FixedDataStride);
        FixedSliceData[] data = new FixedSliceData[PointsCount];
        for (int i = 0; i < PointsCount; i++)
        {
            Vector2 startLocation = new Vector2(UnityEngine.Random.value, UnityEngine.Random.value);
            FixedSliceData newDatum = new FixedSliceData() { StartLocation = startLocation };
            data[i] = newDatum;
        }
        ret.SetData(data);
        return ret;
    }

    private void Update()
    {
        Computer.SetInt("_Lifespan", Lifespan);
        Computer.SetFloat("_Dampener", Dampener);
        Computer.SetTexture(_computeKernel, "_SourceTexture", NoiseSource);
        Computer.SetBuffer(_computeKernel, "_FixedDataBuffer", _fixedDataBuffer);
        Computer.SetBuffer(_computeKernel, "_VariableDataBuffer", _variableDataBuffer);
        Computer.Dispatch(_computeKernel, _groupsCount, 1, 1);

        Mat.SetBuffer("_FixedDataBuffer", _fixedDataBuffer);
        Mat.SetBuffer("_VariableDataBuffer", _variableDataBuffer);
    }

    private void OnRenderObject()
    {
        Mat.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Points, 1, PointsCount);
    }

    private void OnDestroy()
    {
        _variableDataBuffer.Release();
        _fixedDataBuffer.Release();
    }
}
