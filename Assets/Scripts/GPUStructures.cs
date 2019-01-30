using System.Collections;
using System.Collections.Generic;
using UnityEngine;


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
    public int next;
    public Vector3 position;
    public float alpha;
    public static int StructSize()
    {
        return sizeof(float) * 4 + sizeof(int);
    }
};

public struct DoublyLinkedNode
{
    public float depth;
    public float shading;
    public int headOrTail;
    public static int StructSize()
    {
        return sizeof(float) * 2 + sizeof(int);
    }
};

public struct NeighborsNode
{
    public int neighbor;
    public static int StructSize()
    {
        return sizeof(int);
    }
};