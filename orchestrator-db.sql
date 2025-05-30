---- TABELLE ----

DROP TABLE IF EXISTS MontaggiDistribuiti CASCADE;
DROP TABLE IF EXISTS MontaggiGlobali CASCADE;
DROP TABLE IF EXISTS MontaggiLocali CASCADE;
DROP TABLE IF EXISTS AllocazioniDistribuite CASCADE;
DROP TABLE IF EXISTS VolumiDistribuiti CASCADE;
DROP TABLE IF EXISTS VolumiGlobali CASCADE;
DROP TABLE IF EXISTS VolumiLocali CASCADE;
DROP TABLE IF EXISTS Containers CASCADE;
DROP TABLE IF EXISTS Nodi CASCADE;
DROP TABLE IF EXISTS ServiziDeployed CASCADE;
DROP TABLE IF EXISTS Deployments CASCADE;
DROP TABLE IF EXISTS Servizi CASCADE;
DROP TABLE IF EXISTS Admins CASCADE;
DROP TABLE IF EXISTS Developers CASCADE;

CREATE TABLE Developers(
    username VARCHAR(64),
    password CHAR(60) NOT NULL, -- lunghezza hash bcrypt
    anzianita VARCHAR(64) NOT NULL,
    PRIMARY KEY(username)
);

CREATE TABLE Admins(
    username VARCHAR(64),
    password CHAR(60) NOT NULL, -- lunghezza hash bcrypt
    PRIMARY KEY(username)
);

CREATE TABLE Servizi(
    nome VARCHAR(64),
    immagine VARCHAR(64) NOT NULL,
    num_repliche SMALLINT NOT NULL CHECK (num_repliche >= 1), -- massimo circa 32.767 repliche per servizio
    username_developer VARCHAR(64) NOT NULL,
    PRIMARY KEY(nome),
    FOREIGN KEY(username_developer) REFERENCES Developers(username) ON DELETE RESTRICT -- prima di eliminare un developer bisogna fare pulizia dei servizi(manualmente) per evitare danni involontari
);

CREATE TABLE Deployments(
    nome VARCHAR(64),
    esito VARCHAR(64) NOT NULL,
    ambiente VARCHAR(64) NOT NULL,
    num_servizi SMALLINT NOT NULL CHECK (num_servizi >= 1), -- massimo circa 32.767 servizi per deployment
    username_developer VARCHAR(64) NOT NULL,
    nome_versione_precedente VARCHAR(64),
    ambiente_versione_precedente VARCHAR(64),
    PRIMARY KEY(nome, ambiente),
    FOREIGN KEY(nome_versione_precedente, ambiente_versione_precedente) REFERENCES Deployments(nome, ambiente) ON DELETE SET NULL,
    FOREIGN KEY(username_developer) REFERENCES Developers(username) ON DELETE RESTRICT
);

CREATE TABLE ServiziDeployed(
    nome_servizio VARCHAR(64),
    nome_deployment VARCHAR(64),
    ambiente_deployment VARCHAR(64),
    PRIMARY KEY(nome_servizio, nome_deployment, ambiente_deployment),
    FOREIGN KEY(nome_servizio) REFERENCES Servizi(nome) ON DELETE CASCADE,
    FOREIGN KEY(nome_deployment, ambiente_deployment) REFERENCES Deployments(nome, ambiente) ON DELETE CASCADE
);

CREATE TABLE Nodi(
    hostname VARCHAR(64),
    indirizzo_IP VARCHAR(15) NOT NULL, -- consideriamo IPV4
    stato VARCHAR(64) NOT NULL,
    sistema_operativo VARCHAR(64) NOT NULL,
    username_admin VARCHAR(64) NOT NULL,
    PRIMARY KEY(hostname),
    FOREIGN KEY(username_admin) REFERENCES Admins(username) ON DELETE RESTRICT
);

