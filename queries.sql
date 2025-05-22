-- query significativa 
-- 1) Developers che hanno fatto almeno 2 deployment in ambienti diversi per lo stesso servizio
SELECT s.username_developer, s.nome AS nome_servizio, COUNT(DISTINCT sd.ambiente_deployment) AS num_ambienti
FROM ServiziDeployed sd
JOIN Servizi s ON sd.nome_servizio = s.nome
GROUP BY s.username_developer, s.nome
HAVING COUNT(DISTINCT sd.ambiente_deployment) >= 2;


-- 2) query con group by
-- Developer con almeno un failed deployment, con media di servizi deployed maggiore di 5 e ordinati prima per numero di failed deployments e poi per media di servizi deployed, entrambi in ordine decrescente
SELECT username_developer, COUNT(*) AS num_failed_deployments, ROUND(AVG(num_servizi), 2) AS media_servizi_deployed
FROM Deployments
WHERE esito = 'failed'
GROUP BY username_developer
HAVING AVG(num_servizi) > 5
ORDER BY COUNT(*) DESC, AVG(num_servizi) DESC;

-- 3) query con group by
-- Containers che sono in sola lettura su tutti i volumi
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

CREATE VIEW VolumiInLetturaPerContainer AS
SELECT container_nome, container_nome_servizio, COUNT(*) AS num_volumi_lettura
FROM Montaggi
WHERE permessi = 'r--'
GROUP BY container_nome, container_nome_servizio;

CREATE VIEW VolumiPerContainer AS
SELECT container_nome, container_nome_servizio, COUNT(*) AS num_volumi
FROM Montaggi
GROUP BY container_nome, container_nome_servizio;

SELECT VolumiPerContainer.container_nome, VolumiPerContainer.container_nome_servizio, VolumiInLetturaPerContainer.num_volumi_lettura
FROM VolumiPerContainer
JOIN VolumiInLetturaPerContainer 
ON VolumiInLetturaPerContainer.container_nome = VolumiPerContainer.container_nome
AND VolumiInLetturaPerContainer.container_nome_servizio = VolumiPerContainer.container_nome_servizio
WHERE VolumiInLetturaPerContainer.num_volumi_lettura = VolumiPerContainer.num_volumi;

-- 4) query con group by
-- Il nodo o i nodi che se cadessero darebbero problemi a più servizi associato al suo admin
SELECT Containers.hostname_nodo, COUNT(DISTINCT nome_servizio) AS num_servizi, Admins.username AS admin_username
FROM Containers
JOIN Nodi ON Nodi.hostname = Containers.hostname_nodo
JOIN Admins ON Admins.username = Nodi.username_admin
GROUP BY Containers.hostname_nodo, Admins.username
HAVING COUNT(DISTINCT nome_servizio) >= ALL(
    SELECT COUNT(DISTINCT nome_servizio)
    FROM Containers
    GROUP BY Containers.hostname_nodo
)


-- 5) query con group by e having
-- Containers ordinati per spazio disponibile in ordine crescente e il volume più piccolo di quel container
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

SELECT container_nome, container_nome_servizio, SUM(dimensione) AS spazio_volumi_totale, MIN(dimensione) AS spazio_volume_minimo
FROM Montaggi
GROUP BY container_nome, container_nome_servizio
ORDER BY spazio_volumi_totale ASC, spazio_volume_minimo ASC;