# Progetto Basi di Dati: Sistema di Gestione Leghe Fantacalcio
## Abstract
Questo progetto ha lo scopo di realizzare una base di dati per un sistema di gestione del fantacalcio.  
Il fantacalcio è un gioco che si basa sulle prestazioni reali dei calciatori in un campionato reale.  
I partecipanti costruiscono squadre virtuali acquistando calciatori reali rispettando un budget prestabilito, ogni squadra è strutturata secondo ruoli specifici (portieri, difensori, centrocampisti e attaccanti), riproducendo la formazione di una squadra di calcio reale.  
Le squadre così formate si sfidano all'interno di leghe, che possono essere pubbliche o private, ovvero limitate a un numero ristretto di partecipanti tramite password.  
All'interno di ogni lega si disputa un campionato virtuale che riproduce l'andamento delle giornate del campionato reale.   
In ciascuna giornata, i calciatori schierati dai partecipanti ottengono un punteggio determinato dalle loro prestazioni reali: reti segnate, assist, rigori parati, ammonizioni, espulsioni e voti attribuiti dali giornali. La somma di questi punteggi forma il risultato della squadra nella giornata stessa.  
I risultati delle giornate aggiornano la classifica della lega, determinando il vincitore finale al termine del campionato.  
Nel contesto di questo progetto la base di dati dovrà gestire gli utenti che parteciperanno al gioco e di conseguenza alle leghe, creando squadre virtuali per sfidarsi con gli altri partecipanti.  
Inoltre dovrà gestire l'assegnazione delle valutazioni ai calciatori reali per ogni giornata del campionato, in modo da calcolare il punteggio delle squadre virtuali e così stilare una classifica generale per ogni lega.  
L'obiettivo è garantire una gestione efficiente e organizzata delle informazioni così da rendere il più semplice possibile l'integrazione con l'applicazione web o mobile che andrà a interagire con la base di dati.  

## Analisi dei requisiti
Questa sezione contiene l'analisi dei requisiti della base di dati, con la descrizione delle entità e delle relazioni tra di esse.  

#### Utente
L'utente è un soggetto che può registrarsi liberamente al sito/app e partecipare al gioco, tuttavia per far ciò deve partecipare o creare una lega.  
L'utente è identificato da un **ID univoco** così da facilitare la modifica dell'indirizzo email, che rimane univoco per ogni utente.
L'utente contiene i seguenti attributi:  

- **ID**: identificativo univoco dell'utente
- **Nome**: nome dell'utente
- **Cognome**: cognome dell'utente
- **Email**: email dell'utente
- **Password**: password dell'utente  

L'utente può essere **premium** o **base**, ovvero il primo non ha limiti di creazione/partecipazione alle leghe, mentre il secondo può creare/partecipare a un massimo di 3 leghe.  
L'utente può partecipare a più di una lega e può esserne admin (non per forza da solo) e deve avere una e una sola squadra per ogni lega.

#### Lega
La lega raggruppa più utenti che partecipano al gioco per permettere loro di sfidarsi in uno o più campionati.  
La lega è identificata da un **nome** univoco e può essere di tipo **pubblica** o **privata**.  
La **lega privata** ha un attributo **password** che permette di accedere alla lega per chi ne è in possesso.  
Essa può avere da più utenti che sono obbligati ad iscrivere una squadra per far parte della lega.  
Inoltre, più campionati possono essere associati a una lega, così da dividere le squadre in più campionati.  

#### Campionato
Il campionato rappresenta l'effettiva competizione tra le squadre.  
Il campionato è identificato dalla **stagione di riferimento** e dal nome della lega a cui appartiene, così da poter avere più campionati per ogni lega ma solo uno per ogni stagione.
Il campionato è composto da più *giornate*, ovvero le *partite* che si svolgono in un determinato periodo di tempo.  
Il campionato deve avere un minimo di 2 squadre così da poter creareare almeno una partita per giornata, alla squadra viene associato un punteggio che rappresenta i punti raccolti dalla squadra in quel determinato campionato e i crediti che rappresentano il budget a disposizione per l'acquisto dei calciatori.
Inoltre può avere il mercato libero, ovvero i calciatori possono far parte della stessa squadra contemporaneamente.

