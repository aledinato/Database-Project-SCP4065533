# Progetto Basi di Dati: Sistema di Gestione Orchestrator
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
Questa sezione descrive i requisiti funzionali della base di dati dell'orchestrator.
- **Utenti**: ogni utente è identificato da uno *username* ed ha il ruolo di gestire tutta l'infrastruttua dell'orchestrator.
Contengono le seguenti informazioni:
    - *username*: stringa univoca che identifica l'utente
    - *password*: stringa che rappresenta la password dell'utente   

Gli utenti possono essere di due tipi: **admin** e **developer**

- **Utenti admin**: hanno il compito di creare e gestire nodi e volumi, quindi la parte infrastrutturale dell'orchestrator.
  
- **Utenti developer**: hanno il compito di creare e gestire servizi e deployment, quindi la parte applicativa dell'orchestrator.
  
- **Nodi**: sono le macchine fisiche o virtuali che eseguono i container Docker.
Contengono le seguenti informazioni:
    - *hostname*: stringa univoca che identifica il nodo
    - *ip*: stringa che rappresenta l'indirizzo IP del nodo
    - *sistema operativo*: stringa che rappresenta il sistema operativo del nodo
    - *stato*: stringa che rappresenta lo stato del nodo
I nodi possono avere allocati diversi tipi di volumi(locale e distribuito) e oltre ad essere gestiti da un admin, possono contenere più container Docker.
- **Container**:  sono le entità che eseguono i microservizi e fanno parte di un servizio all'interno di un nodo.
Contengono le seguenti informazioni:
    - *nome*: stringa che insieme al servizio padre identifica il container
    - *stato*: stato del container
I container possono avere associati più volumi che però sono allocati su un nodo, il container ha associato solo volumi che sono presenti nel nodo in cui il container è in esecuzione.
Inoltre i container possono accedere a path limitate e diverse del volume con permessi differenti, come per esempio lettura e scrittura.
- **Volumi**: sono le entità che permettono di salvare dati persistenti dei container Docker.
Contengono le seguenti informazioni:
    - *id*: stringa che identifica il volume
    - *dimensione*: numero che rappresenta la dimensione del volume in termini di spazio
    - *path fisico*: stringa che rappresenta il path fisico del volume all'interno del nodo
I volumi possono essere di tre tipi: **locale**, **globale** e **distribuito**.
- **Volume locale**: è un volume che può essere allocato solo su un nodo e può essere condiviso da più container dello stesso nodo
- **Volume globale**: è un volume centralizzato che può essere allocato su un server NAS e può essere condiviso da più container di nodi diversi senza la necessità che il nodo padre abbia il volume allocato.
Necessita oltre al path fisico del volume, anche di un indirizzo IP del server NAS così da poterlo raggiungere.
- **Volume distribuito**: è un volume che può essere allocato su più nodi e può essere condiviso da più container di nodi diversi che hanno una distribuzione del volume
- **Servizi**: sono un astrazione che rappresenta un insieme di container replicati su più nodi.
Contengono le seguenti informazioni:
    - *nome*: titolo del servizio
    - *versione*: versione del servizio, insieme al nome identifica univocamente il servizio
    - *immagine*: immagine Docker da cui verranno creati i container
    - *numero repliche*: numero che rappresenta il numero di repliche del servizio
I servizi sono creati e gestiti da un developer, il quale può creare più servizi con lo stesso nome ma con versioni diverse.
I servizi hanno più container associati (le "repliche"), potenzialmente anche sullo stesso nodo.
- **Deployment**: sono un astrazione che rappresenta un insieme di servizi che vengono rilasciati in una nuova versione dell'applicativo.
Contengono le seguenti informazioni:
    - *ID*: stringa che identifica il deployment
    - *ambiente*: ambiente in cui viene eseguito il deployment (sviluppo, test, produzione)
    - *esito*: esito del deployment (success, running, failed)
    - *numero servizi*: numero di servizi che lo compongono
Il deployment ha associato più servizi e può essere creato solo da un developer.
Inoltre è possibile creare uno storico dei deployment, quindi quando si crea un nuovo deployment il precedente viene associato a quello nuovo come "padre".

