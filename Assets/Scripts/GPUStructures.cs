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
    //public float alpha;
    public static int StructSize()
    {
        return sizeof(float) * 1 + sizeof(int) * 2;
    }
};

public struct DoublyLinkedNode
{
    public float depth;
    //public float shading;
    public int headOrTail;
    public static int StructSize()
    {
        return sizeof(float) + sizeof(int);
    }
};