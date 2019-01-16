using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public static class BoundsUtil
{
    public static bool IsValid(this Bounds bound)
    {
        return bound.min != Vector3.positiveInfinity && bound.max != Vector3.negativeInfinity;
    }
    public static Bounds DefaultBounds()
    {
        Bounds ret = new Bounds();
        ret.SetMinMax(Vector3.positiveInfinity, Vector3.negativeInfinity);
        return ret;
    }
}

public static class CameraUtil
{
    public static Vector3[] GetFrustumPoints(this Camera cam)
    {
        Vector3[] ret = new Vector3[8]
        {
            new Vector3(-1, -1, -1),
            new Vector3(1, -1, -1),
            new Vector3(1, 1, -1),
            new Vector3(-1, 1, -1),
            new Vector3(-1, -1, 1),
            new Vector3(1, -1, 1),
            new Vector3(1, 1, 1),
            new Vector3(-1, 1, 1),
        };
        for (int i = 0; i < 8; i++)
        {
            Vector4 v = ret[i];
            v.w = 1;
            v = cam.cullingMatrix.inverse * v;
            v *= 1 / v.w;
            ret[i] = v;
        }
        return ret;
    }
}



public struct HeaderNode
{
    public int start;
    public static int StructSize()
    {
        return sizeof(int);
    }
};

public struct LinkedNode
{
    public float depth;
    public float alpha;
    public int next;
    public static int StructSize()
    {
        return sizeof(float) * 2 + sizeof(int);
    }
};

public struct DoublyLinkedNode
{
    public float depth;
    public float shading;  // stores final shading
    public int next;
    public int prev;
    public static int StructSize()
    {
        return sizeof(float) * 2 + sizeof(int) * 2;
    }
};

public struct NeighborsNode
{
    public int right;
    public int top;
    public static int StructSize()
    {
        return sizeof(int) * 2;
    }
};

public class DeepShadowMap : MonoBehaviour
{
    private Camera camera;
    private CommandBuffer BeforeForwardOpaque;
    public Light DirectionalLight;
    public Mesh mesh;
    public Material mat;
    public RenderTexture rt;

    public Bounds Bounds;

    private ComputeBuffer LinkedList;
    private ComputeBuffer HeaderList;
    private ComputeBuffer DoublyLinkedList;
    private ComputeBuffer NeighborsList;

    public ComputeShader ResetBuffer;
    private int KernelResetHeaderList;
    private int KernelResetLinkedList;
    private int KernelResetDoublyLinkedList;
    private int KernelResetNeighborsList;

    ComputeBuffer counterBuffer;

    public ComputeShader SortBuffer;
    public ComputeShader LinkBuffer;
    private int KernelSortDeepShadowMap;
    private int KernelLinkDeepShadowMap;

    [Range(0, 1)]
    public float HairAlpha = 0.7f;

    public ComputeShader TestBuffer;
    private int KernelTestBuffer;
    public RenderTexture TestRt;
    [Range(0, 49)]
    public int TestIndex;

    public Material ReceiverMaterial;

    private CommandBuffer AfterForwardOpaque;

    private void Awake()
    {
        int dimension = 512;
        int numElement = 512 * 512 * 50;

        BeforeForwardOpaque = new CommandBuffer();
        AfterForwardOpaque = new CommandBuffer();
        camera = GetComponent<Camera>();
        camera.AddCommandBuffer(CameraEvent.BeforeForwardOpaque, BeforeForwardOpaque);
        camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, AfterForwardOpaque);
        LinkedList = new ComputeBuffer(numElement, LinkedNode.StructSize(), ComputeBufferType.Counter);
        LinkedList.SetCounterValue(0);
        HeaderList = new ComputeBuffer(numElement, HeaderNode.StructSize());
        BeforeForwardOpaque.SetRenderTarget(rt, 0);
        BeforeForwardOpaque.SetViewport(new Rect(0, 0, dimension, dimension));
        mat.SetInt("Dimension", dimension);
        mat.SetBuffer("HeaderList", HeaderList);
        mat.SetBuffer("LinkedList", LinkedList);
        mat.SetFloat("_Alpha", HairAlpha);

        KernelResetHeaderList = ResetBuffer.FindKernel("KernelResetHeaderList");
        ResetBuffer.SetBuffer(KernelResetHeaderList, "HeaderList", HeaderList);
        ResetBuffer.SetInt("Dimension", dimension);
        ResetBuffer.Dispatch(KernelResetHeaderList, 512 / 8, 512 * 50 / 8, 1);
        KernelResetLinkedList = ResetBuffer.FindKernel("KernelResetLinkedList");
        ResetBuffer.SetBuffer(KernelResetLinkedList, "LinkedList", LinkedList);
        counterBuffer = new ComputeBuffer(3, sizeof(uint));
        int[] ResetDAN = new int[3] { 0, 1, 1 };
        counterBuffer.SetData(ResetDAN);


