# Supermarket

##### Calcan Elena-Claudia 
##### 321CA

Programul reprezinta fluxul clientilor pe la casele un supermarket.

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
