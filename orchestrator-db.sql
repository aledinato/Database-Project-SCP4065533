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
    developer_id VARCHAR(64) NOT NULL,
    PRIMARY KEY(nome),
    FOREIGN KEY(developer_id) REFERENCES Developers(username) ON DELETE RESTRICT
);

CREATE TABLE Deployments(
    id CHAR(32), -- adottiamo UUID4 per generare gli UUID
    esito VARCHAR(64), -- nullable
    ambiente VARCHAR(64) NOT NULL,
    num_servizi SMALLINT NOT NULL CHECK (num_servizi >= 1), -- massimo circa 32.767 servizi per deployment
    developer_id VARCHAR(64) NOT NULL,
    versione_precedente CHAR(32),
    PRIMARY KEY(id),
    FOREIGN KEY(versione_precedente) REFERENCES Deployments(id) ON DELETE SET NULL,
    FOREIGN KEY(developer_id) REFERENCES Developers(username) ON DELETE RESTRICT
);

CREATE TABLE ServiziDeployed(
    servizio_id VARCHAR(64),
    deployment_id CHAR(32),
    PRIMARY KEY(servizio_id, deployment_id),
    FOREIGN KEY(servizio_id) REFERENCES Servizi(nome) ON DELETE CASCADE,
    FOREIGN KEY(deployment_id) REFERENCES Deployments(id) ON DELETE CASCADE
);

CREATE TABLE Nodi(
    hostname VARCHAR(64),
    indirizzo_IP VARCHAR(15) NOT NULL, -- consideriamo IPV4
    stato VARCHAR(64) NOT NULL,
    sistema_operativo VARCHAR(64) NOT NULL,
    admin_id VARCHAR(64) NOT NULL,
    PRIMARY KEY(hostname),
    FOREIGN KEY(admin_id) REFERENCES Admins(username) ON DELETE RESTRICT
);

CREATE TABLE Containers(
    nome VARCHAR(64),
    stato VARCHAR(64) NOT NULL,
    nodo_id VARCHAR(64) NOT NULL,
    servizio_id VARCHAR(64) NOT NULL,
    PRIMARY KEY(nome, servizio_id),
    FOREIGN KEY(servizio_id) REFERENCES Servizi(nome) ON DELETE CASCADE,
    FOREIGN KEY(nodo_id) REFERENCES Nodi(hostname) ON DELETE CASCADE
);

CREATE TABLE VolumiLocali(
    id CHAR(32),
    dimensione INT NOT NULL CHECK (dimensione > 0),
    path_fisico VARCHAR(255) NOT NULL,
    nodo_id VARCHAR(64) NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(nodo_id) REFERENCES Nodi(hostname) ON DELETE CASCADE
);

CREATE TABLE VolumiGlobali(
    id CHAR(32),
    dimensione INT NOT NULL CHECK (dimensione > 0),
    path_fisico VARCHAR(255) NOT NULL,
    indirizzo_IP_server VARCHAR(15) NOT NULL, -- consideriamo IPV4
    PRIMARY KEY(id)
);

CREATE TABLE VolumiDistribuiti(
    id CHAR(32),
    dimensione INT NOT NULL CHECK (dimensione > 0),
    path_fisico VARCHAR(255) NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE MontaggiLocali(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi VARCHAR(10) NOT NULL,
    container_nome VARCHAR(64),
    container_servizio_id VARCHAR(64),
    volume_id CHAR(32),
    PRIMARY KEY(container_nome, container_servizio_id, volume_id),
    FOREIGN KEY(container_nome, container_servizio_id) REFERENCES Containers(nome, servizio_id) ON DELETE CASCADE,
    FOREIGN KEY(volume_id) REFERENCES VolumiLocali(id) ON DELETE CASCADE
);

CREATE TABLE MontaggiGlobali(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi VARCHAR(10) NOT NULL,
    container_nome VARCHAR(64),
    container_servizio_id VARCHAR(64),
    volume_id CHAR(32),
    PRIMARY KEY(container_nome, container_servizio_id, volume_id),
    FOREIGN KEY(container_nome, container_servizio_id) REFERENCES Containers(nome, servizio_id) ON DELETE CASCADE,
    FOREIGN KEY(volume_id) REFERENCES VolumiGlobali(id) ON DELETE CASCADE
);

CREATE TABLE MontaggiDistribuiti(
    path_montaggio VARCHAR(255) NOT NULL,
    permessi VARCHAR(10) NOT NULL,
    container_nome VARCHAR(64),
    container_servizio_id VARCHAR(64),
    volume_id CHAR(32),
    PRIMARY KEY(container_nome, container_servizio_id, volume_id),
    FOREIGN KEY(container_nome, container_servizio_id) REFERENCES Containers(nome, servizio_id) ON DELETE CASCADE,
    FOREIGN KEY(volume_id) REFERENCES VolumiDistribuiti(id) ON DELETE CASCADE
);

CREATE TABLE AllocazioniDistribuite(
    nodo_id VARCHAR(64),
    volume_id CHAR(32),
    PRIMARY KEY(nodo_id, volume_id),
    FOREIGN KEY(volume_id) REFERENCES VolumiDistribuiti(id) ON DELETE CASCADE,
    FOREIGN KEY(nodo_id) REFERENCES Nodi(hostname) ON DELETE CASCADE
);

-- TO DO:
-- 1) CHECK on the specific constraint for node and volumes
-- 2) TRIGGER on nServizi e nRepliche

