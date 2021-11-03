static import des;
import common.combinatorics;
import std.random;
import std.algorithm;
import std.range;
import std.stdio;

void main()
{
    static ulong[3] messages;
    foreach (index, ref m; messages)
        m = uniform!ulong;

    ulong key = des.adjustKeyParity(uniform!ulong);
    static Flag!"encrypt" encrypt = Yes.encrypt; // No.encrypt;

    static typeof(messages) cryptedMessages;
    foreach (index, ref em; cryptedMessages)
        em = des.crypt(messages[index], key, encrypt);

    foreach (i; 0..messages.length)
        writefln("%016X -> %016X", messages[i], cryptedMessages[i]);
    writefln("%016X", key);

    enum numKnownBits = 50;
    ulong keyKnownBitsMask = getRandomMaskWithNSetBits(numKnownBits);
    // ulong keyKnownBitsMask = ulong.max >> (64 - numKnownBits);
    ulong knownKeyPart = key & keyKnownBitsMask;
    // erase the key, so it's fair
    key = 0;
    
    static shared size_t counter = 0;
    // `keyFixedMask` includes the known key part + the fixed bits
    // `keyFixedPart` is the known key part + the fixed bits set to 0 or 1
    static ulong search(ulong keyFixedMask, ulong keyFixedPart)
    {
        import core.atomic;
        // The mask which will be incremented until it reaches 0.
        ulong currentMask = keyFixedMask;
        ulong unknownBitsAllSet = ~keyFixedMask;

        outer: while (currentMask != 0)
        {
            ulong currentKey = keyFixedPart | (unknownBitsAllSet & currentMask);
            currentMask = (currentMask | keyFixedMask) + 1;
            
            ulong counterValue = atomicOp!"+"(counter, 1);
            if (counterValue % 10000 == 0 && counterValue > 0)
                writeln(counterValue, " keys checked out of ", (cast(ulong) 1) << (64 - numKnownBits));

            foreach (i; 0..messages.length)
            {
                if (des.crypt(messages[i], currentKey, encrypt) != cryptedMessages[i])
                    continue outer;
            }
            return currentKey;
        }

        // This process did not find the key
        // 0 is an invalid key anyway.
        return 0;
    }

    // Create 2^N tasks, to compute things in parallel.
    // Every task starts with N unkown bits of the fixed key already preset
    // to a combination of zeros and ones.
    size_t numAdditionalFixedBits = 3;
    size_t numTasks = 2^^numAdditionalFixedBits;
    ulong initialChangingFixedMaskPart = getMaskOfFirstNUnsetBits(keyKnownBitsMask, numAdditionalFixedBits);
    ulong changingBitsAllSet = initialChangingFixedMaskPart;
    ulong currentChangingFixedMaskPart = 0;
    ulong fixedMask = initialChangingFixedMaskPart | keyKnownBitsMask;

    import std.parallelism;
    auto tasks = new Task!(search, ulong, ulong)[](numTasks);
    foreach (index, ref task; tasks)
    {
        ulong currentFixedPart = knownKeyPart | (changingBitsAllSet & currentChangingFixedMaskPart);
        task = scopedTask!search(fixedMask, currentFixedPart);
        task.executeInNewThread();
        writeln("Started task ", index);

        currentChangingFixedMaskPart = (currentChangingFixedMaskPart | ~initialChangingFixedMaskPart) + 1;
    }
    writeln(currentChangingFixedMaskPart);
    assert(currentChangingFixedMaskPart == 0);

    ulong foundKey;
    foreach (ref task; tasks)
    {
        foundKey = task.yieldForce();
        if (foundKey != 0)
            break;
    }

    if (foundKey == 0)
        writeln("Could not find the key");
    else
        writefln("Found the key. It is %016X", foundKey);
}

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