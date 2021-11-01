static import des;
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
    writefln("%X16", key);


    // ulong keyKnownExtent = 

}