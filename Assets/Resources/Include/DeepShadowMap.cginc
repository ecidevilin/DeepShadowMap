struct HeaderNode
{
	int start;
};

struct LinkedNode
{
    int next;
	uint index;
    float depth;
    //float alpha;
};

struct DoublyLinkedNode 
{
	float depth;
	//float shading;
	int headOrTail; // head:1 tail:-1 other:0
};

struct FittingFunc
{
	float3 f[4];
};

#define NUM_BUF_ELEMENTS 64
#define FILTER_SIZE 2

uint Dimension;

static const uint FittingBins[4] = { NUM_BUF_ELEMENTS / 8,NUM_BUF_ELEMENTS / 8,NUM_BUF_ELEMENTS / 4,NUM_BUF_ELEMENTS / 2 };