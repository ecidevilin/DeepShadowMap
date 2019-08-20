using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class DeepShadowMap : MonoBehaviour
{
    private Camera camera;
    private CommandBuffer BeforeForwardOpaque;
    private CommandBuffer AfterForwardOpaque;

    private ComputeBuffer NumberBuffer;
    private ComputeBuffer DepthBuffer;

    public Light DirectionalLight;
    public Material ShadowMapMaterial;
    [Range(0, 1)]
    public float HairAlpha = 0.7f;

    public ComputeShader ResetCompute;
    private int KernelResetNumberBuffer;
    private int KernelResetDepthBuffer;

    private int KernelScreenSpaceDeepShadowmap;
    private int KernelGaussianBlurShadow;
    private RenderTexture _DepthTex;
    private RenderTexture _ShadowTex;
    private RenderTexture _BlurTex;

    public ComputeShader ResolveCompute;
    public Material DepthMaterial;

#if UNITY_EDITOR
    public ComputeShader TestCompute;
    private int KernelResetTestResult;
    private int KernelTestNumberBuffer;
    private int KernelTestDepthBuffer;
    public RenderTexture TestRenderTexture;
    [Range(0, 49)]
    public int TestIndex;
    public enum ETestKernel
    {
        KernelTestNumberBuffer,
        KernelTestDepthBuffer,
    }
    public ETestKernel TestKernel;
#endif
    
    public Color HairColor;

    const int dimension = 1024;
    const int elements = 32;

    public bool _AsDefaultShadowmap = false;

    private void Start()
    {
        int numElement = dimension * dimension * elements;

        camera = GetComponent<Camera>();
        BeforeForwardOpaque = new CommandBuffer();
        AfterForwardOpaque = new CommandBuffer();
        camera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, BeforeForwardOpaque);
        camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, AfterForwardOpaque);

        NumberBuffer = new ComputeBuffer(dimension * dimension, sizeof(uint));
        DepthBuffer = new ComputeBuffer(numElement, sizeof(float) * 2);

        _DepthTex = new RenderTexture(Screen.width, Screen.height, 16, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
        _DepthTex.Create();
        _ShadowTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear)
        {
            enableRandomWrite = true,
        };
        _ShadowTex.Create();
        _BlurTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear)
        {
            enableRandomWrite = true,
        };
        _BlurTex.Create();

        KernelResetNumberBuffer = ResetCompute.FindKernel("KernelResetNumberBuffer");
        KernelResetDepthBuffer = ResetCompute.FindKernel("KernelResetDepthBuffer");

        ResetCompute.SetInt("Dimension", dimension);
        ResetCompute.SetBuffer(KernelResetNumberBuffer, "NumberBuffer", NumberBuffer);
        ResetCompute.SetBuffer(KernelResetDepthBuffer, "DepthBuffer", DepthBuffer);

        ResetCompute.Dispatch(KernelResetNumberBuffer, dimension / 8, dimension / 8, 1);

        KernelScreenSpaceDeepShadowmap = ResolveCompute.FindKernel("KernelScreenSpaceDeepShadowmap");
        KernelGaussianBlurShadow = ResolveCompute.FindKernel("KernelGaussianBlurShadow");

        ResolveCompute.SetInt("Dimension", dimension);
        ResolveCompute.SetBuffer(KernelScreenSpaceDeepShadowmap, "NumberBuffer", NumberBuffer);
        ResolveCompute.SetBuffer(KernelScreenSpaceDeepShadowmap, "DepthBuffer", DepthBuffer);
        ResolveCompute.SetTexture(KernelScreenSpaceDeepShadowmap, "_DepthTex", _DepthTex);
        ResolveCompute.SetTexture(KernelScreenSpaceDeepShadowmap, "_ShadowTex", _ShadowTex);

#if UNITY_EDITOR && DEBUG_DSM
        KernelResetTestResult = TestCompute.FindKernel("KernelResetTestResult");
        KernelTestNumberBuffer = TestCompute.FindKernel("KernelTestNumberBuffer");
        KernelTestDepthBuffer = TestCompute.FindKernel("KernelTestDepthBuffer");
        TestCompute.SetInt("Dimension", dimension);
        TestCompute.SetBuffer(KernelTestNumberBuffer, "NumberBuffer", NumberBuffer);
        TestCompute.SetBuffer(KernelTestDepthBuffer, "DepthBuffer", DepthBuffer);
        TestRenderTexture.enableRandomWrite = true;
        TestCompute.SetTexture(KernelResetTestResult, "TestRenderTexture", TestRenderTexture);
        TestCompute.SetTexture(KernelTestNumberBuffer, "TestRenderTexture", TestRenderTexture);
        TestCompute.SetTexture(KernelTestDepthBuffer, "TestRenderTexture", TestRenderTexture);