## Progettazione concettuale
![Progettazione concettuale](/assets/ER.drawio.png)
Si vuole realizzare una base di dati per la gestione di un orchestrator che gestisce i container Docker in un cluster.
Un cluster contiene diversi nodi, di cui si vogliono memorizzare indirizzo IP, nome del sistema operativo e stato ("Up", "Down" e "Drain"). Ogni nodo è identificato da un proprio hostname univoco.
Su ogni nodo possono essere ospitati diversi container Docker, di cui è di interesse conoscere nome e stato.
Ciascun container opera su diversi volumi che utilizza come file system. Un volume può anche essere condiviso tra più container. Ciascun volume è visto da un container con un percorso distinto e ciascun container dispone di permessi specifici su ognuno dei suoi volumi (lettura, scrittura, esecuzione, ecc.).
I volumi, anche se condivisi da più container, dispongono di un proprio percorso fisico ed è di interesse memorizzarne la dimensione e il tipo (Locale, globale e distribuito). Mente un volume locale può essere allocato ad un solo nodo, i volumi distribuiti possono essere allocati su più nodi.
I container, anche su nodi diversi, sono raggruppati in servizi distinti. Per ogni servizio, identificato da nome e versione, è di interesse sapere il percorso dell'immagine e il numero di repliche. Il volume può anche non essere associato a nessun container, ma è comunque allocato in un nodo.
Il diagramma ER non permette di rappresentare il seguente vincolo che si evince dall'analisi dei requisiti: un volume può essere associato a un container e allocato in un nodo solo se il nodo padre del container è lo stesso a cui è allocato il volume.
Sia $V$ l'insieme dei Volumi, $C$ l'insieme dei Container e $N$ l'insieme dei Nodi, allora:
$$
\forall v \in V \backslash \{\text{volumi globali}\}, c \in C, n \in N: v \in Associato(c), n \in Allocazione(v) \Rightarrow n \in Ospitazione(c)
$$
## Progettazione logica
#### Analisi delle ridondanze
#### Eliminazione delle generalizzioni
![Progettazione concettuale](/assets/ER_Refurbished.drawio.png)
#### Schema relazionale
- **Utente**(<u>Username</u>, Password, Ruolo)
- **Servizio**(<u>Nome, Versione</u>, Immagine, NumeroRepliche?, Developer)
  - Servizio.Developer $\to$ Utente.Username
- **Deployment**(<u>ID</u>, Ambiente, Esito, NumeroServizi?, ID_Deployment_Precedente$^*$, ID_Developer)
  - Deployment.ID_Developer $\to$ Utente.Username
  - Deployment.ID_Deployment_Precedente $\to$ Deployment.ID
- **ServizioDeployment**(VersioneServizio, NomeServizio, ID_Deployment)
  - ServizioDeployment.ID_Deployment $\to$ Deployment.ID
  - ServizioDeployment.(NomeServizio, VersioneServizio) $\to$ Servizio.(Nome, Versione)
- **Nodo**(<u>ID</u>, Hostname, IP, OS, Status, ID_Admin)
  - Nodo.ID_Admin $\to$ Utente.Username
- **Container**(<u>ID, NomeServizio, VersioneServizio</u>, Nome, Stato)
  - Container.(NomeServizio, VersioneServizio) $\to$ Servizio.(Nome, Versione)
- **VolumeLocale**(<u>ID</u>, Dimensione, PathFisico, ID_Nodo)
  - VolumeLocale.ID_Nodo $\to$ Nodo.ID
- **VolumeGlobale**(<u>ID</u>, Dimensione, PathFisico, IndirizzoIPServer)
- **VolumeDistribuito**(<u>ID</u>, Dimensione, PathFisico)
- **VolumiLocaliContainer**(<u>ID_Volume, ID_Container, NomeServizioContainer, VersioneServizioContainer</u>, PathMontaggio, Permessi)
  - VolumiLocaliContainer.ID_Volume $\to$ VolumeLocale.ID
  - VolumiLocaliContainer.(ID_Container, NomeServizioContainer, VersioneServizioContainer) $\to$ Container.(ID, NomeServizio, VersioneServizio)
- **VolumiGlobaliContainer**(<u>ID_Volume, ID_Container, NomeServizioContainer, VersioneServizioContainer</u>, PathMontaggio, Permessi)
  - VolumiGlobaliContainer.ID_Volume $\to$ VolumeGlobale.ID
  - VolumiGlobaliContainer.(ID_Container, NomeServizioContainer, VersioneServizioContainer) $\to$ Container.(ID, NomeServizio, VersioneServizio)
- **VolumiDistribuitiContainer**(<u>ID_Volume, ID_Container, NomeServizioContainer, VersioneServizioContainer</u>, PathMontaggio, Permessi)
  - VolumiDistribuitiContainer.ID_Volume $\to$ VolumeDistribuito.ID
  - VolumiDistribuitiContainer.(ID_Container, NomeServizioContainer, VersioneServizioContainer) $\to$ Container.(ID, NomeServizio, VersioneServizio)
- **AllocazioneDistribuita**(<u>ID_Volume, ID_Nodo</u>)
  - AllocazioneDistribuita.ID_Volume $\to$ VolumeDistribuito.ID
  - AllocazioneDistribuita.ID_Nodo $\to$ Nodo.ID