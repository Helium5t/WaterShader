

#ifndef RAND_SEED
#define RAND_SEED 2147483647
#endif


static int state = RAND_SEED;

int generate(int s){
    int x = state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    state = x;
    return x;
}

float generate_01(int s ){
    int x = generate(s);
    return x / 4294967296.0;
}