#endif
        Shader.SetGlobalBuffer("NumberBuffer", NumberBuffer);
        Shader.SetGlobalBuffer("DepthBuffer", DepthBuffer);
        Shader.SetGlobalInt("Dimension", dimension);
    }

    private void Update()
    {
        BeforeForwardOpaque.Clear();

        Renderer[] renderers = FindObjectsOfType<Renderer>();

        BeforeForwardOpaque.BeginSample("DepthOnly");
        BeforeForwardOpaque.SetViewMatrix(camera.worldToCameraMatrix);
        BeforeForwardOpaque.SetProjectionMatrix(camera.projectionMatrix);
        BeforeForwardOpaque.SetRenderTarget(_DepthTex);
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.black);
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
                        var mat = rend.sharedMaterial; // "sharedMaterials" cases bugs;
                        int pass = mat.FindPass("DepthOnly");
                        if (pass < 0)
                        {
                            BeforeForwardOpaque.DrawRenderer(rend, DepthMaterial, m, 0);
                        }
                        else
                        {
                            BeforeForwardOpaque.DrawRenderer(rend, mat, m, pass);
                        }
                        mat.SetShaderPassEnabled("DepthOnly", false);
                    }
                }
            }
        }
        BeforeForwardOpaque.EndSample("DepthOnly");


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
        Matrix4x4 projMatrix = Matrix4x4.Ortho(-0.5f, 0.5f, -0.5f, 0.5f, 0.1f, 10);
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
                        var mat = rend.sharedMaterial; // "sharedMaterials" cases bugs;
                        int pass = mat.FindPass("DeepShadowCaster");
                        if (pass < 0)
                        {
                            BeforeForwardOpaque.DrawRenderer(rend, ShadowMapMaterial, m, 0);
                        }
                        else
                        {
                            BeforeForwardOpaque.DrawRenderer(rend, mat, m, pass);
                        }
                        mat.SetShaderPassEnabled("DeepShadowCaster", false);
                    }
                }
            }
        }
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.black);
        BeforeForwardOpaque.EndSample("ShadowMapMaterial");

        BeforeForwardOpaque.SetRenderTarget(_ShadowTex);
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);
        BeforeForwardOpaque.SetComputeIntParam(ResolveCompute, "_ScreenWidth", Screen.width);
        BeforeForwardOpaque.SetComputeIntParam(ResolveCompute, "_ScreenHeight", Screen.height);
        BeforeForwardOpaque.SetComputeMatrixParam(ResolveCompute, "_CameraInvVP", camera.cullingMatrix.inverse);
        BeforeForwardOpaque.SetComputeMatrixParam(ResolveCompute, "_LightVP", projMatrix * lightMatrix);

        BeforeForwardOpaque.SetComputeIntParam(ResolveCompute, "_AsDefaultShadowmap", _AsDefaultShadowmap ? 1 : 0);

        BeforeForwardOpaque.DispatchCompute(ResolveCompute, KernelScreenSpaceDeepShadowmap, (7 + Screen.width) / 8, (7 + Screen.height) / 8, 1);


        BeforeForwardOpaque.SetRenderTarget(_BlurTex);
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);
        BeforeForwardOpaque.SetComputeIntParam(ResolveCompute, "_BlurStep", 1);
        BeforeForwardOpaque.SetComputeTextureParam(ResolveCompute, KernelGaussianBlurShadow, "_SourceShadowTexture", _ShadowTex);
        BeforeForwardOpaque.SetComputeTextureParam(ResolveCompute, KernelGaussianBlurShadow, "_BlurShadowTexture", _BlurTex);
        BeforeForwardOpaque.DispatchCompute(ResolveCompute, KernelGaussianBlurShadow, (7 + Screen.width) / 8, (7 + Screen.height) / 8, 1);

        //BeforeForwardOpaque.SetRenderTarget(_ShadowTex);
        //BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);
        //BeforeForwardOpaque.SetComputeIntParam(ResolveCompute, "_BlurStep", 2);
        //BeforeForwardOpaque.SetComputeTextureParam(ResolveCompute, KernelGaussianBlurShadow, "_SourceShadowTexture", _BlurTex);
        //BeforeForwardOpaque.SetComputeTextureParam(ResolveCompute, KernelGaussianBlurShadow, "_BlurShadowTexture", _ShadowTex);
        //BeforeForwardOpaque.DispatchCompute(ResolveCompute, KernelGaussianBlurShadow, (7 + Screen.width) / 8, (7 + Screen.height) / 8, 1);

        //BeforeForwardOpaque.SetRenderTarget(_BlurTex);
        //BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);
        //BeforeForwardOpaque.SetComputeIntParam(ResolveCompute, "_BlurStep", 4);
        //BeforeForwardOpaque.SetComputeTextureParam(ResolveCompute, KernelGaussianBlurShadow, "_SourceShadowTexture", _ShadowTex);
        //BeforeForwardOpaque.SetComputeTextureParam(ResolveCompute, KernelGaussianBlurShadow, "_BlurShadowTexture", _BlurTex);
        //BeforeForwardOpaque.DispatchCompute(ResolveCompute, KernelGaussianBlurShadow, (7 + Screen.width) / 8, (7 + Screen.height) / 8, 1);

        BeforeForwardOpaque.SetGlobalTexture("_BlurShadowTexture", _BlurTex);

        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);

        BeforeForwardOpaque.SetViewMatrix(camera.worldToCameraMatrix);
        BeforeForwardOpaque.SetProjectionMatrix(camera.projectionMatrix);
        BeforeForwardOpaque.SetGlobalVector("CameraPos", camera.transform.position);
        BeforeForwardOpaque.SetGlobalVector("LightDir", DirectionalLight.transform.forward);

        BeforeForwardOpaque.SetGlobalColor("_HairColor", HairColor);


#if UNITY_EDITOR && DEBUG_DSM
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
#endif
        AfterForwardOpaque.Clear();
        AfterForwardOpaque.DispatchCompute(ResetCompute, KernelResetDepthBuffer, dimension / 8, dimension / 8, 1);
        AfterForwardOpaque.DispatchCompute(ResetCompute, KernelResetNumberBuffer, dimension / 8, dimension / 8, 1);
    }

    private void OnDestroy()
    {
        DepthBuffer.Dispose();
        NumberBuffer.Dispose();
    }
}
