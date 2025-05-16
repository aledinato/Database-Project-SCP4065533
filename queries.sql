-- 1) query significativa coinvolge 2 tabelle
-- Tutto il versionamento dei deployment con i developer associati usando CTE(common table expression)
WITH RECURSIVE VersioniDeployments AS (
    SELECT d1.id, d1.esito, d1.ambiente, d1.num_servizi, d1.developer_id, d1.versione_precedente
    FROM Deployments d1
    WHERE id = 'deploy-002'

    UNION ALL

    SELECT d2.id, d2.esito, d2.ambiente, d2.num_servizi, d2.developer_id, d2.versione_precedente
    FROM Deployments d2
    JOIN VersioniDeployments ON VersioniDeployments.versione_precedente = d2.id
)
SELECT * FROM VersioniDeployments;
-- 2) query con group by
-- Developer con almeno un failed deployment, con media di servizi deployed maggiore di 5 e ordinati prima per numero di failed deployments e poi per media di servizi deployed, entrambi in ordine decrescente
SELECT developer_id, COUNT(*) AS num_failed_deployments, ROUND(AVG(num_servizi), 2) AS media_servizi_deployed
FROM Deployments
WHERE esito = 'failed'
GROUP BY developer_id
HAVING AVG(num_servizi) > 1
ORDER BY COUNT(*) DESC, AVG(num_servizi) DESC;

-- 3) query con group by
-- Containesr che sono in sola lettura su tutti i volumi
CREATE VIEW Montaggi AS
SELECT MontaggiLocali.*, VolumiLocali.dimensione
FROM MontaggiLocali
JOIN VolumiLocali ON VolumiLocali.id = MontaggiLocali.volume_id
UNION ALL
SELECT MontaggiGlobali.*, VolumiGlobali.dimensione
FROM MontaggiGlobali
JOIN VolumiGlobali ON VolumiGlobali.id = MontaggiGlobali.volume_id
UNION ALL
SELECT MontaggiDistribuiti.*, VolumiDistribuiti.dimensione
FROM MontaggiDistribuiti
JOIN VolumiDistribuiti ON VolumiDistribuiti.id = MontaggiDistribuiti.volume_id;

CREATE VIEW VolumiInLetturaPerContainer AS
SELECT container_nome, container_servizio_id, COUNT(*) AS num_volumi_lettura
FROM Montaggi
WHERE permessi = 'r--'
GROUP BY container_nome, container_servizio_id;

CREATE VIEW VolumiPerContainer AS
SELECT container_nome, container_servizio_id, COUNT(*) AS num_volumi
FROM Montaggi
GROUP BY container_nome, container_servizio_id;

SELECT VolumiPerContainer.container_nome, VolumiPerContainer.container_servizio_id, VolumiInLetturaPerContainer.num_volumi_lettura
FROM VolumiPerContainer
JOIN VolumiInLetturaPerContainer 
ON VolumiInLetturaPerContainer.container_nome = VolumiPerContainer.container_nome
AND VolumiInLetturaPerContainer.container_servizio_id = VolumiPerContainer.container_servizio_id
WHERE VolumiInLetturaPerContainer.num_volumi_lettura = VolumiPerContainer.num_volumi;

-- 4) query con group by
-- Il nodo o i nodi che se cadessero darebbero problemi a più servizi associato al suo admin
SELECT Containers.nodo_id, COUNT(DISTINCT servizio_id) AS num_servizi, Admins.username AS admin_username
FROM Containers
JOIN Nodi ON Nodi.hostname = Containers.nodo_id
JOIN Admins ON Admins.username = Nodi.admin_id
GROUP BY Containers.nodo_id, Admins.username
HAVING COUNT(DISTINCT servizio_id) >= ALL(
    SELECT COUNT(DISTINCT servizio_id)
    FROM Containers
    GROUP BY Containers.nodo_id
)
ORDER BY num_servizi ASC, Admins.username;


-- 5) query con group by e having
-- Containers ordinati per spazio disponibile in ordine crescente e il volume più piccolo di quel container
CREATE VIEW Montaggi AS
SELECT MontaggiLocali.*, VolumiLocali.dimensione
FROM MontaggiLocali
JOIN VolumiLocali ON VolumiLocali.id = MontaggiLocali.volume_id
UNION ALL
SELECT MontaggiGlobali.*, VolumiGlobali.dimensione
FROM MontaggiGlobali
JOIN VolumiGlobali ON VolumiGlobali.id = MontaggiGlobali.volume_id
UNION ALL
SELECT MontaggiDistribuiti.*, VolumiDistribuiti.dimensione
FROM MontaggiDistribuiti
JOIN VolumiDistribuiti ON VolumiDistribuiti.id = MontaggiDistribuiti.volume_id;

SELECT container_nome, container_servizio_id, SUM(dimensione) AS spazio_volumi_totale, MIN(dimensione) AS spazio_volume_minimo
FROM Montaggi
GROUP BY container_nome, container_servizio_id
ORDER BY spazio_volumi_totale ASC, spazio_volume_minimo ASC;