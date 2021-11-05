module common.combinatorics;
import std.stdio;


// https://www.wikiwand.com/en/Binomial_coefficient#/Pascal.27s_triangle
ulong nchoosek(ulong n, ulong k)
{
    if (k > n / 2)
        k = n - k;
    if (k > n)
        return nchoosek_internal(k, n);
    return nchoosek_internal(n, k);
}

private ulong[] pascalsTriangleCache;
private ulong nchoosek_internal(ulong n, ulong k)
{
    assert(k <= n);
    if (k == 0 || k == n)
        return 1;
    // It took me a while to figure out this formula.
    ulong index = (n / 2 - 1) * (n / 2) + (n / 2) * (n & (cast(ulong) 1)) + (k - 1);
    ulong targetLength = index + 1;
    if (pascalsTriangleCache.length >= targetLength)
    {
        if (pascalsTriangleCache[index] != 0)
            return pascalsTriangleCache[index];
    }
    else
    {
        pascalsTriangleCache.length = targetLength;
    }

    ulong result = nchoosek(n - 1, k) + nchoosek(n - 1, k - 1);
    pascalsTriangleCache[index] = result;
    return result;
}
unittest
{
    assert(nchoosek(0, 0) == 1);
    assert(nchoosek(1, 0) == 1);
    assert(nchoosek(1, 1) == 1);
    assert(nchoosek(0, 1) == 1);
    assert(nchoosek(2, 0) == 1);
    assert(nchoosek(2, 1) == 2);
    assert(nchoosek(2, 1) == 2);
    assert(nchoosek(2, 1) == 2);
    assert(nchoosek(2, 2) == 1);
    assert(nchoosek(3, 2) == 3);
    assert(nchoosek(4, 2) == 6);
    assert(nchoosek(4, 2) == 6);
    assert(nchoosek(8, 4) == 70);
    assert(nchoosek(50, 15) == 2250829575120);
    assert(nchoosek(50, 2) == 1225);
    assert(nchoosek(50, 3) == 19600);
    assert(nchoosek(50, 5) == 2118760);
    assert(nchoosek(50, 48) == 1225);
    assert(nchoosek(63, 40) == 93993414551124795);
    assert(nchoosek(64, 32) == 1832624140942590534);
}