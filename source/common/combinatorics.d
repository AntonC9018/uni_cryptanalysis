module common.combinatorics;
import std.stdio;

ulong getRandomMaskWithNSetBits(ulong numOnes)
{
    import std.random;
    if (numOnes > 32)
        return ~getRandomMaskWithNSetBits(64 - numOnes);
    return getRandomMaskWithNSetBits_decode(numOnes, uniform!("[)", ulong)(0, nchoosek(64, numOnes)));
}

// https://cs.stackexchange.com/a/67669
ulong getRandomMaskWithNSetBits_decode(ulong numOnes, ulong ordinal)
{
    ulong bits = 0;
    for (ulong bitIndex = 63; numOnes > 0; bitIndex--)
    {
        ulong nCk = nchoosek(bitIndex, numOnes) - 1;
        // writefln("ordinal: %x  nck(%d, %d): %x", ordinal, bitIndex, numOnes, nCk);
        if (ordinal >= nCk)
        {
            ordinal -= nCk;
            bits |= (cast(ulong) 1) << bitIndex;
            numOnes--;
        }
    }
    return bits;
}
unittest
{
    enum numOnes = 20;
    size_t randomNumber = getRandomMaskWithNSetBits(numOnes);
    // writefln("%x", randomNumber);

    size_t numSetBits = 0;
    foreach (bitIndex; 0..64)
        numSetBits += (randomNumber >> bitIndex) & 1;
    assert(numSetBits == numOnes);
}


// https://www.wikiwand.com/en/Binomial_coefficient#/Pascal.27s_triangle
ulong nchoosek(ulong n, ulong k)
{
    if (k > n)
        return nchoosek_internal(k, n);
    return nchoosek_internal(n, k);
}

private ulong[] cache = [1];
private ulong nchoosek_internal(ulong n, ulong k)
{
    assert(k <= n);
    if (k == 0 || k == n)
        return 1;

    ulong index = (n + 1) * n / 2 + k - 1 - 2 * (n - 1);
    ulong targetLength = index + 1;
    if (cache.length >= targetLength)
    {
        if (cache[index] != 0)
            return cache[index];
    }
    else
    {
        cache.length = targetLength;
    }

    ulong result = nchoosek_internal(n - 1, k) + nchoosek_internal(n - 1, k - 1);
    cache[index] = result;
    return result;
}
unittest
{
    assert(nchoosek(0, 0) == 1);
    assert(nchoosek(1, 0) == 1);
    assert(nchoosek(1, 1) == 1);
    assert(nchoosek(0, 1) == 1);
    assert(nchoosek(2, 0) == 1);
    assert(nchoosek(2, 1) == 2);
    assert(nchoosek(2, 1) == 2);
    assert(nchoosek(2, 1) == 2);
    assert(nchoosek(2, 2) == 1);
    assert(nchoosek(3, 2) == 3);
    assert(nchoosek(4, 2) == 6);
    assert(nchoosek(4, 2) == 6);
    assert(nchoosek(8, 4) == 70);
    assert(nchoosek(50, 15) == 2250829575120);
    assert(nchoosek(50, 2) == 1225);
    assert(nchoosek(50, 3) == 19600);
    assert(nchoosek(50, 5) == 2118760);
    assert(nchoosek(50, 48) == 1225);
    assert(nchoosek(63, 40) == 93993414551124795);
    assert(nchoosek(64, 32) == 1832624140942590534);
}