CREATE TABLE Containers(
    nome VARCHAR(64),
    stato VARCHAR(64) NOT NULL,
    hostname_nodo VARCHAR(64) NOT NULL,
    nome_servizio VARCHAR(64) NOT NULL,
    PRIMARY KEY(nome, nome_servizio),
    FOREIGN KEY(nome_servizio) REFERENCES Servizi(nome) ON DELETE CASCADE,
    FOREIGN KEY(hostname_nodo) REFERENCES Nodi(hostname) ON DELETE RESTRICT
);

CREATE TABLE VolumiLocali(
    nome VARCHAR(64),
    dimensione INT NOT NULL CHECK (dimensione > 0),
    path_fisico VARCHAR(255) NOT NULL,
    hostname_nodo VARCHAR(64) NOT NULL,
    PRIMARY KEY(nome),
    FOREIGN KEY(hostname_nodo) REFERENCES Nodi(hostname) ON DELETE CASCADE
);

CREATE TABLE VolumiGlobali(
    nome VARCHAR(64),
    dimensione INT NOT NULL CHECK (dimensione > 0),
    path_fisico VARCHAR(255) NOT NULL,
    indirizzo_IP_server VARCHAR(15) NOT NULL, -- consideriamo IPV4
    PRIMARY KEY(nome)
);

CREATE TABLE VolumiDistribuiti(
    nome VARCHAR(64),
    dimensione INT NOT NULL CHECK (dimensione > 0),
    path_fisico VARCHAR(255) NOT NULL,
    PRIMARY KEY(nome)
);

CREATE TABLE MontaggiLocali(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi CHAR(3) NOT NULL, -- esempio r-- unix-like
    container_nome VARCHAR(64),
    container_nome_servizio VARCHAR(64),
    nome_volume VARCHAR(64),
    PRIMARY KEY(container_nome, container_nome_servizio, nome_volume),
    FOREIGN KEY(container_nome, container_nome_servizio) REFERENCES Containers(nome, nome_servizio) ON DELETE CASCADE,
    FOREIGN KEY(nome_volume) REFERENCES VolumiLocali(nome) ON DELETE CASCADE
);

CREATE TABLE MontaggiGlobali(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi CHAR(3) NOT NULL,
    container_nome VARCHAR(64),
    container_nome_servizio VARCHAR(64),
    nome_volume VARCHAR(64),
    PRIMARY KEY(container_nome, container_nome_servizio, nome_volume),
    FOREIGN KEY(container_nome, container_nome_servizio) REFERENCES Containers(nome, nome_servizio) ON DELETE CASCADE,
    FOREIGN KEY(nome_volume) REFERENCES VolumiGlobali(nome) ON DELETE CASCADE
);

CREATE TABLE MontaggiDistribuiti(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi CHAR(3) NOT NULL,
    container_nome VARCHAR(64),
    container_nome_servizio VARCHAR(64),
    nome_volume VARCHAR(64),
    PRIMARY KEY(container_nome, container_nome_servizio, nome_volume),
    FOREIGN KEY(container_nome, container_nome_servizio) REFERENCES Containers(nome, nome_servizio) ON DELETE CASCADE,
    FOREIGN KEY(nome_volume) REFERENCES VolumiDistribuiti(nome) ON DELETE CASCADE
);

CREATE TABLE AllocazioniDistribuite(
    hostname_nodo VARCHAR(64),
    nome_volume VARCHAR(64),
    PRIMARY KEY(hostname_nodo, nome_volume),
    FOREIGN KEY(nome_volume) REFERENCES VolumiDistribuiti(nome) ON DELETE CASCADE,
    FOREIGN KEY(hostname_nodo) REFERENCES Nodi(hostname) ON DELETE CASCADE
);

---- INDICI ----

DROP INDEX IF EXISTS AnzianitaDevelopers;
DROP INDEX IF EXISTS EsitoDeployments;
DROP INDEX IF EXISTS NumReplicheServizi;

