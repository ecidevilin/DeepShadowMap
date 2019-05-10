using UnityEngine;
using UnityEngine.Rendering;

public class DeepShadowMap : MonoBehaviour
{
    private Camera camera;
    private CommandBuffer BeforeForwardOpaque;
    private CommandBuffer AfterForwardOpaque;

    private ComputeBuffer HeaderList;
    private ComputeBuffer LinkedList;
    private ComputeBuffer FittingFuncList;

    public Light DirectionalLight;
    public Material ShadowMapMaterial;
    [Range(0, 1)]
    public float HairAlpha = 0.7f;

    public ComputeShader ResetBuffer;
    private int KernelResetHeaderList;
    private int KernelResetLinkedList;
    private int KernelResetFittingFuncList;

    public ComputeShader SortBuffer;
    private int KernelSortDeepShadowMap;

#if UNITY_EDITOR
    public ComputeShader TestBuffer;
    private int KernelResetTestResult;
    private int KernelTestHeaderList;
    private int KernelTestLinkedList;
    private int KernelTestFittingFuncList;
    public RenderTexture TestRt;
    [Range(0, 49)]
    public int TestIndex;
    public enum ETestKernel
    {
        KernelTestHeaderList,
        KernelTestLinkedList,
        KernelTestFittingFuncList,
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

        HeaderList = new ComputeBuffer(dimension * dimension, HeaderNode.StructSize());
        LinkedList = new ComputeBuffer(numElement, LinkedNode.StructSize());
        FittingFuncList = new ComputeBuffer(dimension * dimension, sizeof(float) * 12);

        KernelResetHeaderList = ResetBuffer.FindKernel("KernelResetHeaderList");
        KernelResetLinkedList = ResetBuffer.FindKernel("KernelResetLinkedList");
        KernelResetFittingFuncList = ResetBuffer.FindKernel("KernelResetFittingFuncList");

        ResetBuffer.SetInt("Dimension", dimension);
        ResetBuffer.SetBuffer(KernelResetHeaderList, "HeaderList", HeaderList);
        ResetBuffer.SetBuffer(KernelResetLinkedList, "LinkedList", LinkedList);
        ResetBuffer.SetBuffer(KernelResetFittingFuncList, "FittingFuncList", FittingFuncList);

        ResetBuffer.Dispatch(KernelResetHeaderList, dimension / 8, dimension / 8, 1);

        KernelSortDeepShadowMap = SortBuffer.FindKernel("KernelSortDeepShadowMap");
        SortBuffer.SetInt("Dimension", dimension);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "HeaderList", HeaderList);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "LinkedList", LinkedList);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "FittingFuncList", FittingFuncList);

#if UNITY_EDITOR
        KernelResetTestResult = TestBuffer.FindKernel("KernelResetTestResult");
        KernelTestHeaderList = TestBuffer.FindKernel("KernelTestHeaderList");
        KernelTestLinkedList = TestBuffer.FindKernel("KernelTestLinkedList");
        KernelTestFittingFuncList = TestBuffer.FindKernel("KernelTestFittingFuncList");
        TestBuffer.SetInt("Dimension", dimension);
        TestBuffer.SetBuffer(KernelTestHeaderList, "HeaderList", HeaderList);
        TestBuffer.SetBuffer(KernelTestLinkedList, "HeaderList", HeaderList);
        TestBuffer.SetBuffer(KernelTestLinkedList, "LinkedList", LinkedList);
        TestBuffer.SetBuffer(KernelTestFittingFuncList, "FittingFuncList", FittingFuncList);
        TestRt.enableRandomWrite = true;
        TestBuffer.SetTexture(KernelResetTestResult, "TestRt", TestRt);
        TestBuffer.SetTexture(KernelTestHeaderList, "TestRt", TestRt);
        TestBuffer.SetTexture(KernelTestLinkedList, "TestRt", TestRt);
        TestBuffer.SetTexture(KernelTestFittingFuncList, "TestRt", TestRt);

#endif
        Shader.SetGlobalBuffer("HeaderList", HeaderList);
        Shader.SetGlobalBuffer("LinkedList", LinkedList);
        Shader.SetGlobalBuffer("FittingFuncList", FittingFuncList);
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


        BeforeForwardOpaque.DispatchCompute(SortBuffer, KernelSortDeepShadowMap, dimension / 8, dimension / 8, 1);
        
        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);

        BeforeForwardOpaque.SetViewMatrix(camera.worldToCameraMatrix);
        BeforeForwardOpaque.SetProjectionMatrix(camera.projectionMatrix);
        BeforeForwardOpaque.SetGlobalVector("CameraPos", camera.transform.position);
        BeforeForwardOpaque.SetGlobalVector("LightDir", DirectionalLight.transform.forward);

        BeforeForwardOpaque.SetGlobalColor("_HairColor", HairColor);


#if UNITY_EDITOR
        BeforeForwardOpaque.DispatchCompute(TestBuffer, KernelResetTestResult, dimension / 8, dimension / 8, 1);
        BeforeForwardOpaque.SetComputeIntParam(TestBuffer, "TestIndex", TestIndex);
        if (TestKernel == ETestKernel.KernelTestHeaderList)
        {
            BeforeForwardOpaque.DispatchCompute(TestBuffer, KernelTestHeaderList, dimension / 8, dimension / 8, 1);
        }
        else if (TestKernel == ETestKernel.KernelTestLinkedList)
        {
            BeforeForwardOpaque.DispatchCompute(TestBuffer, KernelTestLinkedList, dimension / 8, dimension / 8, 1);

        }
        else if (TestKernel == ETestKernel.KernelTestFittingFuncList)
        {
            BeforeForwardOpaque.DispatchCompute(TestBuffer, KernelTestFittingFuncList, dimension / 8, dimension / 8, 1);
        }
#endif
        AfterForwardOpaque.Clear();
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetLinkedList, dimension / 8, dimension / 8, 1);
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetFittingFuncList, dimension / 8, dimension / 8, 1);
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetHeaderList, dimension / 8, dimension / 8, 1);

    }

    private void OnDestroy()
    {
        LinkedList.Dispose();
        HeaderList.Dispose();
        FittingFuncList.Dispose();
    }
}
