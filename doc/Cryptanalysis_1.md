

# Lucrearea de laborator Nr.1 la Criptanaliza

A elaborat: *Curmanschii Anton, IA1901*.

Vedeți [Github](https://github.com/AntonC9018/uni_cryptanalysis). 

## Conținutul

- [Lucrearea de laborator Nr.1 la Criptanaliza](#lucrearea-de-laborator-nr1-la-criptanaliza)
  - [Conținutul](#conținutul)
  - [Introducere](#introducere)
  - [Exercițiile](#exercițiile)
    - [1. Cifrul Caesar.](#1-cifrul-caesar)
    - [2. Cifru cu substituție](#2-cifru-cu-substituție)
  - [Remarci](#remarci)
    - [Binding-urile Imgui](#binding-urile-imgui)
    - [De ce nu m-am oprit la binding-urile inițiale pe care le-am găsit și înainte de aceste 4 zile?](#de-ce-nu-m-am-oprit-la-binding-urile-inițiale-pe-care-le-am-găsit-și-înainte-de-aceste-4-zile)

## Introducere

Am implementat o interfață grafică în limbajul [D](https://dlang.org/), utilizând [Imgui](https://github.com/ocornut/imgui) pe baza de [GLFW](https://www.glfw.org/) și [OpenGL](https://www.opengl.org/).

## Exercițiile

### 1. Cifrul Caesar.

**Sarcina:** Folosind analiza frecvenței literelor, determinați conținutul următorului mesaj care a fost obținut prin aplicarea cifrului Caesar.

```
MAXLX TKXGM MAXWK HBWLR HNKXE HHDBG ZYHK
```

Am făcut un modul ce vizualizează frecvențele literelor într-un text.
Încă nu fac sortarea după frecvența.

![Frequencies](images/lab1_frequencies.png)

Codul este destul de simplu, [vedeți după link](https://github.com/AntonC9018/uni_cryptanalysis/blob/9d20c6838edfa86313602813d1a53d7b6ab890b3/source/app.d#L67-L210).

Momentul principal care calculează frecvențele este realizat astfel.
Am făcut o structură ce permite indexarea unui tablou prin litere.
Funcția `countLetterFrequencies()` trece prin toate literele unui 'slice' (pointer + lungime) nul-terminat (lungimea aici este utilizată numai pentru bounds checking, previne bug-uri).
```d
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
```

Cea mai des întâlnita literă în alfabetul englez este 'e', iar în textul nostru cea mai desa literă este 'x'.
Ghicim că litera 'x' corespunde literii 'e', sau în alte cuvinte, cifrul cezarului a mișcat litera 'e' cu 'e' - 'x' poziții.

$ x - e = 5 - 24 = -19 \equiv 7 \mod 26 $.

Am mai făcut o interfață simplă pentru cezar. 
Aici am introdus textul criptat, și numărul 7, și am primit textul decriptat lizibil.

![](images/lab1_caesar.png)

Codul se încape în [40 de linii într-o singură clasă](https://github.com/AntonC9018/uni_cryptanalysis/blob/9d20c6838edfa86313602813d1a53d7b6ab890b3/source/app.d#L20-L65):

Deci, am primit răspunsul *THESE AREN'T THE DROIDS YOU'RE LOOKING FOR*.


### 2. Cifru cu substituție

Un cifru cu substituțiile, spațiile sunt păstrate.

```
LKZB RMLK X JFAKFDEQ AOBXOV TEFIB F MLKABOBA TBXH XKA TBXOV LSBO 
JXKV X NRXFKQ XKA ZROFLRP SLIRJB LC CLODLQQBK ILOB TEFIB F KLAABA 
KBXOIV KXMMFKD PRAABKIV QEBOB ZXJB X QXMMFKD XP LC PLJB LKB 
DBKQIV OXMMFKD OXMMFKD XQ JV ZEXJYBO ALLO Q FP PLJB SFPFQBO F 
JRQQBOBA QXMMFKD XQ JV ZEXJYBO ALLO LKIV QEFP XKA KLQEFKD JLOB
```

Limba engleza conține doar două cuvinte de lungime 1, 'A' și 'I'. Deci 'X' și 'F' sunt ori 'A' ori 'I'.

'XKA' se repetă de 3 ori, cel mai probabil este 'THE', deci 'X' este probabil 'A'.

## Remarci

### Binding-urile Imgui

Este urât că imgui (încă) nu poate fi utilizat în D direct (este scris în limbajul C++), deci se utilizează așa numite binding-urile.
În esența funcțiile se iau după nume ori din librăria statică cu extensia `lib`, ori din librăria dinamică `dll` în timpul rulării.
Problema cu binding-urile este că ele de obicei nu se scriu manual, deoarece necesită munca plicitisitoare, ci generate prin traducerea fișierilor header în limbajul-țintă automatizată, sau semi-automatizată (traducerea inițială + unele corectări manuale).
Aceste instrumente ori nu sunt tare bune, ori sunt dificil de rulate, ori necesită îngrijire care autorii nu au timp s-o furnizeze, de aceea (încă) nu este posibil de generat așa binding-uri pentru orice librărie într-un mod simplu și standartizat.

Am pierdut 4 zile încercând să aduc un proiect de generare a binding-urilor la o stare bună, însă când îmi părea că am terminat și că este destul de bun, de fapt l-am încercat și am înțeles că nu merge. 
Mai necesită prea multe lucruri pentru a fi considerat plăcut de utilizat, însă eu nu mai pot să-mi aloc timpul pentru aceasta.

### De ce nu m-am oprit la binding-urile inițiale pe care le-am găsit și înainte de aceste 4 zile?

În ImGui există 2 ramure — `master` și `docking`. 
Docking-ul este foarte interesant, deoarece permite gruparea comodă a ferestrelor, însă binding-urile inițiale nu l-au suportat.
De aceea