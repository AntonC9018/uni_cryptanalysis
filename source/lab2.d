static import des;
import common.bitmagic;
import std.random;
import std.algorithm;
import std.range;
import std.stdio;

/// `IgnoreParity = false` means processes will not be started if the parity 
/// of the fixed key part is apriori wrong.
/// The default is `false`
version (IgnoreParity)
    enum IgnoreParity = true;
else
    enum IgnoreParity = false;
    // enum IgnoreParity = true;

/// The number of disclosed bits in the key.
/// To test things quickly, set to ~40
enum numKnownBits = 25;
/// 2^numAdditionalFixedBits is the maximum number of processes
/// that will be doing checks. When IgnoreParity is set to false, 
/// most likely, it will be halved, due to how I resolve parity. 
enum numAdditionalFixedBits = 3;

/// The 8 parity bits are always known.
enum numActuallyKnownBits = numKnownBits + 8;


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

    writefln("%16s -> %s", "Message", "DES(Message)");
    foreach (i; 0..messages.length)
        writefln("%016X -> %016X", messages[i], cryptedMessages[i]);
    writefln("Key = %016X", key);

    const keyKnownBitsMask = getRandomMaskWithNSetBits(numKnownBits, des.parityBitsMask, 8) | des.parityBitsMask;
    // ulong keyKnownBitsMask = ulong.max >> (64 - numKnownBits);
    const knownKeyPart = key & keyKnownBitsMask;
    // erase the key, so it's fair
    key = 0;

    static shared size_t numKeysCheckedSoFar = 0;
    /// We have just one global cancellation token here, 
    /// because it's a one-off app and I don't really care
    /// Another way of doing it is to pass a pointer to a heap allocated value I guess?
    /// Or something like that idk. This works though.
    static shared bool isCancelled = false;

    /// `keyFixedMask` includes the known key part + the fixed bits
    /// `keyFixedPart` is the known key part + the fixed bits set to 0 or 1
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

            const currentKey = keyFixedPart | (unknownBitsAllSet & currentMask);
            currentMask = (currentMask | keyFixedMask) + 1;

            atomicOp!"+="(numKeysCheckedSoFar, 1);
            
            static if (!IgnoreParity)
            {
                // The restriction is that we always know the parity bits, so we just check that.
                // Now, this can be a lot more 
                if (des.getKeyParity(currentKey) != (currentKey & des.parityBitsMask))
                    continue;
            }

            foreach (i; 0..messages.length)
            {
                if (des.crypt(messages[i], currentKey, encrypt) != cryptedMessages[i])
                {
                    continue outer;
                }
            }

            return currentKey;
        }

        // This process did not find the key
        // 0 is an invalid key anyway.
        return 0;
    }

    /// Create 2^N tasks, to compute things in parallel.
    /// Every task starts with N unkown bits of the fixed key already preset
    /// to a combination of zeros and ones.
    const size_t numTasks = 2^^numAdditionalFixedBits;
    const initialChangingFixedMaskPart = getMaskOfFirstNUnsetBits(keyKnownBitsMask, numAdditionalFixedBits);
    const changingBitsAllSet = initialChangingFixedMaskPart;
    const fixedMask = initialChangingFixedMaskPart | keyKnownBitsMask;
    ulong currentChangingFixedMaskPart = 0;

    assert(initialChangingFixedMaskPart != ~(cast(ulong) 0), "Play with the parameters a bit, there's nothing to guess");

    static if (!IgnoreParity)
    {
        // 1. compute which bytes are fully fixed
        const fullyFixedByteParityBitsMask = {
            ulong a = des.parityBitsMask;
            foreach (bitIndexInByte; 0..8)
                a &= fixedMask >> bitIndexInByte;
            return a;
        }();
    }

    // writefln("Known %016X", keyKnownBitsMask);
    // writefln("initialChangingFixedMaskPart %016X", initialChangingFixedMaskPart);
    // writefln("changingBitsAllSet %016X", changingBitsAllSet);
    // writefln("fixedMask %016X", fixedMask);
    // writefln("Known Part %016X", knownKeyPart);
    // writefln("fullyFixedByteParityBitsMask %016X", fullyFixedByteParityBitsMask);
    // writeln();


    import std.parallelism;
    import std.meta;
    alias taskArgs = AliasSeq!(search, ulong, ulong);
    Task!taskArgs*[] tasks;// = new Task!(search, ulong)[](numTasks);
    foreach (index; 0..numTasks)
    {
        const currentFixedPart = knownKeyPart | (changingBitsAllSet & currentChangingFixedMaskPart);
        // writefln("CurrentFixed part %016X", currentFixedPart);
        // writefln("currentChangingFixedMaskPart %016X", currentChangingFixedMaskPart);
        currentChangingFixedMaskPart = (currentChangingFixedMaskPart | ~initialChangingFixedMaskPart) + 1;

        static if (!IgnoreParity)
        {
            // If the fixed part is apriori wrong (checking parity), skip it.
            // 2. find out the correct parity
            const correctParity = des.getKeyParity(currentFixedPart);
            // 3. for those bytes that are fixed, check if the parity matches
            const correctParityOfFixedBytes = fullyFixedByteParityBitsMask & correctParity;
            const parityFlagsOfFixedBytes = fullyFixedByteParityBitsMask & currentFixedPart;

            // writefln("correctParity %016X", correctParity);
            // writefln("correctParityOfFixedBytes %016X", correctParityOfFixedBytes);
            // writefln("parityFlagsOfFixedBytes %016X", parityFlagsOfFixedBytes);

            // Skip this task, since its work will be in vain.
            if (parityFlagsOfFixedBytes != correctParityOfFixedBytes)
            {
                writeln("Skipping task number ", index, " (because of parity reasons).");
                continue;
            }
        }

/*
        Other ideas:

        1. Determine which bytes are fully known, or fully known due to parity initially,
           and adjust the initial known bits mask based on that. There is a practically
           substantial possibility of there being at least one fully known byte here.

        2. Each process needs to know about this thing separately, checking the parity 
           before evaluating DES (kind of done that, not in the most efficient way, 
           but it still speeds up things drastically).

        There is substantial benefit in checking the parity bits, each parity bit involved 
        halving the number of guesses.
*/      

        auto t = task!taskArgs(fixedMask, currentFixedPart);
        t.executeInNewThread();
        tasks ~= t;
        writeln("Started task ", index, ".");
    }
    // writeln(currentChangingFixedMaskPart);
    static if (IgnoreParity)
        assert(currentChangingFixedMaskPart == 0);

    // Iterate until one of the tasks finishes having found a valid key.
    ulong foundKey = 0;
    ulong totalNumKeys = (cast(ulong) 1) << (64 - numActuallyKnownBits);
    ulong previousPercentage = 0;
    // There being half the processes means half of the keys were already discarded due to parity reasons.
    // I think there cannot be any other number than a half or 0.
    if (tasks.length == numTasks / 2)
        totalNumKeys /= 2;

    outer: while (tasks.length > 0)
    {
        import core.thread;
        Thread.sleep(dur!"msecs"(100));
        foreach_reverse (index, task; tasks)
        {
            if (task.done)
            {
                foundKey = task.yieldForce();
                // If it found a valid key, we're done
                if (foundKey != 0)
                    break outer;
                // Otherwise remove the given task and keep waiting
                tasks.remove(index);
            }
        }

        ulong newPercentage = (numKeysCheckedSoFar * 100 / totalNumKeys);
        if (newPercentage - previousPercentage >= 5)
        {
            writeln(newPercentage, "% of keys checked.");
            previousPercentage = newPercentage;
        }
    }
    isCancelled = true;

    if (foundKey == 0)
        writeln("Could not find the key");
    else
        writefln("Found the key. It is %016X", foundKey);
}