        DoublyLinkedList = new ComputeBuffer(numElement, DoublyLinkedNode.StructSize());
        NeighborsList = new ComputeBuffer(numElement, NeighborsNode.StructSize());

        KernelResetDoublyLinkedList = ResetBuffer.FindKernel("KernelResetDoublyLinkedList");
        ResetBuffer.SetBuffer(KernelResetDoublyLinkedList, "DoublyLinkedList", DoublyLinkedList);
        KernelResetNeighborsList = ResetBuffer.FindKernel("KernelResetNeighborsList");
        ResetBuffer.SetBuffer(KernelResetNeighborsList, "NeighborsList", NeighborsList);

        KernelSortDeepShadowMap = SortBuffer.FindKernel("KernelSortDeepShadowMap");
        KernelLinkDeepShadowMap = LinkBuffer.FindKernel("KernelLinkDeepShadowMap");
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "HeaderList", HeaderList);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "LinkedList", LinkedList);
        SortBuffer.SetBuffer(KernelSortDeepShadowMap, "DoublyLinkedList", DoublyLinkedList);
        SortBuffer.SetInt("Dimension", dimension);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "HeaderList", HeaderList);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "LinkedList", LinkedList);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "DoublyLinkedList", DoublyLinkedList);
        LinkBuffer.SetBuffer(KernelLinkDeepShadowMap, "NeighborsList", NeighborsList);
        LinkBuffer.SetInt("Dimension", dimension);


        ReceiverMaterial.SetBuffer("HeaderList", HeaderList);
        ReceiverMaterial.SetBuffer("NeighborsList", NeighborsList);
        ReceiverMaterial.SetBuffer("DoublyLinkedList", DoublyLinkedList);

        ReceiverMaterial.SetInt("Dimension", dimension);

        KernelTestBuffer = TestBuffer.FindKernel("KernelTestBuffer");
        TestBuffer.SetBuffer(KernelTestBuffer, "DoublyLinkedList", DoublyLinkedList);
        TestBuffer.SetBuffer(KernelTestBuffer, "HeaderList", HeaderList);

        TestRt.enableRandomWrite = true;
        TestBuffer.SetTexture(KernelTestBuffer, "Result", TestRt);
        TestBuffer.SetInt("Dimension", dimension);


        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetHeaderList, 512 / 8, 512 * 50 / 8, 1);
        AfterForwardOpaque.CopyCounterValue(LinkedList, counterBuffer, 0);
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetLinkedList, counterBuffer, 0);
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetDoublyLinkedList, 512 / 8, 512 * 50 / 8, 1);
        AfterForwardOpaque.DispatchCompute(ResetBuffer, KernelResetNeighborsList, 512 / 8, 512 * 50 / 8, 1);
        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.None);
        BeforeForwardOpaque.ClearRenderTarget(true, true, Color.white);
        Renderer[] renderers = FindObjectsOfType<Renderer>();
        for (int i = 0, imax = renderers.Length; i < imax; i++)
        {
            Renderer rend = renderers[i];
            if (rend.shadowCastingMode != ShadowCastingMode.Off)
            {
                //casterAABBs.Add(rend.bounds);
                if (IntersectAABBFrustumFull(rend.bounds, rend.localToWorldMatrix, Camera.main.cullingMatrix))
                {
                    for (int m = 0, mmax = rend.sharedMaterials.Length; m < mmax; m++)
                    {
                        BeforeForwardOpaque.DrawRenderer(rend, mat, m, 0);
                    }
                }
            }
        }
        BeforeForwardOpaque.DispatchCompute(SortBuffer, KernelSortDeepShadowMap, 512 / 8, 512 / 8, 1);
        BeforeForwardOpaque.DispatchCompute(LinkBuffer, KernelLinkDeepShadowMap, 512 / 8, 512 / 8, 1);

        BeforeForwardOpaque.DispatchCompute(TestBuffer, KernelTestBuffer, 512 / 8, 512 / 8, 1);
        BeforeForwardOpaque.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
    }

    int p = 0;

    private void Update()
    {
        Matrix4x4 lightMatrix = DirectionalLight.transform.worldToLocalMatrix;
        Vector4 forward = lightMatrix.GetRow(2);
        lightMatrix.SetRow(2, -forward);
        BeforeForwardOpaque.SetViewMatrix(lightMatrix);

        Matrix4x4 projMatrix = Matrix4x4.Ortho(-20, 20, -20, 20, 0.1f, 30);
        BeforeForwardOpaque.SetProjectionMatrix(projMatrix);

        BeforeForwardOpaque.SetGlobalMatrix("_LightVP", projMatrix * lightMatrix);
        BeforeForwardOpaque.SetGlobalFloat("_Alpha", HairAlpha);

        BeforeForwardOpaque.SetComputeIntParam(TestBuffer, "TestIndex", TestIndex);


        BeforeForwardOpaque.SetViewMatrix(camera.worldToCameraMatrix);
        BeforeForwardOpaque.SetProjectionMatrix(camera.projectionMatrix);
        BeforeForwardOpaque.SetGlobalVector("CameraPos", camera.transform.position);
        BeforeForwardOpaque.SetGlobalVector("LightDir", DirectionalLight.transform.forward);
    }

    private void RecycleFunc()
    {
        {
            //Bounds casterBounds = new Bounds();
            //casterBounds.SetMinMax(Vector3.positiveInfinity, Vector3.negativeInfinity);
            //List<Bounds> casterAABBs = new List<Bounds>();
            //ExtractActiveCasterInfo(Camera.main, ref casterBounds, ref casterAABBs);
            //Debug.Log(casterAABBs);
            //Bounds = casterBounds;

            //SetupDirectionalLightShadowCamera(new Bounds(), DirectionalLight, 1024, 1024, Bounds, Camera.main, out lightMatrix, out projMatrix);
            //Camera lightCam = DirectionalLight.GetComponent<Camera>();
            AfterForwardOpaque.Clear();
            BeforeForwardOpaque.Clear();




            //for (int i = 0, imax = renderers.Length; i < imax; i++)
            //{
            //    Renderer rend = renderers[i];
            //    if (rend.receiveShadows)
            //    {
            //        if (IntersectAABBFrustumFull(rend.bounds, rend.localToWorldMatrix, Camera.main.cullingMatrix))
            //        {
            //            BeforeForwardOpaque.DrawRenderer(rend, ReceiverMaterial, 0, 0);
            //        }
            //    }
            //}
            //p = p++ % 512 * 512 * 50;
            //HeaderNode[] head = new HeaderNode[512 * 512 * 50];
            //HeaderList.GetData(head);
            //Debug.Log(head[p].start);
            //LinkedNode[] dan = new LinkedNode[512 * 512 * 50];
            //LinkedList.GetData(dan);
            //Debug.Log(dan[p].next);
        }
        ComputeBuffer.CopyCount(LinkedList, counterBuffer, 0);
        int[] counterArray = new int[1];
        counterBuffer.GetData(counterArray);
        Debug.Log(counterArray[0]);
    }

    private void OnDestroy()
    {
        LinkedList.Dispose();
        HeaderList.Dispose();
        DoublyLinkedList.Dispose();
        NeighborsList.Dispose();
        counterBuffer.Dispose();
    }

    bool SetupDirectionalLightShadowCamera(Bounds receiverBounds, Light light, int shadowSizeX, int shadowSizeY, Bounds casterBounds, Camera cam, out Matrix4x4 lightMatrix, out Matrix4x4 projMatrix)
    {
        lightMatrix = Matrix4x4.identity;
        projMatrix = Matrix4x4.Ortho(-1.0f, 1.0f, -1.0f, 1.0f, 0.1f, 10.0f);
        if (!casterBounds.IsValid())
        {
            return false;
        }
        Matrix4x4 frustumTransform = cam.cullingMatrix.inverse;
        Matrix4x4 localFrustumTransform = Matrix4x4.identity;
        float cameraFarZ = cam.farClipPlane;
        float shadowFarZ = 100;
        float farPlaneScale = 1.0f;
        if (false)
        {
            Matrix4x4 cameraProjection = cam.projectionMatrix;
            localFrustumTransform = cameraProjection.inverse;
            Vector4 cornerPos = localFrustumTransform * Vector4.one;
            if (Mathf.Abs(cornerPos.w) > 1.0e-7f)
            {
                float invW = 1.0f / cornerPos.w;
                cornerPos *= invW;
                frustumTransform = localFrustumTransform;
                float c = cornerPos.magnitude / cameraFarZ;
                float p = 0.4f;
                float r = 1.0f - p;
                farPlaneScale = (Mathf.Sqrt(-c * c * p * p + c * c * r * r + p * p) + p) / (c * c);
            }
        }
        float nearZ = cam.nearClipPlane;
        float scaledShadowRange = shadowFarZ * farPlaneScale - nearZ;
        float frustumScale = scaledShadowRange / (cameraFarZ - nearZ);
        if (frustumScale <= float.Epsilon)
        {
            return false;
        }
        Vector3[] cameraFrustum = cam.GetFrustumPoints();
        Vector3 center = casterBounds.center;
        float castersRadius = casterBounds.extents.magnitude * 2;
        Vector3 axisX = light.transform.right;
        Vector3 axisY = light.transform.up;
        Vector3 axisZ = light.transform.forward;
        Vector3 initialLightPos = center - axisZ * castersRadius * 1.2f;

        Bounds frustumBoundsLocal = BoundsUtil.DefaultBounds();
        for (int i = 0; i < 8; i++)
        {
            frustumBoundsLocal.Encapsulate(cameraFrustum[i]);
        }
        Vector3 frustumBoundsSizelocal = frustumBoundsLocal.extents * 2;
        Vector3 frustumBoundsCenterLocal = frustumBoundsLocal.center;
        float texelSizeX = frustumBoundsSizelocal.x / shadowSizeX;
        float texelSizeY = frustumBoundsSizelocal.y / shadowSizeY;
        lightMatrix = light.transform.worldToLocalMatrix;
        lightMatrix.SetColumn(3, new Vector4(0, 0, 0, 1));
        Vector4 lightPosWorld = lightMatrix.MultiplyPoint3x4(frustumBoundsCenterLocal);
        lightPosWorld -= (Vector4)(axisZ * frustumBoundsSizelocal.z * 1.2f);
        lightPosWorld.w = 1;
        lightMatrix = light.transform.worldToLocalMatrix;
        lightMatrix.SetColumn(3, lightPosWorld);
        Vector3 halfFrustumBoundsSizeLocal = frustumBoundsSizelocal * 0.5f;
        projMatrix = Matrix4x4.Ortho(-halfFrustumBoundsSizeLocal.x, halfFrustumBoundsSizeLocal.x, -halfFrustumBoundsSizeLocal.y, halfFrustumBoundsSizeLocal.y, halfFrustumBoundsSizeLocal.z * .1f, halfFrustumBoundsSizeLocal.z * 2.3f);
        return true;
    }

    void ExtractActiveCasterInfo(Camera cam, ref Bounds casterBounds, ref List<Bounds> casterAABBs)
    {
        Renderer[] renderers = FindObjectsOfType<Renderer>();
        Bounds excluded = new Bounds();
        excluded.SetMinMax(Vector3.positiveInfinity, Vector3.negativeInfinity);
        for (int i = 0, imax = renderers.Length; i < imax; i++)
        {
            Renderer rend = renderers[i];
            if (rend.shadowCastingMode != ShadowCastingMode.Off)
            {
                casterAABBs.Add(rend.bounds);
                if (IntersectAABBFrustumFull(rend.bounds, rend.localToWorldMatrix, cam.cullingMatrix))
                {
                    casterBounds.Encapsulate(rend.bounds);
                }
                else
                {
                    excluded.Encapsulate(rend.bounds);
                }
            }
        }
        if (!casterBounds.IsValid())
        {
            casterBounds.Encapsulate(excluded);
        }
    }

    bool IntersectAABBFrustumFull(Bounds bound, Matrix4x4 objectToWorld, Matrix4x4 w2p)
    {
        Plane[] planes = GeometryUtility.CalculateFrustumPlanes(w2p);
        Vector3 m = bound.center;
        Vector3 extent = bound.extents;
        for (int i = 0, imax = planes.Length; i < imax; i++)
        {
            Vector3 normal = planes[i].normal;
            float dist = planes[i].GetDistanceToPoint(m);
            float radius = Vector3.Dot(extent, new Vector3(Mathf.Abs(normal.x), Mathf.Abs(normal.y), Mathf.Abs(normal.z)));
            if (dist + radius < 0)
            {
                return false;
            }
        }
        return true;
    }


    bool PlaneTest(Bounds bound, Matrix4x4 objectToWorld, Plane plane)
    {
        Vector3 right = objectToWorld.GetColumn(0);
        Vector3 up = objectToWorld.GetColumn(1);
        Vector3 forward = objectToWorld.GetColumn(2);
        Vector3 position = objectToWorld.GetColumn(3);
        float r = Vector3.Dot(position, plane.normal);
        Vector3 absNormal = new Vector3(Mathf.Abs(Vector3.Dot(plane.normal, right)), Mathf.Abs(Vector3.Dot(plane.normal, up)), Mathf.Abs(Vector3.Dot(plane.normal, forward)));
        float f = Vector3.Dot(absNormal, bound.extents);
        return ((r - f) < -plane.distance);
    }
}
