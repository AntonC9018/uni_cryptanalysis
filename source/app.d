module app;

import imports;

enum char letterCount = 'Z' - 'A' + 1;

char[] _getAlphabet()
{
    import std.algorithm;

    char[] buffer = new char[](letterCount + 1);
    for (char i = 'A'; i <= 'Z'; i++)
        buffer[i - 'A'] = i;
    buffer[$-1] = 0;

    return buffer;
}
enum alphabet = _getAlphabet();

class Caesar : IApp
{
    char[512] str;
    char[512] result;
    int shift = 0;

    void setup()
    {
        str[] = 0;
        result[] = 0;
    }

    void update(double dt)
    {
        bool valueChanged = ImGui.InputTextMultiline("Encrypted Caesar", str.ptr, str.length);
        valueChanged |= ImGui.InputInt("Shift", &shift);
        while (shift < 0) 
            shift += letterCount; 
        shift %= letterCount;
        
        if (valueChanged)
        {
            size_t j = 0;
            for (size_t i = 0; i < str.length; i++)
            {
                if (str[i] == 0)
                    break;

                import std.ascii;
                if (str[i].isAlpha())
                {
                    char t = cast(char)(str[i].toUpper() - 'A' + shift) % letterCount + 'A';
                    result[j++] = t;
                }
                else
                    result[j++] = str[i];
            }
            result[j] = 0;
        }

        const rectDefault = ImVec2(0, 0);
        ImGui.InputTextMultiline("Decrypted Caesar", result.ptr, str.length, rectDefault.byRef, ImGuiInputTextFlags_ReadOnly);
        ImGui.Separator();
    }
}

void forceCapitalLetter(ref char ch)
{
    import std.ascii;
    ch = toUpper(ch);
    if (!isAlpha(ch)) 
        ch = 'A';
}

struct SingleCharString
{
    char ch;
    char zero = 0;
    this (char c) 
    { 
        ch = c;
    }
    auto ref ptr() 
    { 
        return &this.ch; 
    }
    void forceCapitalLetter()
    {
        .forceCapitalLetter(ch);
    }
}

struct CircularQueue(T, size_t size)
{
    T[size] arrayof;
    private int _currentIndex = -1;
    private size_t _count = 0;

    private int mapIndex(int index) 
    {
        return (index + _currentIndex - _count + 1) % size;
    }

    bool empty()
    {
        return _count == 0;
    }

    enum capacity = size;
    size_t length()
    {
        return cast(size_t) _count;
    }

    auto ref T front()
    in (!empty)
    {
        return arrayof[mapIndex(0)];
    }

    void popFront()
    in (!empty)
    {
        _currentIndex += size - 1;
        _currentIndex %= size;
        _count--;
    }

    void opOpAssign(string op, T)(T value) if (op == "~")
    {
        _currentIndex += 1;
        _currentIndex %= size;
        arrayof[_currentIndex] = value;
        if (_count != size)
            _count++;
    }

    auto opSlice()
    {
        import std.algorithm;
        if (_count < _currentIndex)
        {
            return arrayof[_currentIndex - _count.._currentIndex].chain(arrayof[0..0]);
        }
        if (_count == size)
        {
            return arrayof[_currentIndex + 1..size].chain(arrayof[0.._currentIndex + 1]);
        }
        return arrayof[0.._currentIndex + 1].chain(arrayof[(_currentIndex + 1 + size - _count)..size]);
    }
}

unittest
{
    CircularQueue!(int, 4) q;
    assert(q.empty);
    q ~= 1;
    assert(!q.empty);
    assert(q.front == 1);
    assert(q.length == 1);
    assert(equal(q[], [1]));

    q.popFront();
    assert(q.length == 0);
    assert(q.empty);
    import std.algorithm;
    assert(q[].length == 0);
    
    q ~= 2; 
    q ~= 3;
    q ~= 4;
    q ~= 5;
    assert(q.front == 2);
    assert(q.length == 4);
    assert(equal(q[], [2, 3, 4, 5]));
    q ~= 6; // 2 gets replaced
    assert(q.front == 3);
    assert(q.length == 4);

    assert(equal(q[], [3, 4, 5, 6]));
    assert(equal(q[], [3, 4, 5, 6]));
}


