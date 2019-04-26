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
    public int index;
    public float depth;
    public static int StructSize()
    {
        return sizeof(float) + sizeof(int) * 2;
    }
};