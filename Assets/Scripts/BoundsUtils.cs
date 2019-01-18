using UnityEngine;

public static class BoundsUtils
{

    public static bool IntersectFrustum(Bounds bound, Matrix4x4 objectToWorld, Matrix4x4 w2p)
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


    public static bool IntersectPlane(Bounds bound, Matrix4x4 objectToWorld, Plane plane)
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
