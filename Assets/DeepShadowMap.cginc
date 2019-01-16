struct HeaderNode
{
	int start;
};

struct LinkedNode
{
    float depth;
    float alpha;
    int next;
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
#define NUM_BUF_ELEMENTS 50
#define FILTER_SIZE 2
#define ZFAR 1000.0f

uint Dimension;