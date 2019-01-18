using UnityEngine;
using UnityEngine.Rendering;

public class DeepShadowMap : MonoBehaviour
{
    private Camera camera;
    private CommandBuffer BeforeForwardOpaque;
    private CommandBuffer AfterForwardOpaque;

    private ComputeBuffer HeaderList;
    private ComputeBuffer LinkedList;
    private ComputeBuffer DoublyLinkedList;
    private ComputeBuffer NeighborsList;
    
    public Light DirectionalLight;
    public Material ShadowMapMaterial;
    [Range(0, 1)]
    public float HairAlpha = 0.7f;

    public ComputeShader ResetBuffer;
    private int KernelResetHeaderList;
    private int KernelResetLinkedList;
    private int KernelResetDoublyLinkedList;
    private int KernelResetNeighborsList;

    private ComputeBuffer counterBuffer;

    public ComputeShader SortBuffer;
    private int KernelSortDeepShadowMap;

    public ComputeShader LinkBuffer;
    private int KernelLinkDeepShadowMap;

    public ComputeShader TestBuffer;
    private int KernelTestBuffer;
    public RenderTexture TestRt;
    [Range(0, 49)]
    public int TestIndex;
    
    public Color HairColor;

    const int dimension = 512;
    const int elements = 64;

    private void Start()
    {
        int numElement = dimension * dimension * elements;

        camera = GetComponent<Camera>();
        BeforeForwardOpaque = new CommandBuffer();
        AfterForwardOpaque = new CommandBuffer();
        camera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, BeforeForwardOpaque);
        camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, AfterForwardOpaque);

        HeaderList = new ComputeBuffer(numElement, HeaderNode.StructSize());
        LinkedList = new ComputeBuffer(numElement, LinkedNode.StructSize(), ComputeBufferType.Counter);
        DoublyLinkedList = new ComputeBuffer(numElement, DoublyLinkedNode.StructSize());
        NeighborsList = new ComputeBuffer(numElement, NeighborsNode.StructSize());
        LinkedList.SetCounterValue(0);

        ShadowMapMaterial.SetInt("Dimension", dimension);
        ShadowMapMaterial.SetBuffer("HeaderList", HeaderList);
        ShadowMapMaterial.SetBuffer("LinkedList", LinkedList);

        KernelResetHeaderList = ResetBuffer.FindKernel("KernelResetHeaderList");
        KernelResetLinkedList = ResetBuffer.FindKernel("KernelResetLinkedList");
        KernelResetDoublyLinkedList = ResetBuffer.FindKernel("KernelResetDoublyLinkedList");
        KernelResetNeighborsList = ResetBuffer.FindKernel("KernelResetNeighborsList");

        ResetBuffer.SetInt("Dimension", dimension);
        ResetBuffer.SetBuffer(KernelResetHeaderList, "HeaderList", HeaderList);
        ResetBuffer.SetBuffer(KernelResetLinkedList, "LinkedList", LinkedList);
        ResetBuffer.SetBuffer(KernelResetDoublyLinkedList, "DoublyLinkedList", DoublyLinkedList);
        ResetBuffer.SetBuffer(KernelResetNeighborsList, "NeighborsList", NeighborsList);

        counterBuffer = new ComputeBuffer(3, sizeof(uint));
        int[] ResetLinkedList = new int[3] { 0, 1, 1 };
        counterBuffer.SetData(ResetLinkedList);

        ResetBuffer.Dispatch(KernelResetHeaderList, dimension / 8, dimension * elements / 8, 1);

        KernelSortDeepShadowMap = SortBuffer.FindKernel("KernelSortDeepShadowMap");
        SortBuffer.SetInt("Dimension", dimension);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "HeaderList", HeaderList);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "LinkedList", LinkedList);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "DoublyLinkedList", DoublyLinkedList);

        KernelLinkDeepShadowMap = LinkBuffer.FindKernel("KernelLinkDeepShadowMap");
        LinkBuffer.SetInt("Dimension", dimension);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "HeaderList", HeaderList);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "LinkedList", LinkedList);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "DoublyLinkedList", DoublyLinkedList);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "NeighborsList", NeighborsList);

        KernelTestBuffer = TestBuffer.FindKernel("KernelTestBuffer");
        TestBuffer.SetInt("Dimension", dimension);
        TestBuffer.SetBuffer(KernelTestBuffer, "HeaderList", HeaderList);
        TestBuffer.SetBuffer(KernelTestBuffer, "DoublyLinkedList", DoublyLinkedList);
        TestRt.enableRandomWrite = true;
        TestBuffer.SetTexture(KernelTestBuffer, "Result", TestRt);

        Shader.SetGlobalBuffer("HeaderList", HeaderList);
        Shader.SetGlobalBuffer("NeighborsList", NeighborsList);
        Shader.SetGlobalBuffer("DoublyLinkedList", DoublyLinkedList);
        Shader.SetGlobalInt("Dimension", dimension);
    }

    int p = 0;

    private void Update()
    {
        BeforeForwardOpaque.Clear();

        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.None);
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);

        Matrix4x4 lightMatrix = DirectionalLight.transform.worldToLocalMatrix;
        Vector4 forward = lightMatrix.GetRow(2);
        lightMatrix.SetRow(2, -forward);
        BeforeForwardOpaque.SetViewMatrix(lightMatrix);
        Matrix4x4 projMatrix = Matrix4x4.Ortho(-5, 5, -5, 5, 0.1f, 10);
        BeforeForwardOpaque.SetProjectionMatrix(projMatrix);
        BeforeForwardOpaque.SetViewport(new Rect(0, 0, dimension, dimension));

        BeforeForwardOpaque.SetGlobalMatrix("_LightVP", projMatrix * lightMatrix);
        BeforeForwardOpaque.SetGlobalFloat("_HairAlpha", HairAlpha);

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


        BeforeForwardOpaque.DispatchCompute(SortBuffer, KernelSortDeepShadowMap, dimension / 8, dimension / 8, 1);
        BeforeForwardOpaque.DispatchCompute(LinkBuffer, KernelLinkDeepShadowMap, dimension / 8, dimension / 8, 1);

        BeforeForwardOpaque.SetComputeIntParam(TestBuffer, "TestIndex", TestIndex);
        BeforeForwardOpaque.DispatchCompute(TestBuffer, KernelTestBuffer, dimension / 8, dimension / 8, 1);

        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);

        BeforeForwardOpaque.SetViewMatrix(camera.worldToCameraMatrix);
        BeforeForwardOpaque.SetProjectionMatrix(camera.projectionMatrix);
        BeforeForwardOpaque.SetGlobalVector("CameraPos", camera.transform.position);
        BeforeForwardOpaque.SetGlobalVector("LightDir", DirectionalLight.transform.forward);

        BeforeForwardOpaque.SetGlobalColor("_HairColor", HairColor);

        AfterForwardOpaque.Clear();
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetHeaderList, dimension / 8, dimension * elements / 8, 1);
        AfterForwardOpaque.CopyCounterValue(LinkedList, counterBuffer, 0);
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetLinkedList, counterBuffer, 0);
        //AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetDoublyLinkedList, 512 / 8, 512 * 50 / 8, 1);
        //AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetNeighborsList, 512 / 8, 512 * 50 / 8, 1);
    }

    private void OnDestroy()
    {
        LinkedList.Dispose();
        HeaderList.Dispose();
        DoublyLinkedList.Dispose();
        NeighborsList.Dispose();
        counterBuffer.Dispose();
    }
}
