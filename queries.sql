-- 1) query significativa coinvolge 2 tabelle
-- Tutto il versionamento dei deployment con i developer associati usando CTE(common table expression)
WITH RECURSIVE VersioniDeployments AS (
    SELECT id, ambiente, num_servizi, esito, username AS dev_username
    FROM Deployments
    JOIN Developers ON Developers.username = Deployments.developer_id
    WHERE id = <id>

    UNION ALL

    SELECT id, ambiente, num_servizi, esito, username AS dev_username 
    FROM Deployments
    JOIN VersioniDeployments ON VersioniDeployments.versione_precedente = Deployments.id
    JOIN Developers ON Developers.username = Deployments.developer_id
)
SELECT * FROM VersioniDeployments;

-- 2) query con group by
-- Developer con almeno un failed deployment e ordinati dal maggior numero al minore
SELECT developer_id, COUNT(*) AS num_failed_deployments
FROM Deployments
WHERE esito = 'failed'
GROUP BY developer_id
HAVING COUNT(*) > 0
ORDER BY COUNT(*) DESC;
-- 3) query con group by
-- Container che sono in sola lettura su tutti i container e che hanno almeno un volume montato
CREATE VIEW Montaggi AS
SELECT *
FROM MontaggiLocali
UNION ALL
SELECT *
FROM MontaggiGlobali
UNION ALL
SELECT *
FROM MontaggiDistribuiti;

CREATE VIEW VolumiInLetturaPerContainer AS
SELECT container_nome, container_servizio_id, COUNT(*) AS num_volumi_lettura
FROM Montaggi
WHERE permessi = 'r'
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
WHERE VolumiPerContainer.num_volumi > 0 
AND VolumiInLetturaPerContainer.num_volumi_lettura = VolumiPerContainer.num_volumi;

-- 4) query con group by
-- Il nodo che se cadesse darebbe problemi a più servizi associato al suo admin
SELECT Containers.nodo_id, COUNT(DISTINCT servizio_id) AS num_servizi, Admins.username
FROM Containers
JOIN Admins ON Admins.username = Containers.nodo_id
GROUP BY Containers.nodo_id, Admins.username
ORDER BY num_servizi ASC
LIMIT 1;


-- 5) query con group by e having
-- Container/s con meno spazio a disposizione in kb
SELECT container_nome, container_servizio_id, SUM(dimensione) AS spazio_disponibile
FROM Montaggi
GROUP BY container_nome, container_servizio_id
ORDER BY SpazioDisponibilePerContainer.spazio_disponibile ASC;