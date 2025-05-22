from faker import Faker
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker

# Inizializza Faker
fake = Faker('it_IT')

# Base per definire i modelli ORM
Base = declarative_base()

class Utente(Base):
    __tablename__ = 'utenti'
    id = Column(Integer, primary_key=True)
    nome = Column(String)
    cognome = Column(String)
    email = Column(String)

# 🔧 Dettagli di connessione PostgreSQL
# Modifica questi valori con i tuoi dati
DB_USERNAME = 'admin'
DB_PASSWORD = 'admin'
DB_HOST = 'localhost'
DB_PORT = '5432'
DB_NAME = 'mydb'

# Crea la stringa di connessione
DATABASE_URL = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Connessione al database
engine = create_engine(DATABASE_URL)

# Crea la tabella se non esiste
Base.metadata.create_all(engine)

# Crea la sessione
Session = sessionmaker(bind=engine)
session = Session()

# Aggiungi 10 utenti finti
for _ in range(10):
    utente = Utente(
        nome=fake.first_name(),
        cognome=fake.last_name(),
        email=fake.email()
    )
    session.add(utente)

# Salva i dati
session.commit()
session.close()

print("✅ 10 utenti finti salvati su PostgreSQL.")
