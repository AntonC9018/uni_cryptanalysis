module stuff.diffs;

void main()
{
    import std.conv;
    import std.stdio;

    immutable ubyte[16] subtitutionTable = [
        0x8, 0x5, 0x7, 0xA, 
        0x2, 0xC, 0xF, 0x9, 
        0x3, 0x1, 0xE, 0x0, 
        0x4, 0xB, 0x6, 0xD];
    
    write("x,");
    void writeNext(int i) { write(to!string(i, 16), ","); }

    size_t maxRowIndex;
    size_t maxValue;
    size_t maxValueCount = 0;

    foreach (i; 0..16)
    {
        writeNext(i);
    }
    writeln();
    foreach (i; 0..16)
    {
        writeNext(i);
        size_t[16] counts = 0;
        foreach (j; 0..16)
        {
            ubyte num = subtitutionTable[i] ^ subtitutionTable[j]; 
            writeNext(num);
            counts[num]++;
        }

        import std.algorithm : maxIndex;
        size_t potentialMaxValue = counts[].maxIndex;
        if (counts[potentialMaxValue] > maxValueCount)
        {
            maxValue = potentialMaxValue;
            maxValueCount = counts[potentialMaxValue];
            maxRowIndex = i;
        }

        writeln();
    }

    write(
        "Max index is at row ", maxRowIndex, 
        "; the prevalent value was ", maxValue, 
        "; with count of ", maxValueCount,
        ". The % = ");
    writef("%2.2f", 100 * cast(float) maxValueCount / 16);
    writeln();
}