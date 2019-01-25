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
    public static int StructSize()
    {
        return sizeof(float) * 2;
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