module common.combinatorics;

// https://cs.stackexchange.com/a/67669
ulong decode(ulong ones, ulong ordinal)
{
    ulong bits = 0;
    for (ulong bit = 63; ones > 0; --bit)
    {
        ulong nCk = nchoosek(bit, ones);
        if (ordinal >= nCk)
        {
            ordinal -= nCk;
            bits |= 1 << bit;
            --ones;
        }
    }
    return bits;
}


// https://www.wikiwand.com/en/Binomial_coefficient#/Pascal.27s_triangle
ulong nchoosek(ulong n, ulong k)
{
    if (k > n)
        return nchoosek_internal(k, n);
    return nchoosek_internal(n, k);
}

private ulong[] cache = [1];
private ulong nchoosek_internal(ulong n, ulong k)
{
    assert(k <= n);
    ulong index = (n + 1) * n / 2 + k;
    ulong targetLength = index + 1;
    if (cache.length >= targetLength)
    {
        if (cache[index] != 0)
            return cache[index];
    }
    else
    {
        cache.length = targetLength;
    }

    ulong result;
    if (k == 0 || k == n)
        result = 1;
    else
        result = nchoosek_internal(n - 1, k) + nchoosek_internal(n - 1, k - 1);
    
    cache[index] = result;
    
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
}