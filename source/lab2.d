static import des;
import common.combinatorics;
import std.random;
import std.algorithm;
import std.range;
import std.stdio;

void main()
{
    static shared ulong[3] messages;
    foreach (index, ref m; messages)
        m = uniform!ulong;

    ulong key = des.adjustKeyParity(uniform!ulong);
    static Flag!"encrypt" encrypt = Yes.encrypt; // No.encrypt;

    static shared typeof(messages) cryptedMessages;
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

    enum IgnoreParity = false;
    static if (IgnoreParity)
    {
        // Since the parity bits don't matter, might as well at least just ignore them
        // See the loop below for more potential optimization ideas.
        keyKnownBitsMask |= des.parityBitsMask;
    }

    static shared size_t numKeysCheckedSoFar = 0;
    // We have just one global cancellation token here, 
    // because it's a one-off app and I don't really care
    // Another way of doing it is to pass a pointer to a heap allocated value I guess?
    // Or something like that idk. This works though.
    static shared bool isCancelled = false;

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
            if (isCancelled)
                return 0;

            ulong currentKey = keyFixedPart | (unknownBitsAllSet & currentMask);
            currentMask = (currentMask | keyFixedMask) + 1;

            foreach (i; 0..messages.length)
            {
                if (des.crypt(messages[i], currentKey, encrypt) != cryptedMessages[i])
                {
                    size_t counterValue = atomicOp!"+="(numKeysCheckedSoFar, 1);
                    if (counterValue % 100000 == 0)
                        // (most likely less due to the parity flags)
                        writeln(counterValue, " keys checked out of ", (cast(ulong) 1) << (64 - numKnownBits + 1));
                    continue outer;
                }
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
    writefln("Known %016X", keyKnownBitsMask);
    writefln("InitialChaning %016X", initialChangingFixedMaskPart);
    writefln("Fixed %016X", fixedMask);
    writefln("Known Part %016X", knownKeyPart);
    writeln();

    import std.parallelism;
    Task!(search, ulong, ulong)[] tasks;// = new Task!(search, ulong, ulong)[](numTasks);
    foreach (index; 0..numTasks)
    {
        const currentFixedPart = knownKeyPart | (changingBitsAllSet & currentChangingFixedMaskPart);
        writefln("CurrentFixed part %016X", currentFixedPart);

        static if (!IgnoreParity)
        {
            // If the fixed part is apriori wrong (checking parity), skip it
            // 1. find out the correct parity
            ulong currentParity = currentFixedPart & des.parityBitsMask;
            ulong correctParity = des.getKeyParity(currentFixedPart);
            // 2. compute which bytes are fully fixed
            ulong fullyFixedBytes = des.parityBitsMask;
            foreach (bitIndexInByte; 0..8)
                fullyFixedBytes &= fixedMask << bitIndexInByte;
            // 3. for those bytes that are fixed, check if the parity matches
            ulong parityFlagsOfFixedBytes = fullyFixedBytes & currentParity;
            ulong correctParityOfFixedBytes = fullyFixedBytes & correctParity;
            // Skip this task, since its work will be in vain.
            if (parityFlagsOfFixedBytes != correctParityOfFixedBytes)
            {
                writefln("correctParity %016X", correctParity);
                writefln("fixedMask %016X", fixedMask);
                writefln("fullyFixedBytes %016X", fullyFixedBytes);
                writefln("parityFlagsOfFixedBytes %016X", parityFlagsOfFixedBytes);
                writefln("correctParityOfFixedBytes %016X", correctParityOfFixedBytes);
                writeln("Skipping task number ", index);
                writeln();
                continue;
            }
        }

/*
        Other ideas:

        1. Determine which bytes are fully known, or fully known due to parity initially,
           and adjust the initial known bits mask based on that. There is a practically
           substantial possibility of there being at least one fully known byte here.

        2. Each process needs to know about this thing separately, checking the parity 
           before evaluating DES.

        There is substantial benefit in checking the parity bits, each parity bit involved 
        halving the number of guesses.
*/      

        auto task = scopedTask!search(fixedMask, cast(ulong) currentFixedPart);
        tasks ~= task;
        task.executeInNewThread();
        writeln("Started task ", index);

        currentChangingFixedMaskPart = (currentChangingFixedMaskPart | ~initialChangingFixedMaskPart) + 1;
    }
    // writeln(currentChangingFixedMaskPart);
    // assert(currentChangingFixedMaskPart == 0);

    // Iterate until one of the tasks finishes having found a valid key.
    ulong foundKey = 0;
    outer: while (tasks.length > 0)
    {
        import core.thread;
        Thread.sleep(dur!"msecs"(100));
        foreach (index, ref task; tasks)
        {
            if (task.done)
            {
                foundKey = task.yieldForce();
                // If it found a valid key, we're done
                if (foundKey != 0)
                    break outer;
                // Otherwise remove the given task and keep waiting
                tasks.remove(index);
                continue outer;
            }
        }
    }
    isCancelled = true;

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