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
    FOREIGN KEY(username_developer) REFERENCES Developers(username) ON DELETE RESTRICT
);

CREATE TABLE Deployments(
    nome VARCHAR(64),
    esito VARCHAR(64), -- nullable
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
    FOREIGN KEY(hostname_nodo) REFERENCES Nodi(hostname) ON DELETE CASCADE
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
    permessi VARCHAR(10) NOT NULL,
    container_nome VARCHAR(64),
    container_nome_servizio VARCHAR(64),
    nome_volume VARCHAR(64),
    PRIMARY KEY(container_nome, container_nome_servizio, nome_volume),
    FOREIGN KEY(container_nome, container_nome_servizio) REFERENCES Containers(nome, nome_servizio) ON DELETE CASCADE,
    FOREIGN KEY(nome_volume) REFERENCES VolumiLocali(nome) ON DELETE CASCADE
);

CREATE TABLE MontaggiGlobali(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi VARCHAR(10) NOT NULL,
    container_nome VARCHAR(64),
    container_nome_servizio VARCHAR(64),
    nome_volume VARCHAR(64),
    PRIMARY KEY(container_nome, container_nome_servizio, nome_volume),
    FOREIGN KEY(container_nome, container_nome_servizio) REFERENCES Containers(nome, nome_servizio) ON DELETE CASCADE,
    FOREIGN KEY(nome_volume) REFERENCES VolumiGlobali(nome) ON DELETE CASCADE
);

CREATE TABLE MontaggiDistribuiti(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi VARCHAR(10) NOT NULL,
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

CREATE FUNCTION controllo_allocazione_stesso_nodo_locale()
RETURNS TRIGGER AS $$
DECLARE
    volume_hostname_nodo VARCHAR(64);
    container_hostname_nodo VARCHAR(64);
BEGIN
    SELECT hostname_nodo INTO container_hostname_nodo
    FROM Containers
    WHERE nome = NEW.container_nome AND nome_servizio = NEW.container_nome_servizio;

    SELECT hostname_nodo INTO volume_hostname_nodo
    FROM VolumiLocali
    WHERE VolumiLocali.nome = NEW.nome_volume;

    IF container_hostname_nodo IS NULL OR volume_hostname_nodo IS NULL OR container_hostname_nodo != volume_hostname_nodo THEN
        RAISE EXCEPTION 'Volume locale e container devono essere allocati sullo stesso nodo.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER controllo_allocazione_volume_locale
BEFORE INSERT ON MontaggiLocali
FOR EACH ROW
EXECUTE FUNCTION controllo_allocazione_stesso_nodo_locale();

CREATE FUNCTION controllo_allocazione_stesso_nodo_distribuito()
RETURNS TRIGGER AS $$
DECLARE
    container_hostname_nodo VARCHAR(64);
BEGIN
    SELECT hostname_nodo INTO container_hostname_nodo
    FROM Containers
    WHERE nome = NEW.container_nome AND nome_servizio = NEW.container_nome_servizio;

    IF NOT EXISTS (
        SELECT *
        FROM AllocazioniDistribuite
        WHERE AllocazioniDistribuite.hostname_nodo = container_hostname_nodo AND nome_volume = NEW.nome_volume
    ) THEN
        RAISE EXCEPTION 'Volume distribuito e container devono essere allocati sullo stesso nodo.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER controllo_allocazione_volume_distribuito
BEFORE INSERT ON MontaggiDistribuiti
FOR EACH ROW
EXECUTE FUNCTION controllo_allocazione_stesso_nodo_distribuito();

INSERT INTO Developers (username, password) VALUES
('giulia_dev', 'bcrypt_hash_pw1'),
('marco_dev', 'bcrypt_hash_pw2');

INSERT INTO Admins (username, password) VALUES
('luca_admin', 'bcrypt_hash_pw3'),
('elena_admin', 'bcrypt_hash_pw4');

INSERT INTO Servizi (nome, immagine, num_repliche, username_developer) VALUES
('servizio-autenticazione', 'autenticazione:v1.0', 3, 'giulia_dev'),
('servizio-fatturazione', 'fatturazione:v2.1', 1, 'marco_dev');

INSERT INTO Nodi (hostname, indirizzo_IP, stato, sistema_operativo, username_admin) VALUES
('nodo-1', '192.168.0.10', 'attivo', 'Ubuntu 22.04', 'luca_admin'),
('nodo-2', '192.168.0.11', 'attivo', 'Debian 12', 'elena_admin');

INSERT INTO Containers (nome, stato, hostname_nodo, nome_servizio) VALUES
('contenitore-auth-1', 'in esecuzione', 'nodo-1', 'servizio-autenticazione'),
('contenitore-auth-2', 'in esecuzione', 'nodo-1', 'servizio-autenticazione'),
('contenitore-auth-3', 'in esecuzione', 'nodo-2', 'servizio-autenticazione'),
('contenitore-fatt-1', 'in esecuzione', 'nodo-2', 'servizio-fatturazione');

INSERT INTO Deployments (nome, esito, ambiente, num_servizi, username_developer, nome_versione_precedente, ambiente_versione_precedente) VALUES
('deploy-001', 'successo', 'produzione', 1, 'giulia_dev', NULL, NULL),
('deploy-002', NULL, 'test', 2, 'marco_dev', 'deploy-001', 'produzione');

INSERT INTO ServiziDeployed (nome_servizio, nome_deployment, ambiente_deployment) VALUES
('servizio-autenticazione', 'deploy-001', 'produzione'),
('servizio-autenticazione', 'deploy-002', 'test'),
('servizio-fatturazione', 'deploy-002', 'test');

INSERT INTO VolumiLocali (nome, dimensione, path_fisico, hostname_nodo) VALUES
('vol-loc-001', 10240, '/mnt/dati/auth', 'nodo-1'),
('vol-loc-002', 20480, '/mnt/dati/fatt', 'nodo-2');

INSERT INTO MontaggiLocali (path_montaggio, permessi, container_nome, container_nome_servizio, nome_volume) VALUES
('/app/dati', 'rw', 'contenitore-auth-1', 'servizio-autenticazione', 'vol-loc-001'),
('/app/fatture', 'rw', 'contenitore-fatt-1', 'servizio-fatturazione', 'vol-loc-002');

INSERT INTO VolumiGlobali (nome, dimensione, path_fisico, indirizzo_IP_server) VALUES
('vol-glob-001', 51200, '/srv/globali/auth', '10.10.0.1');

INSERT INTO MontaggiGlobali (path_montaggio, permessi, container_nome, container_nome_servizio, nome_volume) VALUES
('/condiviso/auth', 'rw', 'contenitore-auth-1', 'servizio-autenticazione', 'vol-glob-001');

INSERT INTO VolumiDistribuiti (nome, dimensione, path_fisico) VALUES
('vol-dist-001', 40960, '/srv/distribuiti/fatturazione');

INSERT INTO AllocazioniDistribuite (hostname_nodo, nome_volume) VALUES
('nodo-2', 'vol-dist-001');

INSERT INTO MontaggiDistribuiti (path_montaggio, permessi, container_nome, container_nome_servizio, nome_volume) VALUES
('/distribuiti/fatt', 'rw', 'contenitore-fatt-1', 'servizio-fatturazione', 'vol-dist-001');
