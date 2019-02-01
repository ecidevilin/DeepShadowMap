struct HeaderNode
{
	int start;
};

struct LinkedNode
{
    int next;
    float3 position;
    float alpha;
};

struct DoublyLinkedNode 
{
	float depth;
	float shading;
	int headOrTail; // head:1 tail:-1 other:0
};

struct NeighborsNode
{
	int neighbor;
};
#define NUM_BUF_ELEMENTS 16
#define FILTER_SIZE 0

uint Dimension;