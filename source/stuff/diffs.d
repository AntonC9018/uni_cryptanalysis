// The program outputs a csv file for a given sustitution table (specified in main).
// So run it with `diffs >> filename.csv`.
module stuff.diffs;

import std.conv;
import std.stdio;
import std.algorithm;

void main()
{
    immutable ubyte[16] subtitutionTable = [
        0x8, 0x5, 0x7, 0xA, 
        0x2, 0xC, 0xF, 0x9, 
        0x3, 0x1, 0xE, 0x0, 
        0x4, 0xB, 0x6, 0xD];
    
    diffs(subtitutionTable);
}

private void writeNext(int i) { writef("%1X,", i); }

void diffs(in ubyte[16] subtitutionTable)
{
    size_t[16] getCounts(int constant)
    {
        size_t[16] counts = 0;
        foreach (message; 0..16)
        {
            ubyte a = subtitutionTable[message] ^ subtitutionTable[message ^ constant]; 
            counts[a]++;
        }
        return counts;
    }

    void writeTable(int constant)
    {
        write("m0,");
        write("m1=m0+");
        writeNext(constant);
        write("S[m0],");
        write("S[m1],");
        write("S[m0]+S[m1],");
        write("Hex value,Hex count");
        writeln();

        size_t[16] counts = getCounts(constant);

        foreach (message; 0..16)
        {
            writeNext(message); // m0
            writeNext(message ^ constant); // m1=m0+constant
            writeNext(subtitutionTable[message]); // S[m0]
            writeNext(subtitutionTable[message ^ constant]); // S[m1]
            writeNext(subtitutionTable[message] ^ subtitutionTable[message ^ constant]);
            writeNext(message); // iterator
            writeNext(counts[message]); // counts
            writeln();
        }
    }

    size_t maxCountConstant = 0;
    size_t maxCount = 0;
    foreach (constant; 1..16)
    {
        size_t[16] counts = getCounts(constant);
        size_t potentialMaxIndex = counts[].maxIndex;
        if (counts[potentialMaxIndex] > maxCount)
        {
            maxCountConstant = constant;
            maxCount = counts[potentialMaxIndex];
        }
    }

    writeTable(maxCountConstant);
    writeln();
}