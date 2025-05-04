# Progetto Basi di Dati: Sistema di Gestione Leghe Fantacalcio
## Abstract
Questo progetto ha lo scopo di realizzare una base di dati per un Orchestator come Docker Swarm o Kubernetes.
Un orchestrator è un software che permette di gestire e coordinare più container Docker in un cluster.
In un orchestrator ci possono essere **utenti** con diversi privilegi, nel nostro caso ci sono due tipi di utenti: *admin* e *developer*.
Il primo gestisce la parte infrastrutturale quali i **nodi** e i **volumi**, mentre il secondo coordina la creazione di **servizi** e **deployment**.
I **container** sono l'effettiva entità che esegueno i microservizi, essi risiedono in un **nodo** che può essere qualsiasi macchina con installato Docker, come per esempio una macchina virtuale o un'istanza EC2 su AWS.
Inoltre i container hanno bisogno di salvare i dati persistenti nei **volumi**, che possono essere di tre tipi:
- Il *volume locale* può essere implementato da più container, ma sempre nello stesso nodo.
- Il *volume globale* è localizzato in un server remoto come per esempio un NAS
- Il *volume distribuito* è distribuito su più nodi così da poter essere implementato da container su diversi nodi, ovviamente necessita di forte sincronizzazione tra i nodi.
Il developer ha il compito di creare **servizi** e **deployment**, dove i servizi sono un insieme di container replicati su più nodi e i deployment sono un insieme di servizi che rappresentano il rilascio di una nuova versione dell'applicativo.
L'obiettivo è garantire una gestione efficiente e organizzata delle informazioni così da rendere la gestione dei microservizi e del loro versionamento il più semplice possibile.
## Analisi dei requisiti
## Progettazione concettuale
## Progettazione logica