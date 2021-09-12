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

immutable double[] englishLettersDistribution = _getDistr();

private auto _getDistr()
{
    auto dict = [ 
        'E': 	0.1202,
        'T': 	0.0910,
        'A': 	0.0812,
        'O': 	0.0768,
        'I': 	0.0731,
        'N': 	0.0695,
        'S': 	0.0628,
        'R': 	0.0602,
        'H': 	0.0592,
        'D': 	0.0432,
        'L': 	0.0398,
        'U': 	0.0288,
        'C': 	0.0271,
        'M': 	0.0261,
        'F': 	0.0230,
        'Y': 	0.0211,
        'W': 	0.0209,
        'G': 	0.0203,
        'P': 	0.0182,
        'B': 	0.0149,
        'V': 	0.0111,
        'K': 	0.0069,
        'X': 	0.0017,
        'Q': 	0.0011,
        'J': 	0.0010,
        'Z': 	0.0007
    ];

    double[letterCount] result;
    foreach (i, it; dict)
    {
        result[i - 'A'] = it;
    }
    return result.dup;
}
enum letterCount = 'Z' - 'A' + 1;

auto getLikelyShifts(string str, size_t keyLength, size_t letterIndex)
{
    double[letterCount] deviations;

    foreach (shift; 0..letterCount)
    {
        int[letterCount] counts;

        foreach (ch; str[letterIndex..$].stride(keyLength))
        {
            auto shifted = (ch - 'A' + shift) % letterCount;
            counts[shifted] += 1;
        }
        
        double deviation = 0;

        foreach (index, count; counts)
        {
            deviation += (cast(double) count / str.length - englishLettersDistribution[index]) ^^ 2;
        }

        deviations[shift] = deviation;
    }

    return iota(letterCount).array.sort!((a, b) => deviations[a] < deviations[b]);
}

void main()
{
    string s = `LIOMWGFEGGDVWGHHCQUCRHRWAGWIOWQLKGZETKKMEVLWPCZVGTHVTSGXQOVGCSVETQLTJSUMVWVEUVLXEWSLGFZMVVWLGYHCUSWXQHKVGSHEEVFLCFDGVSUMPHKIRZDMPHHBVWVWJWIXGFWLTSHGJOUEEHHVUCFVGOWICQLTJSUXGLW`;

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
    
    // The window is probably larger than 3
    foreach (keyLength; sorted
        .filter!"a.index > 3 && a.value > 0"
        .map!"a.index".take(2))
    {
        enum numberOfTries = 4;
        auto storedCombos = iota(keyLength).map!(
            i => getLikelyShifts(s, keyLength, i).take(numberOfTries).array).array;
        
        // Now print all combinations
        writeln("Trying key length of ", keyLength);

        auto keys = new int[](keyLength);
        size_t currentIndex = 0;

        while (currentIndex < keyLength - 1)
        {
            write("Trying shifts ");

            foreach (i, shiftIndex; keys)
            {
                auto inverseShift = letterCount - storedCombos[i][shiftIndex];
                write(inverseShift, "(", cast(char)(inverseShift + 'A'), ") ");
            } 
            writeln();

            foreach (i, ch; s)
            {
                auto index = i % keyLength;
                auto shift = storedCombos[index][keys[index]];
                write(cast(char)((ch - 'A' + shift) % letterCount + 'A'));
            } 
            writeln();
            writeln();
            
            foreach (j, ref it; keys)
            {
                if (it < numberOfTries - 1)
                {
                    it++;
                    currentIndex = j;
                    break;
                }
                it = 0;
            }
        }
    }
}
