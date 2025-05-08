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
    nRepliche SMALLINT UNSIGNED NOT NULL CHECK (nRepliche >= 1), -- massimo 65.535 repliche per servizio
    developer_id VARCHAR(64) NOT NULL,
    PRIMARY KEY(nome),
    FOREIGN KEY(developer_id) REFERENCES Developers(username) ON DELETE RESTRICT
);

CREATE TABLE Deployments(
    id CHAR(32), -- adottiamo UUID4 per generare gli UUID
    esito VARCHAR(64), -- nullable
    ambiente VARCHAR(64) NOT NULL,
    nServizi SMALLINT UNSIGNED NOT NULL CHECK (nServizi >= 1), -- massimo 65.535 servizi per deployment
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
    dimensione INT UNSIGNED NOT NULL,
    path_fisico VARCHAR(255) NOT NULL,
    nodo_id VARCHAR(64) NOT NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(nodo_id) REFERENCES Nodi(hostname) ON DELETE CASCADE
);

CREATE TABLE VolumiGlobali(
    id CHAR(32),
    dimensione INT UNSIGNED NOT NULL,
    path_fisico VARCHAR(255) NOT NULL,
    indirizzo_IP_server VARCHAR(15) NOT NULL, -- consideriamo IPV4
    PRIMARY KEY(id)
);

CREATE TABLE VolumiDistribuiti(
    id CHAR(32),
    dimensione INT UNSIGNED NOT NULL,
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