#### Squadra
La squadra è la rappresentazione dell'utente all'interno di una lega a cui partecipa.  
La squadra è identificata dalla **partecipazione a una lega**, ovvero la lega e l'utente a cui appartiene, perciò un utente è obbligato ad avere una e una sola squadra per ogni lega a cui partecipa, inoltre ha un nome non univoco.  
La squadra è composta da almeno 11 calciatori a cui viene associato un valore e una data di acquisto e in caso di svincolo una data di svincolo.  
La squadra può partecipare a più campionati collezionando punti per ogni giornata di campionato e spendendo crediti per l'acquisto dei calciatori.  
La squadra partecipa alle partite durante le giornate, sfidando le altre squadre dello stesso campionato.  

#### Calciatore
Il calciatore rappresenta un calciatore reale che gioca in un campionato reale.
È identificato da un **ID univoco** e ha i seguenti attributi:  

- **Nome**: nome del calciatore
- **Cognome**: cognome del calciatore
- **ID**: identificativo univoco del calciatore reale
- **Squadra**: squadra reale a cui appartiene il calciatore (es. Juventus)  

Inoltre il calciatore può avere un ruolo tra i seguenti:  

- **Portiere**
- **Difensore**
- **Centrocampista**
- **Attaccante**

Utili a rispettare i vincoli di formazione delle squadre.  
Il calciatore può essere partecipare a più squadre (virtuali), potenzialmente anche in squadre dello stesso campionato, dato che il mercato può essere libero.  
Infine al calciatore vengono assegnate delle valutazioni in base alle sue prestazioni reali, utili per determinare la vittoria di una squadra in una partita.

#### Giornata
La giornata rappresenta un insieme di partite che si svolgono nella stessa giornata del campionato reale all'interno del campionato virtuale. 
Essa è identificata da un **ID di tipo intero** e il **campionato** a cui appartiene.  
La giornata è associata a una giornata reale, ovvero la giornata appartenente al campionato reale, così da poter associare le valutazioni dei calciatori nelle giornate virtuali specifiche.  
La giornata è composta da più partite tra due squadre, che si sfidano in casa e in trasferta.

#### Giornata reale
La giornata reale rappresenta una giornata del campionato reale identificata da il **numero di giornata** e la **stagione** a cui appartiene.
Essa può essere assegnata a più giornate virtuali e a più valutazioni dei calciatori.

#### Partita
La partita rappresenta una sfida tra due squadre in una giornata del campionato virtuale ed è identificata da un **ID univoco**.
Essa è associata a due squadra sfidanti in cui una è in casa e l'altra in trasferta.
Ogni sfidante deve schierare una formazione, scegliendi i calciatori tra i componenti della propria squadra.
La partita ha l'attributo **risultato** composto dai punti della squadra ospite e da quella locale.

#### Valutazione
La valutazione rappresenta il punteggio di un calciatore in una giornata reale e si identifica con un l'**ID del calciatore** e l'identificatore della **giornata reale** a cui appartiene.
La valutazione è composta da un voto base, dettato dai giornali, e i bonus/malus che il calciatore ha ricevuto in base ai suoi gol/assist/cartellini e ecc, è importante sottolineare che i bonus e i malus possono essere più di uno per prestazione del calciatore.

#### Formazione
La formazione rappresenta la scelta dell'utente nei calciatori con cui raccogliere i punti in una partita, è perciò composta da un insieme di calciatori che partecipano ad una squadra di un utente, specificando la posizione in cui il calciatore è stato schierato.
La formazione è identificata da un **ID univoco** e contiene il modulo selezionato, che definisce il numero di calciatori per ogni ruolo.
Infine, la formazione è associata a una coppia partita-squadra, così da avere una sola formazione per ogni partita di una squadra.