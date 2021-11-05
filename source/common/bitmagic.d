module common.bitmagic;

import std.stdio;

ulong getMaskOfFirstNUnsetBits(ulong mask, ulong numBits)
{
    ulong result = 0;

    for (size_t bitIndex = 0; numBits > 0; bitIndex++) 
    {
        // All bits were set, could not add more.
        if (bitIndex == 64)
            return result;

        ulong currentBit = (mask >> bitIndex) & 1;
        if (currentBit == 0)
        {
            result |= (cast(ulong) 1) << bitIndex;
            numBits--;
        }
    }

    return result;
}
unittest
{
    assert(getMaskOfFirstNUnsetBits(0, 64) == ~(cast(ulong) 0));
    assert(getMaskOfFirstNUnsetBits(0xffffffff_ffffff00, 8) == 0x00000000_000000ff);
    assert(getMaskOfFirstNUnsetBits(0x00ffffff_ffffffff, 4) == 0x0f000000_00000000);
}

/// This implementation is 4 times faster than the one below.
/// With unrolled loops (static foreach) it's 1.5 times more fast than this.
ulong countBits(ulong number)
{
    ulong count = 0;
    foreach (bitIndex; 0..8)
        count += (number >> bitIndex) & 0x01010101_01010101;
    ulong actualCount = 0;
    foreach (byte b; cast(byte[8]) (&count)[0..1])
        actualCount += b;
    return actualCount;
}
unittest
{
    assert(countBits(0xffffffff_ffffffff) == 64);
}

// ulong countBits(ulong number)
// {
//     ulong count = 0;
//     foreach (bitIndex; 0..64)
//         count += (number >> bitIndex) & 1;
//     return count;
// }

import std.random;
import common.combinatorics;

ulong getRandomMaskWithNSetBits(ulong numOnes)
in (numOnes <= 64)
{
    if (numOnes > 32)
        return ~getRandomMaskWithNSetBits(64 - numOnes);
    return getRandomMaskWithNSetBits_decode(numOnes, uniform!("[)", ulong)(0, nchoosek(64, numOnes)));
}

ulong getRandomMaskWithNSetBits(ulong numMoreOnes, ulong skippedBitsMask)
{
    return getRandomMaskWithNSetBits(numMoreOnes, skippedBitsMask, countBits(skippedBitsMask));
}

ulong getRandomMaskWithNSetBits(ulong numMoreOnes, ulong skippedBitsMask, ulong skippedBitsCount)
in (numMoreOnes <= 64 - skippedBitsCount)
{
    assert(countBits(skippedBitsMask) == skippedBitsCount);
    if (numMoreOnes > 32)
        return ~getRandomMaskWithNSetBits(64 - numMoreOnes - skippedBitsCount, skippedBitsMask, skippedBitsCount) 
            & ~skippedBitsMask;
    return getRandomMaskWithNSetBits_decode(
        numMoreOnes, uniform!("[)", ulong)(0, nchoosek(64 - skippedBitsCount, numMoreOnes)), 
        skippedBitsMask, skippedBitsCount);
}

// https://cs.stackexchange.com/a/67669
ulong getRandomMaskWithNSetBits_decode(ulong numOnes, ulong ordinal)
in (numOnes <= 64)
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
    assert(countBits(randomNumber) == numOnes);
}

ulong getRandomMaskWithNSetBits_decode(ulong numMoreOnes, ulong ordinal, ulong skippedBitsMask, ulong numAlreadySetBits)
in (numMoreOnes <= 64 - numAlreadySetBits)
{
    assert(countBits(skippedBitsMask) == numAlreadySetBits);
    ulong bits = 0;
    ulong bitIndex = 63;

    for (ulong bitCounter = 64 - numAlreadySetBits - 1; numMoreOnes > 0; bitCounter--, bitIndex--)
    {
        while ((skippedBitsMask >> bitIndex) & 1)
            bitIndex--;

        ulong nCk = nchoosek(bitCounter, numMoreOnes) - 1;
        if (ordinal >= nCk)
        {
            ordinal -= nCk;
            bits |= (cast(ulong) 1) << bitIndex;
            numMoreOnes--;
        }
    }
    return bits;
}
unittest
{
    enum numOnes = 20;
    ulong mask = 0xffffff00_00000000;
    ulong maskBitCount = countBits(mask);
    ulong randomNumber = getRandomMaskWithNSetBits(numOnes, mask, maskBitCount);
    assert(countBits(randomNumber) == numOnes);
    assert(countBits(randomNumber | mask) == numOnes + maskBitCount);
}
unittest
{
    enum numOnes = 40;
    ulong mask = 0xff000000_00000000;
    ulong maskBitCount = countBits(mask);
    ulong randomNumber = getRandomMaskWithNSetBits(numOnes, mask, maskBitCount);
    assert(countBits(randomNumber) == numOnes);
    assert(countBits(randomNumber | mask) == numOnes + maskBitCount);
}