FROM gcc:latest

RUN apt-get update && apt-get install -y libpq-dev

WORKDIR /usr/src/app
COPY . .

RUN gcc -o orchestrator_app main.c -lpq

CMD ["./orchestrator_app"]