---- Ottimizzazione query 1 ----
CREATE INDEX NumReplicheServizi
ON Servizi ( num_repliche );

---- Ottimizzazioni query 2 ----
CREATE INDEX AnzianitaDevelopers
ON Developers
USING HASH ( anzianita );

CREATE INDEX EsitoDeployments
ON Deployments
USING HASH ( esito );


---- INSERT ----

INSERT INTO Developers (username, anzianita,password) VALUES
('giulia_dev', 'senior', 'bcrypt_hash_pw1'),
('marco_dev', 'senior', 'bcrypt_hash_pw2'),
('alessandro_dev', 'junior', 'bcrypt_hash_pw3'),
('filippo_dev', 'senior', 'bcypt_hash_pw4');

INSERT INTO Admins (username, password) VALUES
('luca_admin', 'bcrypt_hash_pw5'),
('elena_admin', 'bcrypt_hash_pw6'),
('matteo_admin', 'bcrypt_hash_pw7'),
('davide_admin', 'bcrypt_hash_pw8');

INSERT INTO Servizi (nome, immagine, num_repliche, username_developer) VALUES
('servizio-autenticazione', 'autenticazione:v1.0', 3, 'giulia_dev'),
('servizio-fatturazione', 'fatturazione:v2.1', 2, 'marco_dev'),
('servizio-cors', 'cors:v4.2', 3, 'marco_dev'),
('servizio-proxy', 'proxy:v8.8', 2, 'giulia_dev'),
('servizio-cert-http', 'certbot:v3.0.9', 2, 'marco_dev'),
('servizio-scheduling', 'scheduler:v4.5', 6, 'marco_dev'),
('servizio-cache', 'redis:latest', 2, 'alessandro_dev'),
('servizio-nginx', 'nginx:latest', 2, 'alessandro_dev'),
('servizio-storage', 's3:latest', 2, 'alessandro_dev'),
('servizio-database', 'mongodb:latest', 3, 'alessandro_dev'),
('servizio-notification', 'notification:2.1', 2, 'filippo_dev'),
('servizio-nextjs', 'nextjs:latest', 2, 'filippo_dev');

INSERT INTO Nodi (hostname, indirizzo_IP, stato, sistema_operativo, username_admin) VALUES
('nodo-1', '192.168.0.10', 'Ready', 'Ubuntu 22.04', 'luca_admin'),
('nodo-2', '192.168.0.11', 'Ready', 'Debian 12', 'elena_admin'),
('nodo-3', '192.168.0.12', 'Down', 'Kali Linux 2024.1', 'matteo_admin'),
('nodo-4', '192.168.0.14', 'Ready', 'Arch Linux 6.14.4', 'matteo_admin'),
('nodo-5', '192.168.0.15', 'Ready', 'Linux Mint 22.4', 'davide_admin'),
('nodo-251', '192.168.0.251', 'Drain', 'Windows Server 2012', 'luca_admin'),
('nodo-252', '192.168.0.252', 'Drain', 'Windows Server 2012', 'luca_admin');

