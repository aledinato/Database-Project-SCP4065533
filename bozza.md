# Progetto Basi di Dati: Sistema di Gestione Orchestrator
## Abstract
Questo progetto ha lo scopo di realizzare una base di dati per un Orchestrator come Docker Swarm o Kubernetes.
Un orchestrator è un software che permette di gestire e coordinare più container Docker in un cluster.
In un orchestrator ci possono essere **utenti** con diversi privilegi, nel nostro caso ci sono due tipi di utenti: *admin* e *developer*.
Il primo gestisce la parte infrastrutturale quali i **nodi**, mentre il secondo coordina la creazione di **servizi** e **deployment**.
I **container** sono l'effettiva entità che eseguono i microservizi, essi risiedono in un **nodo** che può essere qualsiasi macchina con installato Docker, come per esempio una macchina virtuale o un'istanza EC2 su AWS.
Inoltre i container hanno bisogno di salvare i dati persistenti nei **volumi**, che possono essere di tre tipi:
- Il *volume locale* può essere montato su più container, ma sempre nello stesso nodo.
- Il *volume globale* è localizzato in un server remoto come per esempio un NAS
- Il *volume distribuito* è distribuito su più nodi così da poter essere montato su container con nodi diversi tra di loro, ovviamente necessita di forte sincronizzazione tra i nodi.  

Il developer ha il compito di creare **servizi** e **deployment**, dove i servizi sono un insieme di container replicati su più nodi e i deployment sono un insieme di servizi che rappresentano il rilascio di una nuova versione dell'applicativo.
L'obiettivo è garantire una gestione efficiente e organizzata delle informazioni così da rendere la gestione dei microservizi e del loro versionamento il più semplice possibile.

## Analisi dei requisiti
Questa sezione descrive i requisiti funzionali della base di dati dell'orchestrator.
- **Utenti**: ogni utente è identificato da uno *username* ed ha il ruolo di gestire tutta l'infrastruttua dell'orchestrator.
Contengono le seguenti informazioni:
    - *username*: stringa univoca che identifica l'utente
    - *password*: stringa che rappresenta la password dell'utente   

Gli utenti possono essere di due tipi: **admin** e **developer**

- **Utenti admin**: hanno il compito di creare e gestire nodi, quindi la parte infrastrutturale dell'orchestrator.
  
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
Inoltre i container possono accedere a path limitati e diverse del volume con permessi differenti, come per esempio lettura e scrittura.
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
    - *nome*: titolo del servizio che lo identifica
    - *immagine*: immagine Docker da cui verranno creati i container
    - *numero repliche*: numero che rappresenta il numero di repliche del servizio
