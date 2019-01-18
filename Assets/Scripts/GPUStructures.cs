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