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
};

struct NeighborsNode
{
	int right;
	int top;
};
#define NUM_BUF_ELEMENTS 16
#define FILTER_SIZE 1

uint Dimension;