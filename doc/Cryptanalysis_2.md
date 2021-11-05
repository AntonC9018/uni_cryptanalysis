# Lucrearea de laborator Nr.2 la Criptanaliza

Tema: **Atacul algoritmului DES prin forța brută**

A elaborat: *Curmanschii Anton, IA1901*.

Vedeți [Github](https://github.com/AntonC9018/uni_cryptanalysis).


## Sarcina

1. Calculați trei perechi de text clar-text criptat $ (m_0, c_0), (m_1, c_1), (m_2, c_2) $, folosind sistemul de criptare 
   DES cu cheia secretă $ k $ pe 64 de biți, generată aleator.

2. Considerând cunoscuți 40 de biți arbitrari ai cheii secrete + biții de paritate, să se determine restul 
   biților cheii $ k $, folosind atacul prin forță brută. Numărul de perechi $ (m_i, c_i) $ ce vor fi implicate în 
   realizarea atacului va depinde de faptul dacă există mai multe variante posibile de cheie $ k $. 


## Algoritmul

1. Se generează un număr aleator pe 64 biți. Acest număr este cheia secretă.
   Cheia se ajustează, ca biții de paritate să fie corecte, conform [specificației DES](https://csrc.nist.gov/csrc/media/publications/fips/46/3/archive/1999-10-25/documents/fips46-3.pdf#page=6&zoom=auto,-151,328).

2. Se generează o mască, unde 48 de biți sunt 1 (40 de biți sunt selectate aleator, și 8 biți sunt biții de paritate).
   Pentru aceasta folosesc [algoritmul de enumerare lui Thomas Cover](https://cs.stackexchange.com/a/67669).
   Implementarea necesită funcția $ C _ n ^ k $ (în surse engleze, $ n \choose k $), care dă numărul de combinații.
   Am implementat-o, folosind [triunghiul lui Pascal](https://www.wikiwand.com/en/Binomial_coefficient#/Pascal.27s_triangle).

3. Masca biților cunoscuți de cheie este combinată prin AND cu biții cheii, pentru a primi biții cunoscuți ale cheii.

4. Trecem prin toate măștile posibile, unde sunt setate toți biții măștii cunoscute, și mai un număr variabil de biți pe locuri 
   necunoscute. Această problemă deja am rezolvat-o de mai multe ori în cod, ideea inițial vine [de aici](https://stackoverflow.com/questions/53326021/fast-way-to-shift-bits-to-positions-given-in-a-mask). 
   Pe poziții unde această mască are biții setați unde masca de biți cunoscuți nu le are, punem 1, astfel trecând prin
   toate variantele posibile ale cheii.

5. Pentru fiecare cheie, se verifică paritatea cu ajutorul biților de paritate. 
   Dacă paritatea nu este corectă, cheia se consideră nevalidă.

6. Pentru chei corecte, se verifică dacă o cheie dată criptează toate mesajele clare la mesajele criptate corespunzătoare.
   Verific toate una după altă, pentru a nu culege cheile într-un tablou, verificându-le după ce am cules toate cheile posibile.
   Fac verificarea pe toate perechile de mesaje deoadată, și dacă cheia criptează corect toate mesajele, opresc căutarea.


## Paralelizarea

Pentru paralelizare am folosit modului `std.parallelism` în D.

Algoritmul este următorul:

1. Fixez primii $ N $ biți egale cu 0 din masca biților cunoscuți. 
   Formez o mască, numimită *masca changing*, unde punem 1 pe pozițiile acestor biți.

2. Generez masca biților fixați, egală cu OR-ul dintre masca biților cunoscuți și masca changing.

3. Trec prin toate combinațiile de 0 și 1 posibile pentru cele $ N $ biți a măștii changing.
   Generez cheia inițială, unde combin cu OR biții cunoscuți ai cheii și biții măștii changing.

4. Pentru fiecare așa cheie inițială, verific dacă așa cheie poate exista (este posibil că, de exemplu, toții biți din octetul 
   inițial vor fi fixați, însă paritatea să fie nevalidă). Elimin așa chei.

5. Pentru cheile inițiale valide, pornesc un nou proces, care execută algoritmul inițial, pașii 4-6,
   cu biții fixați setați la masca biților fixați (2), iar biții cheii cunoscuți setați la cheia inițială (3).

6. Procesul principal verifică progresul proceselor care fac computații, oprindu-se și oprindu-le pe toate procesele dacă cheia corectă a fost găsită.


## Realizarea

Vedeți [codul sursă pe github](https://github.com/AntonC9018/uni_cryptanalysis/blob/e43e4f9770e79db9c7809a8a556913f5e5b30d27/source/lab2.d), și [modulele adăugătoare](https://github.com/AntonC9018/uni_cryptanalysis/tree/master/source/common) care implementează [algoritmul DES](https://github.com/AntonC9018/uni_cryptanalysis/blob/e43e4f9770e79db9c7809a8a556913f5e5b30d27/source/common/des.d), [operații utile pe biți](https://github.com/AntonC9018/uni_cryptanalysis/blob/e43e4f9770e79db9c7809a8a556913f5e5b30d27/source/common/bitmagic.d) și [funcția $ C _ n ^ k $](https://github.com/AntonC9018/uni_cryptanalysis/blob/e43e4f9770e79db9c7809a8a556913f5e5b30d27/source/common/combinatorics.d).
Algoritmul nu este optimal, însă a ieșit atât de rapid că se termină aproape instant și pentru un număr de biți cunoscuți egal cu 32. 
Se execută în mai puțin decât un minut pe calculatorul meu pentru doar 25 biți cunoscuți.

## Executarea

Numărul de biți necunoscuți = 25.
Cu numărul de biți setați la o valore mai mare ca 32, atacul se termină cu succes aproape imediat.
Compilatorul meu este DMD, cu LDC codul trebuie să se execute și mai rapid.

```d
$ dub --config=lab2 --build=release
Performing "release" build using C:\D_Lang\dmd2\windows\bin\dmd.exe for x86_64.
uni_cryptanalysis ~master: building configuration "lab2"...
Linking...
Running lab2.exe
         Message -> DES(Message)
7C88488A9967E207 -> 16D83436D3D0B72D
66613089FE9F2740 -> 70C7500BA8C4553D
45F6429968D43E6D -> D5D5598D8C4AE146
Key = 0DE6AE6DABE9E5E3
Started task 0.
Skipping task number 1 (because of parity reasons).
Skipping task number 2 (because of parity reasons).
Started task 3.
Skipping task number 4 (because of parity reasons).
Started task 5.
Started task 6.
Skipping task number 7 (because of parity reasons).
5% of keys checked.
10% of keys checked.
15% of keys checked.
20% of keys checked.
Found the key. It is 0DE6AE6DABE9E5E3

$ dub --config=lab2 --build=release
Performing "release" build using C:\D_Lang\dmd2\windows\bin\dmd.exe for x86_64.
uni_cryptanalysis ~master: target for configuration "lab2" is up to date.
To force a rebuild of up-to-date targets, run again with --force.
Running lab2.exe
         Message -> DES(Message)
9CFF70D43722BE70 -> 74D02F965FF98A79
7A3AB69B3F2ADADB -> 0ACA66AA959EC16C
14A3AB84CA02521D -> 9C9F1BBAA3DF180C
Key = A458C467BAD6D561
Started task 0.
Started task 1.
Started task 2.
Started task 3.
Started task 4.
Started task 5.
Started task 6.
Started task 7.
5% of keys checked.
10% of keys checked.
15% of keys checked.
20% of keys checked.
25% of keys checked.
Found the key. It is A458C467BAD6D561
```