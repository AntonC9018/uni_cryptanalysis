

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
    - [Ex. 3 a)](#ex-3-a)
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

Limba engleza conține doar două cuvinte de lungimea 1, 'A' și 'I'.
Însă textul clar conține 3 cuvinte cu o singură literă: 'X', 'F', 'Q'. 
Ori avem o anomalie, ori cifrul nu criptează 1 la 1, ori este într-o altă limbă.
Ne mișcăm mai departe presupunând că e o anomalie.

'XKA' se repetă de 3 ori, cel mai probabil este 'THE' ori 'AND', însă 'X' nu poate fi 'T', deoarece este una din 'A' sau 'I'. Deci 'X' este cel mai probabil 'A', 'K' este 'N', iar 'A' este 'D'.

Pentru comoditatea încercărilor, ca toate literele să fie folosite la orice moment fără corectări manuale, am făcut un buton `Normalize`. Când îl apăsați, găsește toate literele care nu au fost folosite, precum și cele care sunt folosite de mai multe ori, și schimbă acestea cu cele nefolosite. Problema este că chiar dacă numai ce ați schimbat una sau mai multe litere și vreți ca ele să rămână neschimbate, există o posibilitate că ele să fie resubstituite înapoi de așa algoritm. 

Am elaborat un algoritm ceva mai complicat care utilizează o coadă circulară unde pune indicii literelor când utilizatorul le schimbă, și pe urmă utilizează acea coadă pentru a determina ce litere să schimbe. Iată implementarea [coadei circulare](https://github.com/AntonC9018/uni_cryptanalysis/blob/aa44a06e222f8a83e2edd331ecd04436ac1881d3/source/app.d#L92-L181), și [partea principală a algoritmului](https://github.com/AntonC9018/uni_cryptanalysis/blob/aa44a06e222f8a83e2edd331ecd04436ac1881d3/source/app.d#L232-L343). M-am oprit când am văzut că lucrează corect, se mai  poate face refactoring, evident. (Cu totul nu am pierdul 5 ore la aceasta.)

Acum avem:

![](images/lab1_subs1.png)

```
LNZB RMLN A JFDNFEKQ DOBAOV TKFIB F MLNDBOBD TBAH AND TBAOV LSBO 
JANV A XRAFNQ AND ZROFLRP SLIRJB LC CLOELQQBN ILOB TKFIB F NLDDBD 
NBAOIV NAMMFNE PRDDBNIV QKBOB ZAJB A QAMMFNE AP LC PLJB LNB 
EBNQIV OAMMFNE OAMMFNE AQ JV ZKAJYBO DLLO Q FP PLJB SFPFQBO F 
JRQQBOBD QAMMFNE AQ JV ZKAJYBO DLLO LNIV QKFP AND NLQKFNE JLOB
```

Cele mai comune litere din text sunt 'B' - 28, 'K' - 24, 'X' - 23, 'L' - 22. 'B' este cel mai probabil 'E' după frecvența, dar putem și raționaliza. 'K' deja presupunem că este 'N', 'X' tot, 'L' nu poate fi 'E', deoarece cuvintele care încep cu 'E' nu sunt tare comune, însă în textul avem LC de mai multe ori. Presupunem că 'B' este 'E'.

Deci literele pe care le cunoaștem sunt 'ANDE'.

Avem un cuvânt suspicios, LNE, 'L' este probabil 'O'.

Avem două cuvinte de două litere care încep cu 'A': AP și AQ. Sunt cel mai probabil unele dintre AS, AT, AM sau AN.
Nu poate fi AN, deoarece N deja se cunoaște. Deci, 'P' și 'Q' sunt între 'S', 'T' sau 'M'. 

Frecvența literelor 'P' este 8, iar lui 'Q' - 16. 'T' este mai comună în engleză, deci fixăm 'Q' la 'T'.
Atunci 'P' este ori 'S' ori 'M'.

'F' este cel mai probabil 'I', deci vom fixa aceasta.

![](images/lab1_sub2.png)

```
ONZE RMON A JIDNIBKT DLEALV QKIFE I MONDELED QEAH AND QEALV OSEL 
JANV A XRAINT AND ZRLIORP SOFRJE OC COLBOTTEN FOLE QKIFE I NODDED 
NEALFV NAMMINB PRDDENFV TKELE ZAJE A TAMMINB AP OC POJE ONE 
BENTFV LAMMINB LAMMINB AT JV ZKAJYEL DOOL T IP POJE SIPITEL I 
JRTTELED TAMMINB AT JV ZKAJYEL DOOL ONFV TKIP AND NOTKINB JOLE
```

NAMMINB, TAMMINB, LAMMINB termină cu INB. Această 'B' cel mai probabil este 'G'. 'D' arată 'G', deci setăm 'D' la 'G'.

ANDITGE sunt literele fixate.

DLEALV = DREARY, NEALFV = NEARLY, GENTFV = GENTLY, Deci ceea ce este acum la 'F' se duce la 'L', iar ceea ce este la 'V' se duce la 'Y'. (aici am înțeles că butonul meu nu prea are sens, și încă că nu lucrează perfect).

JIDNIGKT este evident MIDNIGHT  și mai unele substituții devin aparente după aceasta.

ONZE = ONCE

RMON = UPON

etc.

![](images/lab1_sub3.png)

```
ONCE UPON A MIDNIGHT DREARY WHILE I PONDERED WEAJ AND WEARY OKER 
MANY A QUAINT AND CURIOUS KOLUME OF FORGOTTEN LORE WHILE I NODDED 
NEARLY NAPPING SUDDENLY THERE CAME A TAPPING AS OF SOME ONE 
GENTLY RAPPING RAPPING AT MY CHAMBER DOOR T IS SOME KISITER I 
MUTTERED TAPPING AT MY CHAMBER DOOR ONLY THIS AND NOTHING MORE
```

KISITER = VISITER

WEAJ = WEAK

```
ONCE UPON A MIDNIGHT DREARY WHILE I PONDERED WEAK AND WEARY OVER 
MANY A QUAINT AND CURIOUS VOLUME OF FORGOTTEN LORE WHILE I NODDED 
NEARLY NAPPING SUDDENLY THERE CAME A TAPPING AS OF SOME ONE 
GENTLY RAPPING RAPPING AT MY CHAMBER DOOR T IS SOME VISITER I 
MUTTERED TAPPING AT MY CHAMBER DOOR ONLY THIS AND NOTHING MORE
```

[Edgar Allan Poe, The Raven](https://www.poetryfoundation.org/poems/48860/the-raven)

Substituțiile finale:

![](images/lab1_sub4.png)

### Ex. 3 a)

```
YMJRJ  YMTIT  QTLDG  JMNSI  KWJVZ  JSHDF  SFQDX  NXWJQ  NJXTS  YMJKF  HYYMF  YNSFS  DQFSL 
ZFLJJ FHMQJ YYJWM FXNYX TBSUJ WXTSF QNYDY MJRTX YTGAN TZXYW FNYYM FYQJY YJWXM 
FAJNX YMJKW JVZJS HDBNY MBMNH MYMJD FUUJF WNSFQ FSLZF LJHQJ FWQDN SJSLQ NXMYM 
JQJYY JWEFU UJFWX KFWQJ XXKWJ VZJSY QDYMF SXFDF NSYNR JXLTS JGDNK DTZBF SYJIY TKNSI 
TZYYM JKWJV ZJSHN JXTKQ JYYJW XBNYM NSFQF SLZFL JDTZM FIYTK NSIFQ FWLJU NJHJT KYJCY 
FSIHT  ZSYJF  HMKWJ  VZJSH  DSTBM  TBJAJ  WBJMF  AJHTR  UZYJW  XYMFY  HFSIT  YMJMF  WIBTW 
PKTWZ XGZYN SKFHY BJITS YJAJS SJJIY TITYM NXXYJ UFXKT WRTXY QFSLZ FLJXY MJWJF WJIFY 
FGFXJ  XTKYM  JQJYY  JWKWJ  VZJSH  NJXBM  NHMMF  AJGJJ  SHFQH  ZQFYJ  IGDQT  TPNSL  FYRNQ 
QNTSX TKYJC YXFSI FWJYM ZXAJW DMNLM QDFHH ZWFYJ
```

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