-- aggiorna il numero di repliche del Servizio associato al Container aggiunto
CREATE FUNCTION aggiorna_num_repliche()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Servizi
    SET num_repliche = (
        SELECT COUNT(*)
        FROM Containers
        WHERE Containers.servizio_id = NEW.servizio_id
    )
    WHERE nome = NEW.servizio_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dopo_creazione_container
AFTER INSERT OR DELETE ON Containers
FOR EACH ROW
EXECUTE FUNCTION aggiorna_num_repliche();

CREATE FUNCTION aggiorna_num_servizi()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Deployments
    SET num_servizi = (
        SELECT COUNT(*)
        FROM ServiziDeployed
        WHERE deployment_id = NEW.deployment_id
    )
    WHERE id = NEW.deployment_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dopo_creazione_servizioDeployed
AFTER INSERT OR DELETE ON ServiziDeployed
FOR EACH ROW
EXECUTE FUNCTION aggiorna_num_servizi();

CREATE FUNCTION controllo_allocazione_stesso_nodo_locale()
RETURNS TRIGGER AS $$
DECLARE
    volume_nodo_id VARCHAR(64);
    container_nodo_id VARCHAR(64);
BEGIN
    SELECT nodo_id INTO container_nodo_id
    FROM Containers
    WHERE nome = NEW.container_nome AND servizio_id = NEW.container_servizio_id;

    SELECT nodo_id INTO volume_nodo_id
    FROM VolumiLocali
    WHERE VolumiLocali.id = NEW.volume_id;

    IF container_nodo_id IS NULL OR volume_nodo_id IS NULL OR container_nodo_id != volume_nodo_id THEN
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
    container_nodo_id VARCHAR(64);
BEGIN
    SELECT nodo_id INTO container_nodo_id
    FROM Containers
    WHERE nome = NEW.container_nome AND servizio_id = NEW.container_servizio_id;

    IF NOT EXISTS (
        SELECT *
        FROM AllocazioniDistribuite
        WHERE AllocazioniDistribuite.nodo_id = container_nodo_id AND volume_id = NEW.volume_id
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

INSERT INTO Servizi (nome, immagine, num_repliche, developer_id) VALUES
('servizio-autenticazione', 'autenticazione:v1.0', 3, 'giulia_dev'),
('servizio-fatturazione', 'fatturazione:v2.1', 1, 'marco_dev');

INSERT INTO Nodi (hostname, indirizzo_IP, stato, sistema_operativo, admin_id) VALUES
('nodo-1', '192.168.0.10', 'attivo', 'Ubuntu 22.04', 'luca_admin'),
('nodo-2', '192.168.0.11', 'attivo', 'Debian 12', 'elena_admin');

INSERT INTO Containers (nome, stato, nodo_id, servizio_id) VALUES
('contenitore-auth-1', 'in esecuzione', 'nodo-1', 'servizio-autenticazione'),
('contenitore-auth-2', 'in esecuzione', 'nodo-1', 'servizio-autenticazione'),
('contenitore-auth-3', 'in esecuzione', 'nodo-2', 'servizio-autenticazione'),
('contenitore-fatt-1', 'in esecuzione', 'nodo-2', 'servizio-fatturazione');

INSERT INTO Deployments (id, esito, ambiente, num_servizi, developer_id, versione_precedente) VALUES
('deploy-001', 'successo', 'produzione', 1, 'giulia_dev', NULL),
('deploy-002', NULL, 'test', 2, 'marco_dev', 'deploy-001');

INSERT INTO ServiziDeployed (servizio_id, deployment_id) VALUES
('servizio-autenticazione', 'deploy-001'),
('servizio-autenticazione', 'deploy-002'),
('servizio-fatturazione', 'deploy-002');

INSERT INTO VolumiLocali (id, dimensione, path_fisico, nodo_id) VALUES
('vol-loc-001', 10240, '/mnt/dati/auth', 'nodo-1'),
('vol-loc-002', 20480, '/mnt/dati/fatt', 'nodo-2');

INSERT INTO MontaggiLocali (path_montaggio, permessi, container_nome, container_servizio_id, volume_id) VALUES
('/app/dati', 'rw', 'contenitore-auth-1', 'servizio-autenticazione', 'vol-loc-001'),
('/app/fatture', 'rw', 'contenitore-fatt-1', 'servizio-fatturazione', 'vol-loc-002');

INSERT INTO VolumiGlobali (id, dimensione, path_fisico, indirizzo_IP_server) VALUES
('vol-glob-001', 51200, '/srv/globali/auth', '10.10.0.1');

INSERT INTO MontaggiGlobali (path_montaggio, permessi, container_nome, container_servizio_id, volume_id) VALUES
('/condiviso/auth', 'rw', 'contenitore-auth-1', 'servizio-autenticazione', 'vol-glob-001');

INSERT INTO VolumiDistribuiti (id, dimensione, path_fisico) VALUES
('vol-dist-001', 40960, '/srv/distribuiti/fatturazione');

INSERT INTO AllocazioniDistribuite (nodo_id, volume_id) VALUES
('nodo-2', 'vol-dist-001');

INSERT INTO MontaggiDistribuiti (path_montaggio, permessi, container_nome, container_servizio_id, volume_id) VALUES
('/distribuiti/fatt', 'rw', 'contenitore-fatt-1', 'servizio-fatturazione', 'vol-dist-001');
