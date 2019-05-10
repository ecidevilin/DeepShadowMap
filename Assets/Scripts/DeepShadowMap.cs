using UnityEngine;
using UnityEngine.Rendering;

public class DeepShadowMap : MonoBehaviour
{
    private Camera camera;
    private CommandBuffer BeforeForwardOpaque;
    private CommandBuffer AfterForwardOpaque;

    private ComputeBuffer NumberBuffer;
    private ComputeBuffer DepthBuffer;
    private ComputeBuffer RegressionBuffer;

    public Light DirectionalLight;
    public Material ShadowMapMaterial;
    [Range(0, 1)]
    public float HairAlpha = 0.7f;

    public ComputeShader ResetCompute;
    private int KernelResetNumberBuffer;
    private int KernelResetDepthBuffer;
    private int KernelResetRegressionBuffer;

    public ComputeShader SortCompute;
    private int KernelSortDepth;

#if UNITY_EDITOR
    public ComputeShader TestCompute;
    private int KernelResetTestResult;
    private int KernelTestNumberBuffer;
    private int KernelTestDepthBuffer;
    private int KernelTestRegressionBuffer;
    public RenderTexture TestRenderTexture;
    [Range(0, 49)]
    public int TestIndex;
    public enum ETestKernel
    {
        KernelTestNumberBuffer,
        KernelTestDepthBuffer,
        KernelTestRegressionBuffer,
    }
    public ETestKernel TestKernel;
#endif
    
    public Color HairColor;

    const int dimension = 512;
    const int elements = 32;

    private void Start()
    {
        int numElement = dimension * dimension * elements;

        camera = GetComponent<Camera>();
        BeforeForwardOpaque = new CommandBuffer();
        AfterForwardOpaque = new CommandBuffer();
        camera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, BeforeForwardOpaque);
        camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, AfterForwardOpaque);

        NumberBuffer = new ComputeBuffer(dimension * dimension, sizeof(uint));
        DepthBuffer = new ComputeBuffer(numElement, sizeof(float));
        RegressionBuffer = new ComputeBuffer(dimension * dimension, sizeof(float) * 12);

        KernelResetNumberBuffer = ResetCompute.FindKernel("KernelResetNumberBuffer");
        KernelResetDepthBuffer = ResetCompute.FindKernel("KernelResetDepthBuffer");
        KernelResetRegressionBuffer = ResetCompute.FindKernel("KernelResetRegressionBuffer");

        ResetCompute.SetInt("Dimension", dimension);
        ResetCompute.SetBuffer(KernelResetNumberBuffer, "NumberBuffer", NumberBuffer);
        ResetCompute.SetBuffer(KernelResetDepthBuffer, "DepthBuffer", DepthBuffer);
        ResetCompute.SetBuffer(KernelResetRegressionBuffer, "RegressionBuffer", RegressionBuffer);

        ResetCompute.Dispatch(KernelResetNumberBuffer, dimension / 8, dimension / 8, 1);

        KernelSortDepth = SortCompute.FindKernel("KernelSortDepth");
        SortCompute.SetInt("Dimension", dimension);
        SortCompute.SetBuffer(KernelSortDepth, "NumberBuffer", NumberBuffer);
        SortCompute.SetBuffer(KernelSortDepth, "DepthBuffer", DepthBuffer);
        SortCompute.SetBuffer(KernelSortDepth, "RegressionBuffer", RegressionBuffer);

#if UNITY_EDITOR
        KernelResetTestResult = TestCompute.FindKernel("KernelResetTestResult");
        KernelTestNumberBuffer = TestCompute.FindKernel("KernelTestNumberBuffer");
        KernelTestDepthBuffer = TestCompute.FindKernel("KernelTestDepthBuffer");
        KernelTestRegressionBuffer = TestCompute.FindKernel("KernelTestRegressionBuffer");
        TestCompute.SetInt("Dimension", dimension);
        TestCompute.SetBuffer(KernelTestNumberBuffer, "NumberBuffer", NumberBuffer);
        TestCompute.SetBuffer(KernelTestDepthBuffer, "DepthBuffer", DepthBuffer);
        TestCompute.SetBuffer(KernelTestRegressionBuffer, "RegressionBuffer", RegressionBuffer);
        TestRenderTexture.enableRandomWrite = true;
        TestCompute.SetTexture(KernelResetTestResult, "TestRenderTexture", TestRenderTexture);
        TestCompute.SetTexture(KernelTestNumberBuffer, "TestRenderTexture", TestRenderTexture);
        TestCompute.SetTexture(KernelTestDepthBuffer, "TestRenderTexture", TestRenderTexture);
        TestCompute.SetTexture(KernelTestRegressionBuffer, "TestRenderTexture", TestRenderTexture);

