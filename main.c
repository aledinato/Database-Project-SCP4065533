#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "dependencies/include/libpq-fe.h"

void do_exit(PGconn *conn){
    PQfinish(conn);
    exit(1);
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

int main() {
    char* PG_HOST = getenv("DB_HOST");
    char* PG_USER = getenv("DB_USER");
    char* PG_PASS = getenv("DB_PASSWORD");
    char* PG_DB = getenv("DB_NAME");
    char* PG_PORT = getenv("DB_PORT");

    char credentials [250];
    sprintf( credentials, "user=%s password=%s dbname=%s host=%s port=%s ", PG_USER , PG_PASS , PG_DB , PG_HOST , PG_PORT);
    PGconn *conn = PQconnectdb(credentials);

    if (PQstatus(conn) == CONNECTION_BAD) {
        fprintf(stderr, "Connessione al database fallita: %s", PQerrorMessage(conn));
        do_exit(conn);
    }

    char* query="SELECT * FROM Developers";

    PGresult *res = PQexec(conn, query);

    check_results(res, conn);

    print_query_result(res);

    PQclear(res);
    PQfinish(conn);

    return 0;
}