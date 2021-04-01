# Supermarket

##### Calcan Elena-Claudia 
##### 321CA

Programul reprezinta fluxul clientilor pe la casele unui supermarket.

#### 1. queue
----------------------------------------------------------
  
  - reprezinta implementarea unei cozi folosind 2 stive
  -  structura queue cuprinde urmatoarele campuri:
     - left   -> este o stiva reprezentata ca pe un **flux**
     - right  -> striva reprezentata ca pe o lista
     - size-l -> dimensiunea lui left
     - size-r -> dimensiunea lui right
  - functiile implementate reprezinta operatiile pe care le face o coada: enqueue, dequeue si top
  - functia rotate muta elementele din stiva right in stiva left
  - de fiecare data cand se executa o operatie de enqueue sau dequeue, se verifica daca este necesara
  o rotatie, prentru mentinerea invariantului
  

#### 2. supermarket
-----------------------------------------------------------

  - este implementata simularea supermarket-ului
  - o casa este reprezentata prin structura counter ce are urmatoarele campuri:
    - index     -> index-ul unei case
    - tt        -> total time
    - et        -> exit time
    - queue     -> coada casei reprezentata de structura queue
    - is-closed -> starea unei case, inchisa sau deschisa
   - simularea este data de functia serve care primeste o lista de cereri, requests, ce sunt aplicate
   pe rand caselor
   - exista 2 tipuri de case:
      1. prioritare (fast)
      2. normale (slow)
     
   - se efectueaza 5 tipuri de cereri:
      1.  ADD (client n-items)
          - adauga clientul la coada unei case
          - in functie de numarul de items acesta se poate aseza la o casa prioritara sau normala
          - clientul este asezat la casa cu tt-ul minim din lista de case si care este deschisa
     
     2.   DELAY (index minutes)
          - este crescut tt-ul si et-ul casei cu indexul dat cu un numar de minute dat
          - in cele doua liste se cauta casa cu indexul corespunzator si ii se aplica cererea 
     
     3.   CLOSE (index)
          - starea casei cu indezul dat este setata ca fiind inchisa
          - in cele doua liste se cauta casa cu indexul corespunzator si ii se aplica cererea
     
     4.   PASSED-TIME (minutes)
          - se scad tt-ul si et-ul tuturor caselor 
          - in functie de timpul trecut clientii se scot de la case si se salveaza intr-o lista
      
     5.   ENSURE (average)
          - se adauga case normale pana cand tt-ul mediu a tuturor caselor deschise este mai mic sau egal decat average  