I servizi sono creati e gestiti da un developer, il quale può creare più servizi con diverso nome.
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
![Progettazione concettuale](./assets/ER.jpg)
Si vuole realizzare una base di dati per la gestione di un orchestrator che gestisce i container Docker in un cluster.
Un cluster contiene diversi nodi, di cui si vogliono memorizzare indirizzo IP, nome del sistema operativo e stato ("Up", "Down" e "Drain"). Ogni nodo è identificato da un proprio hostname univoco.
Su ogni nodo possono essere ospitati diversi container Docker, di cui è di interesse conoscere nome e stato.
Ciascun container opera su diversi volumi, utilizzati come file system, e un volume può anche essere condiviso tra più container. Ciascun volume è visto da un container con un percorso distinto e ciascun container dispone di permessi specifici su ognuno dei suoi volumi (lettura, scrittura, esecuzione, ecc.). I volumi, anche se condivisi da più container, dispongono di un proprio percorso fisico ed è di interesse memorizzarne la dimensione (in KB) e il tipo (locale, globale e distribuito).
Ad esempio, un volume A di qualsiasi tipo, con percorso '<u>/volumes/A</u>', può essere montato a due diversi container: il container $C_1$, che lo vede con il percorso '<u>/var/files</u>' e su cui dispone di tutti i permessi, e il container $C_2$, che lo vede con percorso '<u>/data/read</u>', a cui può accedere in sola lettura. Dunque se $C_1$ vuole accedere al file fisico '<u>/volumes/A</u>/net/hosts.txt' lo potrà fare con il percorso '<u>/var/files</u>/net/hosts.txt'.
Mentre un volume locale può essere allocato ad un solo nodo, i volumi distribuiti possono essere allocati su più nodi. I volumi globali, a differenza degli altri due tipi, non sono allocati a nessun nodo, e sono accessibili con un proprio indirizzo IP, che va quindi memorizzato. Un qualsiasi volume può anche non essere associato a nessun container, ma è comunque allocato in un nodo.
I container, anche su nodi diversi, sono raggruppati in servizi distinti, ovvero un container può essere parte di un solo servizio. Per ogni servizio, identificato da nome, è di interesse sapere il percorso dell'immagine e il numero di repliche.
Il diagramma ER non permette di rappresentare il seguente vincolo che si evince dall'analisi dei requisiti: un volume può essere associato a un container e allocato in un nodo solo se il nodo padre del container è lo stesso a cui è allocato il volume.
Sia $V$ l'insieme dei Volumi, $C$ l'insieme dei Container e $N$ l'insieme dei Nodi, allora:
$$
\forall v \in V \backslash \{\text{volumi globali}\}, c \in C, n \in N: v \in Associato(c), n \in Allocazione(v) \Rightarrow n \in Ospitazione(c)
$$
## Progettazione logica
Questa sezione descrive la progettazione logica dato lo schema concettuale sviluppato nella sezione precedente, con lo scopo di analizzare le ridondanze ed eliminare le generalizzazioni.
#### Tabella Entità-Relazioni
###### Tabella delle entità
| Entità | Descrizione | Attributi | Identificatore |
|-----------|-----------|-----------|-----------|
| Utente | Utente che gestisce l'orchestrator | *Username, Password, Ruolo* | *Username* |
| Developer | Utente che gestisce i servizi e i deployment | |  |
| Admin | Utente che gestisce i nodi | |  |
| Nodo | Macchina fisica o virtuale che esegue i container Docker | *Hostname, Indirizzo IP, OS, Stato* | *Hostname* |
| Container | Entità che esegue i microservizi | *Nome, Stato* | *Nome, NomeServizio* |
| Volume | Entità che permette di salvare dati persistenti | *ID, Dimensione, PathFisico* | *ID* |
| VolumeLocale | Volume allocato in un nodo | | |
| VolumeGlobale | Volume allocato in un server remoto | *IndirizzoIPServer* | |
| VolumeDistribuito | Volume allocato su più nodi | | |
| Servizio | Astrazione che rappresenta un insieme di container replicati su più nodi | *Nome, Immagine, NumeroRepliche* | *Nome* |
| Deployment | Astrazione che rappresenta un insieme di servizi rilasciati in una nuova versione dell'applicativo | *ID, Ambiente, Esito, NumeroServizi* | *ID* |

###### Tabella delle relazioni
| Relazione | Descrizione | Componente | Attributi |
|-----------|-----------|-----------|-----------|
| Sviluppo | Sviluppo servizio da parte di un developer | Developer, Servizio | |
| Associazione | Associazione tra più servizi e più deployment | Servizio, Deployment | |
| Produzione | Produzione deployment da parte di un developer | Developer, Deployment | |
| Creazione | Creazione nodo da parte di un admin | Admin, Nodo | |
| Ospitazione | Ospitazione di più container in un nodo | Nodo, Container | |
| Part-of | Container è parte di un servizio | Servizio, Container | |
| Montaggio | Associazione tra più container e più volumi | Container, Volume | *PathMontaggio, Permessi* |
| Allocazione distribuita | Allocazione volume distribuito su più nodi | VolumeDistribuito, Nodo | |
| Allocazione locale | Allocazione volume locale in un nodo | VolumeLocale, Nodo | |
| Versione precedente | Associazione deployment alla sua versione precedente | Deployment, Deployment | |
#### Ristrutturazione attributi multipli
Nello schema concettuale notiamo che nella relazione *Montaggio* è presente un attributo *permessi* che rappresenta i permessi di accesso al volume montato sul container.
Questo attributo potrebbe essere ristrutturato come tabella a parte, tuttavia in Linux i permessi vengono espressi come stringa perciò non c'è necessità di ristrutturarlo.
#### Analisi delle ridondanze
Nello schema concettuale sono presenti due ridondanze da analizzare:
- **Numero Repliche**, in *Servizio*, rappresenta il numero di container replicati su più nodi, che può essere ottenuto contando i container con lo stesso servizio.
Questo attributo viene modificato ogni volta che si vuole aumentare/diminuire il numero di repliche o quando un container viene creato o eliminato.
Lo scopo di un Orchestrator è tutelare i servizi con variazione dei requisiti molto rapida, perciò ipotizziamo uno Swarm Docker con 50 servizi attivi e 20 repliche per servizio di media, ovvero 1000 container attivi.
Sempre ipotizzando una media di 10 modifiche per ogni servizio al giorno, l'attributo **Numero Repliche** viene modificato in media 500 volte al giorno e viene visualizzato in media 20 volte al giorno per ogni servizio, ovvero 1000 volte al giorno.
  - **Operazione 1** (500 al giorno): crea o elimina nuovo container associato ad un servizio, così aumentando o diminuendo il numero di repliche
  - **Operazione 2** (1000 al giorno): visualizza il numero di repliche di un servizio

  I volumi della base di dati:
  | Entità | Costrutto | Volume |
  |:-----------:|:-----------:|:-----------:|
  | Container  | E | 1000 |
  | Servizio | E | 50  |

  - **CON RIDONDANZA**
    - Operazione 1:

      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Container  | E | 1 | S | 500|
      | Part-of  | R | 1 | S | 500|
      | Ospitazione | R | 1 | S | 500|
      | Servizio | E | 1  | L | 500|
      | Servizio | E | 1  | S | 500|

    - Operazione 2:

      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Servizio | E | 1  | L | 1000|

    Assumendo costo doppio per gli accessi in scrittura:
    $$ \text{CostoTotale}_{ConRidondanza} = (500 \cdot 2) \cdot 4 + 500 + 1000 = 5500$$

  - **SENZA RIDONDANZA**
    - Operazione 1:
      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Container  | E | 1 | S | 500|
      | Part-of  | R | 1 | S | 500|
      | Ospitazione | R | 1 | S | 500|

    - Operazione 2:

      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Servizio | E | 1  | L | 1000|
      | Part-of | R | 20 | L | 1000|
    Assumendo costo doppio per gli accessi in scrittura:
    $$ \text{CostoTotale}_{SenzaRidondanza} = (500 \cdot 2) \cdot 3 + 1000 + 1000 \cdot 20 = 24000 $$

  L'analisi suggerisce che l'attributo **Numero Repliche** è necessario, in quanto il costo totale con ridondanza è 4 volte inferiore rispetto al costo totale senza ridondanza e considerando l'alto volume di accessi sia in lettura che in scrittura risulta fondamentale mantenere l'attributo.

