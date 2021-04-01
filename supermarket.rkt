#lang racket
(require racket/match)
(require "queue.rkt")

(provide (all-defined-out))

(define ITEMS 5)
(define MAX-TT 100000)


; TODO
; Aveți libertatea să vă structurați programul cum doriți (dar cu restricțiile
; de mai jos), astfel încât funcția serve să funcționeze conform specificației.
; 
; Restricții (impuse de checker):
; - trebuie să existe în continuare funcția (empty-counter index)
; - cozile de la case trebuie implementate folosind noul TDA queue
(define-struct counter (index tt et queue is-closed) #:transparent)

(define (empty-counter index)
  (make-counter index 0 0 empty-queue #f))

;; functie care aplica o modificare casei cu un anumit index dat ca parametru
(define (update f counters index)
   (map (lambda (x) (if (= (counter-index x) index) (f x) x)) counters))

;; creste tt-ul unei case cu un anumit numar de minute
(define tt+
   (lambda (min)
    (lambda (C)
    (match C
    [(counter _ tt _ _ _)
     (struct-copy counter C [tt (+ tt min)])]))))

;; creste et-ul unei case cu un numar dat de minute
(define et+
    (lambda (min)
    (lambda (C)
    (match C
      [(counter _ _ et _ _)
           (struct-copy counter C [et (+ et min)])]))))

;; adauga o persoana la o casa, urmand ca tt-ul si et-ul (in cazul in care nu este nimeni la coada) sa creasca
(define (add-to-counter name items)   
  (λ (C)                                
    (match C
      [(counter _ tt et queue _ )
       (if (queue-empty? queue)
           (struct-copy counter C
                        [tt (counter-tt ((tt+ items) C))]
                        [et (counter-et ((et+ items) C))]
                        [queue (enqueue (cons name items) (counter-queue C))])
           (struct-copy counter C
                        [tt (counter-tt ((tt+ items) C))]
                        [queue (enqueue (cons name items) (counter-queue C))]))])))

;; functie abstracta ce calculeaza minimul unei liste de case
(define general-min-func
  (lambda (f)
    (lambda (L)
      (if (null? L)
          (cons 0 MAX-TT) ;; daca se primeste o lista vide atunci se intoarce o pereche dintre 0 si un numar maxim pentru tt presupus
      (foldl (lambda (C acc) (if (< (cdr (f C)) (cdr acc)) (f C) acc)) (f (car L)) (cdr L))))))

(define (min-tt L) ((general-min-func extract-idx-tt) L)) ;; afla casa cu tt-ul minim folosind functia de mai sus
(define (min-et L) ((general-min-func extract-idx-et) L)) ;; afla casa cu et-ul minim folosind functia de mai sus

;; extrage indexul si tt-ul a unei case si returneaza perechea (index . tt)
(define (extract-idx-tt C)
  (cons (counter-index C) (counter-tt C)))

;; extrage indexul si et-ul a unei case si returneaza perechea (index . et)
(define (extract-idx-et C)
 (cons (counter-index C) (counter-et C)))

;; elimina prinma persoana din coada unei case
(define (remove-first-from-counter C)   
   (let ([new-q (dequeue (counter-queue C))])
     (make-counter (counter-index C) (tt-after-remove 0 new-q) (et-after-remove new-q) new-q (counter-is-closed C))))

;; calculeaza tt-ul unei case dupa ce o persoana a plecat
(define (tt-after-remove new-tt q)
  (let loop-stream-queue ([queue (queue-left q)] [size (queue-size-l q)])
    (if (zero? size)
        0
        (+ (cdr (stream-first queue)) (loop-stream-queue (stream-rest queue) (sub1 size)) ))))

;; calculeaza et-ul unei case dupa ce o persoan a plecat
(define (et-after-remove q)
  (if (queue-empty? q) 0 (cdr (top q))))

;; calculeaza starea unei case după un numar dat de minute
(define (pass-time-through-counter minutes)
  (λ (C)
    (cond
      ((and (< (counter-et C) minutes) (< (counter-tt C) minutes)) (struct-copy counter C [tt 0] [et 0]))
      ((and (< (counter-et C) minutes) (>= (counter-tt C) minutes))
       (struct-copy counter C [tt (- (counter-tt C) minutes)] [et 0] ))
      (else (struct-copy counter C [tt (- (counter-tt C) minutes)] [et (- (counter-et C) minutes)])))))

;; seteaza starea unei case ca fiind inchisa
(define close-counter
  (lambda (C)
    (struct-copy counter C [is-closed #t])))
  
; TODO
; Implementați funcția care simulează fluxul clienților pe la case.
; ATENȚIE: Față de etapa 3, apare un nou tip de cerere, așadar
; requests conține 5 tipuri de cereri (cele moștenite din etapa 3 plus una nouă):
;   - (<name> <n-items>) - persoana <name> trebuie așezată la coadă la o casă              (ca înainte)
;   - (delay <index> <minutes>) - casa <index> este întârziată cu <minutes> minute         (ca înainte)
;   - (ensure <average>) - cât timp tt-ul mediu al caselor este mai mare decât
;                          <average>, se adaugă case fără restricții (case slow)           (ca înainte)
;   - <x> - trec <x> minute de la ultima cerere, iar starea caselor se actualizează
;           corespunzător (cu efect asupra câmpurilor tt, et, queue)                       (ca înainte)
;   - (close <index>) - casa index este închisă                                            (   NOU!   )
; Sistemul trebuie să proceseze cele 5 tipuri de cereri în ordine, astfel:
; - persoanele vor fi distribuite la casele DESCHISE cu tt minim; nu se va întâmpla
;   niciodată ca o persoană să nu poată fi distribuită la nicio casă                       (mică modificare)
; - când o casă suferă o întârziere, tt-ul și et-ul ei cresc (chiar dacă nu are clienți);
;   nu aplicați vreun tratament special caselor închise                                    (ca înainte)
; - tt-ul mediu (ttmed) se calculează pentru toate casele DESCHISE, 
;   iar la nevoie veți adăuga case slow una câte una, până când ttmed <= <average>         (mică modificare)
; - când timpul prin sistem avansează cu <x> minute, tt-ul, et-ul și queue-ul tuturor 
;   caselor se actualizează pentru a reflecta trecerea timpului; dacă unul sau mai mulți 
;   clienți termină de stat la coadă, ieșirile lor sunt contorizate în ordine cronologică. (ca înainte)
; - când o casă se închide, ea nu mai primește clienți noi; clienții care erau deja acolo
;   avansează normal, până la ieșirea din supermarket                                    
; Rezultatul funcției serve va fi o pereche cu punct între:
; - lista sortată cronologic a clienților care au părăsit supermarketul:
;   - fiecare element din listă va avea forma (index_casă . nume)
;   - dacă mai mulți clienți ies simultan, sortați-i crescător după indexul casei
; - lista cozilor (de la case DESCHISE sau ÎNCHISE) care încă au clienți:
;   - fiecare element va avea forma (index_casă . coadă) (coada este de tip queue)
;   - lista este sortată după indexul casei


(define (serve requests fast-counters slow-counters)
   (serve-helper requests fast-counters slow-counters '()))

;; functie ajutatoare care intoarce o perche intre lista sortata cronologic a clientilor care au parasit supermarket-ul
;; si lista cozilor care inca mai au clienti 
(define (serve-helper requests fast-counters slow-counters gone-ppl)
  (if (null? requests)
      (cons gone-ppl (append (get-queues fast-counters) (get-queues slow-counters)))
      ;; se verifica tipul cererii
      (match (car requests)

        [(list 'delay index minutes) ;; delay
          (if (is-in-counters? fast-counters (cadr (car requests))) ;; se verifica daca se aplica unei case de tip fast
             (serve-helper (cdr requests) (update (delay-action (caddr (car requests))) fast-counters (cadr (car requests)))  slow-counters gone-ppl) 
             (serve-helper (cdr requests) fast-counters (update (delay-action (caddr (car requests))) slow-counters (cadr (car requests))) gone-ppl))]

        [(list 'ensure average) ;; ensure
          (serve-helper (cdr requests) fast-counters (add-counters slow-counters  fast-counters (cadr (car requests))) gone-ppl)]

        [(list 'close index) ;; close
         (if (is-in-counters? fast-counters (cadr (car requests))) ;; se verifica daca se aplica unei case de tip fast
             (serve-helper (cdr requests) (update close-counter fast-counters (cadr (car requests))) slow-counters gone-ppl)
             (serve-helper (cdr requests) fast-counters (update close-counter slow-counters (cadr (car requests))) gone-ppl))]

        [(cons name n-items) ;; add 
          (if (<=  (cadr (car requests)) ITEMS) ;; se verifica daca persoana are maxim ITEMS
             (cond
               ;; persoana se duce la casa cu cel mai mic tt dintre casa cu tt-ul minim din fast counters si casa cu tt-ul minim din slow counters 
               ((<= (cdr (min-tt (open-counters fast-counters))) (cdr (min-tt (open-counters slow-counters))))
                (serve-helper (cdr requests)
                              (update (add-to-counter (car (car requests)) (cadr (car requests))) fast-counters (car (min-tt (open-counters fast-counters))))
                              slow-counters
                              gone-ppl))
               (else (serve-helper (cdr requests)
                                   fast-counters
                                   (update (add-to-counter (car (car requests)) (cadr (car requests))) slow-counters (car (min-tt (open-counters slow-counters))))
                                   gone-ppl)))
             ;; persoana are mai multe produse decat ITEMS si se duce la casa cu tt-ul minim din slow counters
             (serve-helper (cdr requests)
                           fast-counters
                           (update (add-to-counter (car (car requests)) (car (cdr (car requests)))) slow-counters (car (min-tt (open-counters slow-counters))))
                           gone-ppl))]
        
        [number  ;; passed-time
         (serve-helper (cdr requests)
                       (time-passed fast-counters (car requests))
                       (time-passed slow-counters (car requests))
                       (append gone-ppl (must-leave '() (append fast-counters slow-counters) (car requests))))
                       ])))

;; intoarce o lista de perechi (index . queueue) a tuturor caselor ce inca au clienti
;; se filtreaza casele care inca au clienti si se construieste o lista de perechi (index . queue)
(define (get-queues counters)
  (foldl (λ (C acc)  (append acc (list (cons (counter-index C) (counter-queue C))))) '()
        (filter (λ (C) (not (queue-empty? (counter-queue C)))) counters)))


;; salveaza intr-o lista toate persoanele care pleaca de la case dupa un anumit interval de timp
;; pentru fiecare casa din lista se apeleaza functia must-leave-helper si rezultatul se concateneaza la lista ppl, lista ce contine toti clientii care au plecat
;; la final lista ppl este sortata crescator (cronologic) in functie dupa care clientii au parasit casa
;; se creeaza o lista de perechi formata din index-ul casei de unde au plecat si numele clientului
(define (must-leave ppl counters minutes)
  (if 
    (null? counters)
    (foldl (λ (C acc) (append acc (list (cons (car C) (cadr C))))) '() (sort ppl  (λ (x y) (if (not (= (caddr x) (caddr y))) (> (caddr x) (caddr y)) (< (car x) (car y))))))
     (must-leave (append ppl (must-leave-helper (counter-queue (car counters)) '() minutes (counter-index (car counters)) (counter-et (car counters)))) (cdr counters) minutes)))

;; functie care salveaza persoanele care pleaca de la o anumita casa dupa un interval de timp
;; functia intoarce o lista de liste cu 3 elemente formata din index-ul casei, numele persoanei si timpul dupa care a plecat
(define (must-leave-helper q ppl time idx initial-et)
  (cond
    ((queue-empty? q) ppl)
    ((< time initial-et) ppl)
    (else (must-leave-helper (dequeue q) (append ppl (list (list idx (car (top q)) (- time initial-et)))) (- time initial-et) idx (next-person q)))))


;; funcia intoarce urmatoarea persoana de la coada sau 0 daca coada este goala
(define (next-person q)
  (if (queue-empty? (dequeue q)) 0 (cdr (top (dequeue q)))))
  
;; calculeaza timpul care a trecut pe la fiecare casa
(define (time-passed counters time)
    (map (λ (C) (if (zero? (counter-et C)) C (counter-after-time-passed ((pass-time-through-counter time) C) (- time (counter-et C))))) counters))

;; actualizeaza o casa dupa un anumit interval de timp
;; cat timp nu au trecut toate minutele si clientii au terminat de stat la coada, acestia se scot din coada casei
(define (counter-after-time-passed C time) 
  (cond
    ((queue-empty? (counter-queue C)) C)
    ((and (zero? time) (zero? (counter-et C))) (remove-first-from-counter C))
    ((<= time 0) C)
    ((and (zero? (counter-et C)) (not (zero? time)) (not (queue-empty? (counter-queue C)))) (counter-after-time-passed (remove-first-from-counter C) time))
    (else (counter-after-time-passed ((pass-time-through-counter time) C) (- time (counter-et C))))))

;; verifica daca indexul apartine unei case 
(define (is-in-counters? counters idx)
  (cond
    ((null? counters) #f)
    ((eq? (counter-index (car counters)) idx) #t)
    (else (is-in-counters? (cdr counters) idx))))

;; filtreaza casele care sunt deschise
(define (open-counters counters)
  (filter (λ (C) (not (counter-is-closed C))) counters))

;; face suma tt-urilor a unei liste de counters care sunt deschise
(define (sum-tt counters)
  (foldl (λ (C acc) (if (not (counter-is-closed C)) (+ acc (counter-tt C)) acc)) 0 counters))

;; adauga case de tipul slow in functie de media cererii ensure
(define (add-counters slow-counters fast-counters average)
  (if (<= (/ (+ (sum-tt slow-counters) (sum-tt fast-counters)) (+ (length (open-counters slow-counters)) (length (open-counters fast-counters)))) average)
      slow-counters
      (add-counters (append slow-counters (list (empty-counter (add1 (+ (length fast-counters) (length slow-counters)))))) fast-counters average)))

;; realizeaza cererea de delay a unei case, crescand tt-ul si et-ul acesteia
(define (delay-action min)
    (lambda (C)
      (struct-copy counter C
                   [tt (counter-tt ((tt+ min) C))]
                   [et (counter-et ((et+ min) C))])))