INSERT INTO Containers (nome, stato, hostname_nodo, nome_servizio) VALUES
('container-auth-1', 'running', 'nodo-1', 'servizio-autenticazione'),
('container-auth-2', 'running', 'nodo-1', 'servizio-autenticazione'),
('container-auth-3', 'running', 'nodo-2', 'servizio-autenticazione'),
('container-fatt-1', 'running', 'nodo-2', 'servizio-fatturazione'),
('container-fatt-2', 'created', 'nodo-2', 'servizio-fatturazione'),
('container-cors-1', 'running', 'nodo-3', 'servizio-cors'),
('container-cors-2', 'running', 'nodo-1', 'servizio-cors'),
('container-cors-3', 'running', 'nodo-4', 'servizio-cors'),
('container-proxy', 'running', 'nodo-2', 'servizio-proxy'),
('container-reserve-proxy', 'paused', 'nodo-3', 'servizio-proxy'),
('container-certbot-1', 'running', 'nodo-5', 'servizio-cert-http'),
('container-certbot-2', 'dead', 'nodo-251', 'servizio-cert-http'),
('container-scheduler-1', 'running', 'nodo-1', 'servizio-scheduling'),
('container-scheduler-2', 'running', 'nodo-2', 'servizio-scheduling'),
('container-scheduler-3', 'running', 'nodo-3', 'servizio-scheduling'),
('container-scheduler-4', 'running', 'nodo-4', 'servizio-scheduling'),
('container-scheduler-5', 'running', 'nodo-5', 'servizio-scheduling'),
('container-scheduler-windows', 'dead', 'nodo-252', 'servizio-scheduling'),
('container-cache', 'running', 'nodo-1', 'servizio-cache'),
('container-cache-2', 'running', 'nodo-2', 'servizio-cache'),
('container-nginx', 'stopped', 'nodo-1', 'servizio-nginx'),
('container-nginx-2', 'stopped', 'nodo-3', 'servizio-nginx'),
('container-storage', 'running', 'nodo-4', 'servizio-storage'),
('container-storage-2', 'running', 'nodo-5', 'servizio-storage'),
('container-mongodb', 'running', 'nodo-1','servizio-database'),
('container-mongodb-2', 'running', 'nodo-2','servizio-database'),
('container-mongodb-3', 'running', 'nodo-3','servizio-database'),
('container-notification', 'stopped', 'nodo-5','servizio-notification'),
('container-notification-2', 'stopped', 'nodo-5','servizio-notification'),
('container-nextjs', 'running', 'nodo-3','servizio-nextjs'),
('container-nextjs-2', 'running', 'nodo-4','servizio-nextjs');

INSERT INTO Deployments (nome, esito, ambiente, num_servizi, username_developer, nome_versione_precedente, ambiente_versione_precedente) VALUES
('deploy-001', 'success', 'sviluppo', 1, 'giulia_dev', NULL, NULL),
('deploy-001', 'failed', 'test', 2, 'filippo_dev', 'deploy-001', 'sviluppo'),
('deploy-002', 'failed', 'test', 4, 'filippo_dev', 'deploy-001', 'test'),
('deploy-master-v1', 'success', 'produzione', 1, 'alessandro_dev', 'deploy-002', 'test'),
('deploy-002', 'success', 'sviluppo', 1, 'alessandro_dev', 'deploy-master-v1', 'produzione'),
('deploy-003', 'success', 'sviluppo', 1, 'giulia_dev', 'deploy-002', 'sviluppo'),
('deploy-003', 'success', 'test', 1, 'giulia_dev', 'deploy-003', 'sviluppo'),
('deploy-004', 'failed', 'test', 3, 'filippo_dev', 'deploy-003', 'test'),
('deploy-master-v2', 'failed', 'produzione', 1, 'marco_dev', 'deploy-004', 'test'),
('deploy-004', 'failed', 'sviluppo', 1, 'alessandro_dev', 'deploy-master-v2', 'produzione'),
('deploy-005', 'running', 'sviluppo', 1, 'alessandro_dev', 'deploy-004', 'sviluppo');

INSERT INTO ServiziDeployed (nome_servizio, nome_deployment, ambiente_deployment) VALUES
('servizio-autenticazione', 'deploy-001', 'sviluppo'),
('servizio-autenticazione', 'deploy-002', 'test'),
('servizio-fatturazione', 'deploy-002', 'test'),
('servizio-cors', 'deploy-002', 'test'),
('servizio-cert-http', 'deploy-002', 'test'),
('servizio-nextjs', 'deploy-004', 'test'),
('servizio-notification', 'deploy-004', 'sviluppo');

