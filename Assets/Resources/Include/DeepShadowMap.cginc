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
	float shading;	// stores final shading
	int next;
	int prev;
};

struct NeighborsNode
{
	int right;
	int top;
};
#define NUM_BUF_ELEMENTS 16
#define FILTER_SIZE 2
#define ZFAR 1000.0f

uint Dimension;