class Frequencies : IApp
{
    char[1024] input;
    char[1024] subst;
    AlphabetMap!ulong freqArray;
    AlphabetMap!SingleCharString letters;
    CircularQueue!(char, 32) lastReassignedCharacters;

    void setup()
    {
        input[] = 0;
        subst[] = 0;
        freqArray = AlphabetMap!ulong.init;
        for (char i = 'A'; i <= 'Z'; i++)
            letters[i] = SingleCharString(i);
    }

    void update(double dt)
    {
        bool valueChanged = ImGui.InputTextMultiline("Input", input.ptr, input.length);
        
        if (valueChanged)
        {
            freqArray = countLetterFrequencies(input);
        }
        const rectDefault = ImVec2(0, 0);

        import std.ascii;
        import std.algorithm;

        ImGui.NewLine();
        ImGui.BeginGroup();
        ImGui.PushItemWidth(25);
        for (char i = 'A'; i <= 'Z'; i++)
        {
            if (i % 5 == 0)
                ImGui.NewLine();
            else
                ImGui.SameLine();
            if (ImGui.InputText(textz(i, ":", freqArray[i]), letters[i].ptr, 2))
            {
                valueChanged = true;
                lastReassignedCharacters ~= i;
            }
        }
        ImGui.PopItemWidth();
        ImGui.EndGroup();

        if (ImGui.Button("Normalize"))
        {
            int[letterCount] usedLetterIndices = -1;
            size_t[] indicesOfDuplicates;

            for (size_t i = 0; i < letterCount; i++)
            {
                if (usedLetterIndices[letters.arrayof[i].ch - 'A'] != -1)
                    indicesOfDuplicates ~= i;
                else
                    usedLetterIndices[letters.arrayof[i].ch - 'A'] = cast(int) i;
            }

            foreach (missingCharacterIndex; 0..letterCount)
            {
                // The given letter has not been assigned to any other letter.
                // We need to find a duplicate letter changed last in the queue, and assign that this letter.
                // However, the duplicates in the array only have the later occurences, so we also
                // need to check all of their counterparts, which are at position of their letters
                // in the usedLetterIndices array.
                if (usedLetterIndices[missingCharacterIndex] == -1)
                {
                    import std.algorithm;
                    import std.typecons;

                    size_t retrieveIndexToAssignLetterTo()
                    {
                        long minPosition = int.max;
                        bool isDuplicate = false;
                        size_t resultIndex;

                        // So we go through all duplicates.
                        foreach (index, duplicateIndex; indicesOfDuplicates)
                        {
                            // We find the other element that has been assigned the same character.
                            // that this duplicated one was assigned.
                            const otherIndexAssignedToSameCharacter = usedLetterIndices[letters.arrayof[duplicateIndex].ch - 'A'];
                            assert(otherIndexAssignedToSameCharacter != -1);
                            const positionOfOriginal = lastReassignedCharacters[].indexOf(otherIndexAssignedToSameCharacter + 'A');
                            if (positionOfOriginal == -1)
                            {
                                // Here it's the perfect opportunity to push it out, since it's never been mentioned.
                                // But first, the duplicate now should take its place.
                                // We don't really have to modify the usedLetters thing, since it's not used after that.
                                // So we just take out the duplicate at that index.
                                indicesOfDuplicates = indicesOfDuplicates.remove(index);
                                // Actually, we do use it when looking up characters at indices, right? Because we'll be iterating again after.
                                // So we still need to assign here.
                                usedLetterIndices[letters.arrayof[duplicateIndex].ch - 'A'] = cast(int) duplicateIndex;
                                usedLetterIndices[missingCharacterIndex] = otherIndexAssignedToSameCharacter;
                                return otherIndexAssignedToSameCharacter;
                            }
                            // Try to find the duplicate it in the queue.
                            // The letter it's indexed by is what matters.
                            const positionOfDuplicate = lastReassignedCharacters[].indexOf(cast(char) duplicateIndex + 'A');
                            // If the duplicate was not mentioned, push it out immediately.
                            if (positionOfDuplicate == -1)
                            {
                                indicesOfDuplicates = indicesOfDuplicates.remove(index);
                                usedLetterIndices[missingCharacterIndex] = cast(int) duplicateIndex;
                                return duplicateIndex;
                            }
                            // positionOfOriginal is met earlier in the table, so it has more priority to be taken out.
                            if (positionOfOriginal <= positionOfDuplicate
                                // But it's gotta be less than the current min.
                                && positionOfOriginal <= minPosition)
                            {
                                // We can only have one non-duplicate, but it may replace itself here.
                                // assert(!isDuplicate);

                                minPosition = positionOfOriginal;
                                resultIndex = otherIndexAssignedToSameCharacter;
                                isDuplicate = false; 
                            }
                            
                            // Otherwise check the duplicate cost
                            else if (positionOfDuplicate < minPosition)
                            {
                                minPosition = positionOfDuplicate;
                                resultIndex = index;
                                isDuplicate = true;
                            }
                        }

                        // If no candidates exist, this function would not get called
                        assert(minPosition != int.max);

                        if (isDuplicate)
                        {
                            const result = indicesOfDuplicates[resultIndex];
                            usedLetterIndices[missingCharacterIndex] = cast(int) result;
                            indicesOfDuplicates = indicesOfDuplicates.remove(resultIndex);
                            return result;
                        }

                        // It doesn't matter which guy becomes owner.
                        auto removedOwnerCharacter = letters.arrayof[resultIndex].ch;
                        auto indexOfDuplicateThatBecomesOwner = indicesOfDuplicates.countUntil!(a => letters.arrayof[a].ch == removedOwnerCharacter);
                        // The original now owns the missing character, becauыe it got assigned that character.
                        usedLetterIndices[missingCharacterIndex] = cast(int) resultIndex;
                        // This now owns the character that was assigned to the non-duplicate.
                        usedLetterIndices[removedOwnerCharacter - 'A'] = cast(int) indicesOfDuplicates[indexOfDuplicateThatBecomesOwner];
                        indicesOfDuplicates = indicesOfDuplicates.remove(indexOfDuplicateThatBecomesOwner);

                        return resultIndex;
                    }

                    letters.arrayof[retrieveIndexToAssignLetterTo()].ch = 
                        cast(char) (missingCharacterIndex + 'A');
                }
            }
            valueChanged = true;
        }

        if (valueChanged)
        {
            subst[] = 0;
            size_t j = 0;

            foreach (ch; input)
            {
                if (ch == 0)
                    break;
                if (!isAlpha(ch))
                {
                    subst[j++] = ch;
                    continue;
                }
                ch = toUpper(ch);
                subst[j++] = letters[ch].ch;
            }
        }

        ImGui.InputTextMultiline("With substitutions", subst.ptr, subst.length, rectDefault.byRef, ImGuiInputTextFlags_ReadOnly);
        ImGui.Separator();
    }
}

struct AlphabetMap(T)
{
    T[letterCount] arrayof;

    ref auto opIndex(char ch)
    {
        return arrayof[ch - 'A'];
    }
}


AlphabetMap!ulong countLetterFrequencies(char[] str)
{
    import std.ascii;

    AlphabetMap!ulong result;

    for (size_t i = 0;; i++)
    {
        if (str[i] == 0)
            return result;

        str[i] = toUpper(str[i]);
        
        if (isAlpha(str[i]))
            result[str[i]] += 1;
    }
}


class App : IApp
{
    Caesar _caesar;
    Frequencies _freqs;
    // Initialize data
    void setup()
    {
        _caesar = new Caesar();
        _freqs = new Frequencies();
        _caesar.setup();
        _freqs.setup();
    }

    // The game loop, called each frame
    void update(double dt)
    {
        ImguiImpl.NewFrame();
        if (ImGui.Begin("Tools"))
        {
            _caesar.update(dt);        
            _freqs.update(dt);
        }
        ImGui.End();
        ImGui.Render();
    }
}