INSERT INTO VolumiLocali (nome, dimensione, path_fisico, hostname_nodo) VALUES
('vol-loc-001', 10240, '/mnt/dati/auth', 'nodo-1'),
('vol-loc-002', 20480, '/mnt/dati/fatt', 'nodo-2'),
('vol-loc-004', 16384, '/mnt/dati/proxy', 'nodo-2'),
('vol-loc-005', 8192, '/mnt/dati/cache', 'nodo-1'),
('vol-loc-006', 10240, '/mnt/dati/nginx', 'nodo-3'),
('vol-loc-007', 20480, '/mnt/dati/storage', 'nodo-4');

INSERT INTO MontaggiLocali (path_montaggio, permessi, container_nome, container_nome_servizio, nome_volume) VALUES
('/app/dati', 'r--', 'container-auth-1', 'servizio-autenticazione', 'vol-loc-001'),
('/app/fatture', 'r--', 'container-fatt-1', 'servizio-fatturazione', 'vol-loc-002'),
('/app/proxy', 'r--', 'container-proxy', 'servizio-proxy', 'vol-loc-004'),
('/app/cache', 'rw-', 'container-cache', 'servizio-cache', 'vol-loc-005'),
('/app/nginx', 'r--', 'container-nginx-2', 'servizio-nginx', 'vol-loc-006'),
('/app/storage', 'r-x', 'container-storage', 'servizio-storage', 'vol-loc-007');

INSERT INTO VolumiGlobali (nome, dimensione, path_fisico, indirizzo_IP_server) VALUES
('vol-glob-001', 51200, '/srv/globali/auth', '10.10.0.1'),
('vol-glob-003', 61440, '/srv/globali/scheduling', '10.10.0.3'),
('vol-glob-004', 32768, '/srv/globali/cache', '10.10.0.4'),
('vol-glob-005', 20480, '/srv/globali/nginx', '10.10.0.5'),
('vol-glob-006', 10240, '/srv/globali/storage', '10.10.0.6');

INSERT INTO MontaggiGlobali (path_montaggio, permessi, container_nome, container_nome_servizio, nome_volume) VALUES
('/condiviso/auth', 'r--', 'container-auth-1', 'servizio-autenticazione', 'vol-glob-001'),
('/condiviso/scheduler', 'rw-', 'container-scheduler-1', 'servizio-scheduling', 'vol-glob-003'),
('/condiviso/cache', 'rw-', 'container-cache', 'servizio-cache', 'vol-glob-004'),
('/condiviso/nginx', 'r--', 'container-nginx', 'servizio-nginx', 'vol-glob-005'),
('/condiviso/storage', '--x', 'container-storage', 'servizio-storage', 'vol-glob-006');

INSERT INTO VolumiDistribuiti (nome, dimensione, path_fisico) VALUES
('vol-dist-001', 40960, '/srv/distribuiti/fatturazione'),
('vol-dist-003', 30720, '/srv/distribuiti/cache'),
('vol-dist-004', 25600, '/srv/distribuiti/nginx'),
('vol-dist-005', 51200, '/srv/distribuiti/database'),
('vol-dist-006', 40960, '/srv/distribuiti/nextjs');

INSERT INTO AllocazioniDistribuite (hostname_nodo, nome_volume) VALUES
('nodo-2', 'vol-dist-001'),
('nodo-1', 'vol-dist-003'),
('nodo-1', 'vol-dist-004'),
('nodo-1', 'vol-dist-005'),
('nodo-3', 'vol-dist-006');

INSERT INTO MontaggiDistribuiti (path_montaggio, permessi, container_nome, container_nome_servizio, nome_volume) VALUES
('/distribuiti/fatt', 'r--', 'container-fatt-1', 'servizio-fatturazione', 'vol-dist-001'),
('/distribuiti/cache', 'rw-', 'container-cache', 'servizio-cache', 'vol-dist-003'),
('/distribuiti/nginx', 'rw-', 'container-nginx', 'servizio-nginx', 'vol-dist-004'),
('/distribuiti/database', 'rw-', 'container-mongodb', 'servizio-database', 'vol-dist-005'),
('/distribuiti/nextjs', 'rw-', 'container-mongodb-3', 'servizio-database', 'vol-dist-006');

