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
                if (str[i] == ' ')
                {
                    result[j++] = ' ';
                    continue;
                }
                if (str[i] >= 'a' && str[i] <= 'z')
                    str[i] += 'A' - 'a';

                char t = cast(char)(str[i] - 'A' + shift + letterCount) % letterCount + 'A';
                result[j++] = t;
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



class Frequencies : IApp
{
    char[512] input;
    char[512] subst;
    AlphabetMap!ulong freqArray;
    AlphabetMap!SingleCharString letters;

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
            valueChanged |= ImGui.InputText(textz(i, ":", freqArray[i]), letters[i].ptr, 2);
        }
        ImGui.PopItemWidth();
        ImGui.EndGroup();

        // if (ImGui.Button("Normalize"))
        // {
        //     AlphabetMap!int counts;
        //     for (char i = 'A'; i <= 'Z'; i++)
        //         counts[letters[i].ch]++;
            
        //     for (char i = 'A'; i <= 'Z'; i++)
        //     {
        //         if (counts[i] > 1)
        //         for (char j = 'A'; j <= 'Z'; j++)

        //     }
        // }

        if (valueChanged)
        {
            subst[] = 0;
            size_t j = 0;

            foreach (ch; input)
            {
                if (ch == 0)
                    break;
                if (!isAlpha(ch))
                    continue;
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