#endif
        Shader.SetGlobalBuffer("NumberBuffer", NumberBuffer);
        Shader.SetGlobalBuffer("DepthBuffer", DepthBuffer);
        Shader.SetGlobalBuffer("RegressionBuffer", RegressionBuffer);
        Shader.SetGlobalInt("Dimension", dimension);
    }

    int p = 0;

    private void Update()
    {
        BeforeForwardOpaque.Clear();

        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.None);
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);

        Matrix4x4 lightMatrix = DirectionalLight.transform.worldToLocalMatrix;
        //if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLCore 
        //    || SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES3)
        {
            Vector4 forward = lightMatrix.GetRow(2);
            lightMatrix.SetRow(2, -forward);
        }
        BeforeForwardOpaque.SetViewMatrix(lightMatrix);
        Matrix4x4 projMatrix = Matrix4x4.Ortho(-1, 1, -1, 1, 0.1f, 10);
        BeforeForwardOpaque.SetProjectionMatrix(projMatrix);
        BeforeForwardOpaque.SetViewport(new Rect(0, 0, dimension, dimension));

        /*if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Metal)
        {
            Matrix4x4 mAdj = Matrix4x4.identity;
            mAdj.m22 = -0.5f;
            mAdj.m23 = 0.5f;
            projMatrix = mAdj * projMatrix;
        }*/
        BeforeForwardOpaque.SetGlobalMatrix("_LightVP", projMatrix * lightMatrix);
        BeforeForwardOpaque.SetGlobalFloat("_HairAlpha", HairAlpha);

        BeforeForwardOpaque.BeginSample("ShadowMapMaterial");
        Renderer[] renderers = FindObjectsOfType<Renderer>();
        for (int i = 0, imax = renderers.Length; i < imax; i++)
        {
            Renderer rend = renderers[i];
            if (rend.shadowCastingMode != ShadowCastingMode.Off)
            {
                //casterAABBs.Add(rend.bounds);
                if (BoundsUtils.IntersectFrustum(rend.bounds, rend.localToWorldMatrix, Camera.main.cullingMatrix))
                {
                    for (int m = 0, mmax = rend.sharedMaterials.Length; m < mmax; m++)
                    {
                        BeforeForwardOpaque.DrawRenderer(rend, ShadowMapMaterial, m, 0);
                    }
                }
            }
        }
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.black);
        BeforeForwardOpaque.EndSample("ShadowMapMaterial");


        BeforeForwardOpaque.DispatchCompute(SortCompute, KernelSortDepth, dimension / 8, dimension / 8, 1);
        
        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);

        BeforeForwardOpaque.SetViewMatrix(camera.worldToCameraMatrix);
        BeforeForwardOpaque.SetProjectionMatrix(camera.projectionMatrix);
        BeforeForwardOpaque.SetGlobalVector("CameraPos", camera.transform.position);
        BeforeForwardOpaque.SetGlobalVector("LightDir", DirectionalLight.transform.forward);

        BeforeForwardOpaque.SetGlobalColor("_HairColor", HairColor);


#if UNITY_EDITOR
        BeforeForwardOpaque.DispatchCompute(TestCompute, KernelResetTestResult, dimension / 8, dimension / 8, 1);
        BeforeForwardOpaque.SetComputeIntParam(TestCompute, "TestIndex", TestIndex);
        if (TestKernel == ETestKernel.KernelTestNumberBuffer)
        {
            BeforeForwardOpaque.DispatchCompute(TestCompute, KernelTestNumberBuffer, dimension / 8, dimension / 8, 1);
        }
        else if (TestKernel == ETestKernel.KernelTestDepthBuffer)
        {
            BeforeForwardOpaque.DispatchCompute(TestCompute, KernelTestDepthBuffer, dimension / 8, dimension / 8, 1);

        }
        else if (TestKernel == ETestKernel.KernelTestRegressionBuffer)
        {
            BeforeForwardOpaque.DispatchCompute(TestCompute, KernelTestRegressionBuffer, dimension / 8, dimension / 8, 1);
        }
#endif
        AfterForwardOpaque.Clear();
        AfterForwardOpaque.DispatchCompute(ResetCompute, KernelResetDepthBuffer, dimension / 8, dimension / 8, 1);
        AfterForwardOpaque.DispatchCompute(ResetCompute, KernelResetRegressionBuffer, dimension / 8, dimension / 8, 1);
        AfterForwardOpaque.DispatchCompute(ResetCompute, KernelResetNumberBuffer, dimension / 8, dimension / 8, 1);

    }

    private void OnDestroy()
    {
        DepthBuffer.Dispose();
        NumberBuffer.Dispose();
        RegressionBuffer.Dispose();
    }
}
