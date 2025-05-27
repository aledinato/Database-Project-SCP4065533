#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "dependencies/include/libpq-fe.h"

#define PG_HOST "127.0.0.1"
#define PG_USER "admin"
#define PG_PASS "admin"
#define PG_DB "testProgettoDB"
#define PG_PORT 5432
#define MAX_PARAMS 3

typedef struct{
    char* query_name;
    char* query_string;
    int num_params;
    char* input_format[MAX_PARAMS];
} Query;

Query queries[] = {
    {
        .query_name = "ServiziDeployedAmbientiDiversiPerDeveloper",
        .query_string = "SELECT s.username_developer AS nome_servizio, COUNT(DISTINCT sd.ambiente_deployment) AS num_ambienti "
                        "FROM ServiziDeployed sd "
                        "JOIN Servizi s ON sd.nome_servizio = s.nome "
                        "GROUP BY s.username_developer "
                        "HAVING COUNT(DISTINCT sd.ambiente_deployment) >= $1::integer",
        .num_params = 1,
        .input_format = {"%d"}

    },
    {
        .query_name = "DeploymentsPerDeveloper",
        .query_string = "SELECT dep.username_developer, COUNT(*) AS num_failed_deployments, "
                        "ROUND(AVG(num_servizi), 2) AS media_servizi_deployed "
                        "FROM Deployments dep "
                        "JOIN Developers dev ON dep.username_developer = dev.username "
                        "WHERE dev.anzianita = $1::varchar AND dep.esito = $2::varchar "
                        "GROUP BY dep.username_developer "
                        "HAVING AVG(dep.num_servizi) > $3::integer "
                        "ORDER BY COUNT(*) DESC, AVG(dep.num_servizi) DESC",
        .num_params = 3,
        .input_format = {"%s", "%s","%d"}
    },
    {
        .query_name = "ContainersPerSpazioEVolumeMinimo",
        .query_string = "SELECT container_nome, container_nome_servizio, SUM(dimensione) AS spazio_volumi_totale, "
                        "MIN(dimensione) AS spazio_volume_minimo "
                        "FROM Montaggi GROUP BY container_nome, container_nome_servizio "
                        "ORDER BY spazio_volumi_totale ASC, spazio_volume_minimo ASC",
        .num_params = 0,
        .input_format = {""}
    },
    {
        .query_name = "ContainersSolaLettura",
        .query_string = "SELECT VolumiPerContainer.container_nome, VolumiPerContainer.container_nome_servizio, "
                        "VolumiInLetturaPerContainer.num_volumi_lettura "
                        "FROM VolumiPerContainer JOIN VolumiInLetturaPerContainer "
                        "ON VolumiInLetturaPerContainer.container_nome = VolumiPerContainer.container_nome "
                        "AND VolumiInLetturaPerContainer.container_nome_servizio = VolumiPerContainer.container_nome_servizio "
                        "WHERE VolumiInLetturaPerContainer.num_volumi_lettura = VolumiPerContainer.num_volumi",
        .num_params = 0,
        .input_format = {""}
    },
    {
        .query_name = "NodiCritici",
        .query_string = "SELECT Containers.hostname_nodo, COUNT(DISTINCT nome_servizio) AS num_servizi, Nodi.username_admin AS admin_username "
                        "FROM Containers "
                        "JOIN Nodi ON Nodi.hostname = Containers.hostname_nodo "
                        "GROUP BY Containers.hostname_nodo, Nodi.username_admin "
                        "HAVING COUNT(DISTINCT nome_servizio) >= ALL(SELECT COUNT(DISTINCT nome_servizio) FROM Containers GROUP BY Containers.hostname_nodo) "
                        "ORDER BY num_servizi ASC, Nodi.username_admin ASC",
        .num_params = 0,
        .input_format = {""}
    }
};

void do_exit(PGconn *conn){
    PQfinish(conn);
    exit(1);
}

void prepare_queries(PGconn *conn){
    for(int i=0; i<5; i++){
        PGresult *res = PQprepare(conn, queries[i].query_name, queries[i].query_string, queries[i].num_params, NULL);
        if (PQresultStatus(res) != PGRES_COMMAND_OK) {
            fprintf(stderr, "Preparazione della query fallita: %s", PQresultErrorMessage(res));
        }
        PQclear(res);
    }
}

void print_query_result(PGresult *res){
    int num_tuples = PQntuples(res);
    int num_fields = PQnfields(res);
    
    for(int i=0; i < num_fields; i++){
        printf("%s\t\t", PQfname(res, i));
    }
    printf("\n");

    for(int i=0; i < num_tuples; i++){
        for(int j=0; j < num_fields; j++){
            printf("%s\t\t", PQgetvalue(res, i, j));
        }
        printf("\n");
    }
}