-- QUERY
-- 1)
SELECT s.username_developer AS username_developer, 
COUNT(DISTINCT sd.ambiente_deployment) AS num_ambienti
FROM ServiziDeployed sd
JOIN Servizi s ON sd.nome_servizio = s.nome
WHERE s.num_repliche >= 2
GROUP BY s.username_developer
HAVING COUNT(DISTINCT sd.ambiente_deployment) >= 2;

-- 2)
SELECT dep.username_developer, COUNT(*) AS num_failed_deployments, 
ROUND(AVG(num_servizi), 2) AS media_servizi_deployed
FROM Deployments dep
JOIN Developers dev  
ON dep.username_developer = dev.username
WHERE dev.anzianita = 'senior' AND dep.esito = 'failed'
GROUP BY dep.username_developer
HAVING AVG(dep.num_servizi) > 2
ORDER BY COUNT(*) DESC, AVG(dep.num_servizi) DESC;

-- 3)
CREATE VIEW Montaggi AS
SELECT MontaggiLocali.*, VolumiLocali.dimensione
FROM MontaggiLocali
JOIN VolumiLocali ON VolumiLocali.nome = MontaggiLocali.nome_volume
UNION ALL
SELECT MontaggiGlobali.*, VolumiGlobali.dimensione
FROM MontaggiGlobali
JOIN VolumiGlobali ON VolumiGlobali.nome = MontaggiGlobali.nome_volume
UNION ALL
SELECT MontaggiDistribuiti.*, VolumiDistribuiti.dimensione
FROM MontaggiDistribuiti
JOIN VolumiDistribuiti ON VolumiDistribuiti.nome = MontaggiDistribuiti.nome_volume;

SELECT container_nome, container_nome_servizio, 
SUM(dimensione) AS spazio_volumi_totale, 
MIN(dimensione) AS spazio_volume_minimo
FROM Montaggi
GROUP BY container_nome, container_nome_servizio
ORDER BY spazio_volumi_totale ASC, spazio_volume_minimo ASC;

-- 4)
CREATE VIEW VolumiInLetturaPerContainer AS
SELECT container_nome, container_nome_servizio, COUNT(*) AS num_volumi_lettura
FROM Montaggi
WHERE permessi = 'r--'
GROUP BY container_nome, container_nome_servizio;

CREATE VIEW VolumiPerContainer AS
SELECT container_nome, container_nome_servizio, COUNT(*) AS num_volumi
FROM Montaggi
GROUP BY container_nome, container_nome_servizio;

SELECT vpc.container_nome, vpc.container_nome_servizio, vlpc.num_volumi_lettura, vpc.num_volumi
FROM VolumiPerContainer vpc
JOIN VolumiInLetturaPerContainer vlpc
ON vlpc.container_nome = vpc.container_nome
AND vlpc.container_nome_servizio = vpc.container_nome_servizio
WHERE vlpc.num_volumi_lettura = vpc.num_volumi;

-- 5)
SELECT Containers.hostname_nodo, 
COUNT(DISTINCT nome_servizio) AS num_servizi, Nodi.username_admin
FROM Containers
JOIN Nodi ON Nodi.hostname = Containers.hostname_nodo
GROUP BY Containers.hostname_nodo, Nodi.username_admin
HAVING COUNT(DISTINCT nome_servizio) >= ALL(
    SELECT COUNT(DISTINCT nome_servizio)
    FROM Containers
    GROUP BY Containers.hostname_nodo
)
ORDER BY Containers.hostname_nodo ASC, Nodi.username_admin ASC;
