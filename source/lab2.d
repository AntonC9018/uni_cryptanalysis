static import des;
import std.random;
import std.algorithm;
import std.range;
import std.stdio;

void main()
{
    ulong[3] messages;
    foreach (ref m; messages)
        m = uniform!ulong;
    ulong key = des.adjustKeyParity(uniform!ulong);
    
    // Flag!"encrypt" encrypt = Yes.encrypt; // No.encrypt;
    // ulong[3] encryptedMessages = messages[].map(m => des.crypt(m, key, encrypt)).staticArray;

    writefln("0x%x", key);
}