void check_results(PGresult *res, PGconn * conn){
    if (PQresultStatus(res) != PGRES_TUPLES_OK){
        fprintf(stderr, "Non è stato restituito un risultato per il seguente errore: %s", PQerrorMessage(conn));
        PQclear(res);
        do_exit(conn);
    }
}

void write_query_result(PGresult *res, PGconn * conn, int query){
    char csvPath[1024];
    snprintf(csvPath, sizeof(csvPath), "%s%s.csv", "./results/", queries[query - 1].query_name);

    FILE *result_file = fopen(csvPath, "w");
    if (result_file == NULL) {
        printf("Errore nell'aprire il file CSV\n");
        PQclear(res);
        do_exit(conn);
    }

    int num_tuples = PQntuples(res);
    int num_fields = PQnfields(res);

    for (int i = 0; i < num_fields; i++) {
        fprintf(result_file, "%s", PQfname(res, i));
        if (i < num_fields - 1) fprintf(result_file, ",");
    }
    fprintf(result_file, "\n");

    for (int i = 0; i < num_tuples; i++) {
        for (int j = 0; j < num_fields; j++) {
            fprintf(result_file, "%s", PQgetvalue(res, i, j));
            if (j < num_fields - 1) fprintf(result_file, ",");
        }
        fprintf(result_file, "\n");
    }

    fclose(result_file);
}

PGresult* get_result(int query, PGconn *conn){
    Query *q = &queries[query - 1];
    char buffers[MAX_PARAMS][255]; //massima lunghezza stringa 255 caratteri
    const char *parameters[q->num_params];
    for(int i = 0; i < q->num_params; i++) {
        printf("Inserire parametro %d: ", i + 1);
        if (strcmp(q->input_format[i], "%d") == 0) {
            int temp;
            scanf("%d", &temp);
            snprintf(buffers[i], sizeof(buffers[i]), "%d", temp);
        } else {
            scanf(q->input_format[i], buffers[i]);
        }
        parameters[i] = buffers[i];
    }
    return PQexecPrepared(conn, q->query_name, q->num_params, parameters, NULL, 0, 0);
}

int main() {
    char credentials [250];
    sprintf( credentials, "user=%s password=%s dbname=%s host=%s port=%d", PG_USER , PG_PASS , PG_DB , PG_HOST , PG_PORT);
    PGconn *conn = PQconnectdb(credentials);

    if (PQstatus(conn) == CONNECTION_BAD) {
        fprintf(stderr, "Connessione al database fallita: %s", PQerrorMessage(conn));
        do_exit(conn);
    }

    prepare_queries(conn);

    int query = 0;
    while(1){
        printf("Inserire un numero tra 1 e 5 per eseguire la query, 0 per terminare il programma\n\n");
        
        printf("0) Per terminare il programma\n");
        printf("1) Inserire un intero per ottenere i developer che hanno sviluppato dei servizi, poi deployati, in un numero di ambienti maggiore o uguale dell'intero specificato\n");//posibilitù aggiunta data per ordinarle
        printf("2) Inserire un grado di anzianità, uno stato valido di un deployment e un intero per ottenere i developer nel grado specificato con associati i numeri di deployment nello stato specificato e la media dei servizi deployed\n");
        printf("   Vengono considerati solo i developer con una media di servizi deployed superiore all'intero specificato\n");
        printf("3) Si ottengono i container ordinati per spazio totale dei volumi montati in ordine crescente e la dimensione del volume più piccolo di quel container\n");
        printf("4) Si ottengono i container che sono in sola lettura su tutti i volumi\n");
        printf("5) Si ottengono il nodo o i nodi che se cadessero danneggerebbero più servizi, viene inserito anche l'admin associato al nodo\n");

        scanf("%d", &query);
        if(query < 0 || query > 5){
            printf("Numero query errato, deve essere compreso tra 1 e 5, 0 per terminare il programma\n");
            continue;
        }
        if(query == 0){
            printf("Ciao :)\n");
            break;
        }

        PGresult *res = get_result(query, conn);

        check_results(res, conn);

        int output_type;
        printf("Per stampare a schermo scrivere 0, per stampare su file scrivere 1, 2 per entrambi: ");
        scanf("%d", &output_type);
        if(output_type == 1 || output_type == 2){
            write_query_result(res, conn, query);
        }
        if(output_type == 0 || output_type == 2){
            print_query_result(res);
        }

        PQclear(res);
    }
    PQfinish(conn);

    return 0;
}
//gcc query.c -L dependencies/lib -lpq -o query