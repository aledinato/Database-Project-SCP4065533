#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <libpq-fe.h>

void do_exit(PGconn *conn){
    PQfinish(conn);
    exit(1);
}

int main() {
    PGconn *conn = PQconnectdb(strcat("dbname=",getenv("DB_HOST")));
    if (PQstatus(conn) == CONNECTION_BAD) {
        fprintf(stderr, "Connessione al database fallita: %s", PQerrorMessage(conn));
        do_exit(conn);
    }

    char* query="SELECT * FROM Developers";
    PGresult *res = PQexec(conn, query);

    if (PQresultStatus(res) != PGRES_TUPLES_OK){
        fprintf(stderr, "Non è stato restituito un risultato per il seguente errore: %s", PQerrorMessage(conn));
        PQclear(res);
        do_exit(conn);
    }

    fprintf(stdout, "%s", PQgetvalue(res, 0, 0));
    PQclear(res);
    PQfinish(conn);

    return 0;
}