module stuff.kasiski;

import std.algorithm;
import std.range;
import std.ascii;
import std.stdio;

auto findRepeatingPatters(string message)
{
    int[][string] repeatCountsForNGrams;
    
    foreach (windowSize; [4, 3])
    foreach (startingIndex; 0..message.length - windowSize)
    {
        auto withoutStart = message[startingIndex..$];
        auto windowNGram = withoutStart[0..windowSize];

        if (windowNGram in repeatCountsForNGrams)
        {
            continue;
        }
        
        int[] positions;

        foreach (position, window; withoutStart[windowSize..$].slide(windowSize).enumerate(windowSize))
        {
            // window is a lazy range
            if (equal(window, windowNGram))
            {
                positions ~= position;
            }
        }

        repeatCountsForNGrams[windowNGram] = positions;
    }

    auto sortedAssocArray = repeatCountsForNGrams.byKeyValue
        .filter!`a.value.length > 0`
        .array
        .sort!((a, b) => a.value.length > b.value.length);

    return sortedAssocArray;
}

void main()
{
    string s = `KTPCZNOOGHVFBTZVSBIOVTAGMKRLVAKMXAVUSTTPCNLCDVHXEOCPECPPHXHLNLFCKNYBPSQVXYPVHAKTAOLUHTITPDCSBPAJEAQZRIMCSYIMJHRABPPPHBUSKVXTAJAMHLNLCWZVSAQYVOYDLKNZLHWNWKJGTAGKQCMQYUWXTLRUSBSGDUAAJEYCJVTACAKTPCZPTJWPVECCBPDBELKFBVIGCTOLLANPKKCXVOGYVQBNDMTLCTBVPHIMFPFNMDLEOFGQCUGFPEETPKYEGVHYARVOGYVQBNDWKZEHTTNGHBOIWTMJPUJNUADEZKUUHHTAQFCCBPDBELCLEVOGTBOLEOGHBUEWVOGM`;

    int[25] divisors; 
    auto things = findRepeatingPatters(s).map!`a.value`.joiner;
    foreach (it; things)
    foreach (i; 0..divisors.length)
    {
        if ((it % (i + 2)) == 0)
        {
            divisors[i] += 1;
        }
    }

    auto sorted = divisors[].enumerate(2).array.sort!"a[1] > b[1]";

    foreach (i, it; sorted[0..5])
    {
        writeln(i, ": ", it);
    }
}