- **Numero Servizi**, in *Deplyment*, rappresenta il numero di servizi associati ad un deployment, che può essere ottenuto contando i servizi con lo stesso deployment.
Questo attributo non viene mai modificato dato che si preferisce crearne uno di nuovo al posto di modificarne uno già esistente per favorire il versionamento dei deployment.
Ciò accade perchè c'è una forte necessità di fare rollback in caso il deployment fallisca o abbia dei bug nell'ambiente in cui è stato fatto.
Utilizziamo le stesse ipotesi dell'analisi precedente, ovvero 50 servizi attivi e 20 repliche per servizio di media.
Inoltre consideriamo che vengono creati in media 3 deployment al giorno (dev, test e produzione) con 50 servizi per deployment, quindi in totale ipotizziamo 1000 deployment come volume.
  - **Operazione 1** (3 al giorno): memorizza un nuovo deployment associato a più servizi
  - **Operazione 2** (6 volte al giorno): visualizza il numero di servizi di un deployment prima di crearne uno nuovo e dopo averlo creato

  Come già specificato, specifichiamo i volumi della base di dati:
  | Entità | Costrutto | Volume |
  |:-----------:|:-----------:|:-----------:|
  | Deployment  | E | 1000 |
  | Servizio | E | 50 |

  - **CON RIDONDANZA**
    - Operazione 1:

      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Deployment  | E | 1 | S | 3 |
      | Associazione  | R | 1 | S | 50 |

    - Operazione 2:

      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Deployment | E | 1  | L | 6 |

    Assumendo costo doppio per gli accessi in scrittura:
    $$ \text{CostoTotale}_{ConRidondanza} = (3 \cdot 2) + (50 \cdot 2) + 6 =  112 $$

  - **SENZA RIDONDANZA**
    - Operazione 1:
      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Deployment  | E | 1 | S | 3 |
      | Associazione  | R | 1 | S | 50 |
    - Operazione 2:

      | Entità | Costrutto | Accessi | Tipo | Numero Operazioni |
      |:-----------:|:-----------:|:-----------:|:-----------:|:-----------:|
      | Deployment | E | 1 | L | 6 |
      | Servizio | E | 50 | L | 6 |
    Assumendo costo doppio per gli accessi in scrittura:
    $$ \text{CostoTotale}_{SenzaRidondanza} = (3 \cdot 2) + (50 \cdot 2) + 6 + (50\cdot6) = 412 $$

  L'analisi suggerisce che l'attributo **Numero servizi** è utile, in quanto il costo totale con ridondanze è circa 3 volte inferiore, tuttavia anche l'ipotesi di rimuoverlo sarebbe valida dato il numero di accessi è in termini assoluti molto basso.
  Noi scegliamo di mantenerlo per semplificare le query ed evitare il calcolo del numero di servizi associati ad un deployment, tuttavia è fondamentale mantenere la consistenza del numero di servizi salvato nel deployment.

