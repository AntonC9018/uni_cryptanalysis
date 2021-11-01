static import des;
import common.combinatorics;
import std.random;
import std.algorithm;
import std.range;
import std.stdio;

void main()
{
    ulong[3] messages;
    foreach (index, ref m; messages)
        m = uniform!ulong;

    ulong key = des.adjustKeyParity(uniform!ulong);
    Flag!"encrypt" encrypt = Yes.encrypt; // No.encrypt;

    typeof(messages) cryptedMessages;
    foreach (index, ref em; cryptedMessages)
        em = des.crypt(messages[index], key, encrypt);

    foreach (i; 0..messages.length)
        writefln("%016X -> %016X", messages[i], cryptedMessages[i]);
    writefln("%016X", key);

    enum numKnownBits = 50;
    // ulong keyKnownBitsMask = getRandomMaskWithNSetBits(numKnownBits);
    ulong keyKnownBitsMask = ulong.max >> (64 - numKnownBits);
    ulong knownKeyPart = key & keyKnownBitsMask;
    // erase the key, so it's fair
    key = 0;
    ulong currentMask = keyKnownBitsMask + 1;
    ulong unknownBitsAllSet = ~keyKnownBitsMask;
    ulong currentKey;

    outer: while (currentMask != 0)
    {
        currentKey = knownKeyPart | (unknownBitsAllSet & currentMask);
        currentMask |= keyKnownBitsMask;
        foreach (i; 0..messages.length)
        {
            if (des.crypt(messages[i], currentKey, encrypt) != cryptedMessages[i])
            {
                currentMask += 1;
                continue outer;
            }
        }
        break;
    }

    if (currentMask == 0)
        writeln("Could not find the key");
    else
        writefln("Found the key. It is %016X", currentKey);
}