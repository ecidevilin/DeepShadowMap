﻿
struct FittingFunc
{
	float3 f[4];
};

#define NUM_BUF_ELEMENTS 32
#define FILTER_SIZE 2

uint Dimension;

static const uint FittingBins[4] = { NUM_BUF_ELEMENTS / 8,NUM_BUF_ELEMENTS / 8,NUM_BUF_ELEMENTS / 4,NUM_BUF_ELEMENTS / 2 };
static const uint FittingBinsAcc[4] = { 0,NUM_BUF_ELEMENTS / 8,NUM_BUF_ELEMENTS / 4,NUM_BUF_ELEMENTS / 2 };