#### Eliminazione delle generalizzazioni
Le generalizzazioni descritte nello schema concettuale vengono ristrutturate con l'obiettivo di eliminare le ridondanze e semplificare il modello relazionale.
Le due entità coinvolte sono:
- **Utente**: la generalizzazione di Utente in Developer e Admin è necessaria per la distinzione dei privilegi per tipo di utente, in quanto i due tipi di utente hanno relazioni totalmente diverse tra di loro, ma condividono gli stessi attributi.
Perciò si decide di partizionare l'entità *Utente* nelle specializzazioni *Developer* e *Admin* con lo scopo di mantenere i vincoli relativi ai loro ruoli, ovvero che un developer non può creare nodi e un admin non può creare servizi e deployment.
Questa scelta aumenta il numero di tabelle, ma oltre a mantenere i vincoli precedentemente descritti, riduce al minimo i valori nulli e non richiede l'aggiunta dell'attributo *Ruolo*.
- **Volume**: la generalizzazione di Volume in Volume Locale, Globale e Distribuito è necessaria per la distinzione logica dei volumi, in quanto i tre tipi di volume hanno relazioni e attributi diversi tra di loro.
Perciò si decide di partizionare l'entità *Volume* in *VolumeLocale*, *VolumeGlobale* e *VolumeDistribuito* con lo scopo di separare i volumi in base alla loro tipologia e mantenere i vincoli relativi alla loro allocazione.
Questa scelta aumenta il numero di tabelle, ma rende possibile l'implementazione di attributi e relazioni specifiche per ogni tipo di volume, inoltre riduce al minimo il numero di valori nulli.
Nel caso si fosse deciso di accorpare le tre specializzazioni in un'unica entità non sarebbe stato possibile implementare le relazioni specifiche per ogni tipo di volume, inoltre l'attributo *IndirizzoIPServer* sarebbe stato nullo per i volumi locali e distribuiti, rendendo il modello meno chiaro e meno efficiente.







![Progettazione concettuale](./assets/ER_Refurbished.jpg)
#### Schema relazionale
- **Developers**(<u>Username</u>, Password)
- **Admins**(<u>Username</u>, Password)
- **Servizi**(<u>Nome</u>, Immagine, NumeroRepliche, Developer)
  - Servizio.Developer $\to$ Utente.Username
- **Deployments**(<u>ID</u>, Ambiente, Esito, NumeroServizi, ID_Deployment_Precedente$^*$, ID_Developer)
  - Deployment.ID_Developer $\to$ Utente.Username
  - Deployment.ID_Deployment_Precedente $\to$ Deployment.ID
- **ServiziDeployed**(NomeServizio, ID_Deployment)
  - ServiziDeployed.ID_Deployment $\to$ Deployment.ID
  - ServiziDeployed.NomeServizio $\to$ Servizio.Nome
- **Nodi**(<u>Hostname</u>, IP, OS, Status, ID_Admin)
  - Nodo.ID_Admin $\to$ Utente.Username
- **Containers**(<u>Nome, NomeServizio</u>, Stato)
  - Container.NomeServizio $\to$ Servizio.Nome
- **VolumiLocali**(<u>ID</u>, Dimensione, PathFisico, ID_Nodo)
  - VolumeLocale.ID_Nodo $\to$ Nodo.Hostname
- **VolumiGlobali**(<u>ID</u>, Dimensione, PathFisico, IndirizzoIPServer)
- **VolumiDistribuiti**(<u>ID</u>, Dimensione, PathFisico)
- **VolumiLocaliContainer**(<u>ID_Volume, ID_Container, NomeServizioContainer</u>, PathMontaggio, Permessi)
  - VolumiLocaliContainer.ID_Volume $\to$ VolumeLocale.ID
  - VolumiLocaliContainer.(ID_Container, NomeServizioContainer) $\to$ Container.(Nome, NomeServizio)
- **VolumiGlobaliContainer**(<u>ID_Volume, ID_Container, NomeServizioContainer</u>, PathMontaggio, Permessi)
  - VolumiGlobaliContainer.ID_Volume $\to$ VolumeGlobale.ID
  - VolumiGlobaliContainer.(ID_Container, NomeServizioContainer) $\to$ Container.(Nome, NomeServizio)
- **VolumiDistribuitiContainer**(<u>ID_Volume, ID_Container, NomeServizioContainer</u>, PathMontaggio, Permessi)
  - VolumiDistribuitiContainer.ID_Volume $\to$ VolumeDistribuito.ID
  - VolumiDistribuitiContainer.(ID_Container, NomeServizioContainer) $\to$ Container.(Nome, NomeServizio)
- **AllocazioneDistribuita**(<u>ID_Volume, ID_Nodo</u>)
  - AllocazioneDistribuita.ID_Volume $\to$ VolumeDistribuito.ID
  - AllocazioneDistribuita.ID_Nodo $\to$ Nodo.Hostname