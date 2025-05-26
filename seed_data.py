from faker import Faker
import random
import uuid
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, text,  ForeignKeyConstraint
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, declarative_base

fake = Faker('it_IT')
Base = declarative_base()

# Connessione al DB
DB_USERNAME = 'admin'
DB_PASSWORD = 'admin'
DB_HOST = '127.0.0.1'
DB_PORT = '5432'
DB_NAME = 'mydb'
DATABASE_URL = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)
session = Session()

# Modelli ORM aggiornati
class Servizio(Base):
    __tablename__ = 'servizi'
    nome = Column(String, primary_key=True)
    username_developer = Column(String, ForeignKey('developers.username'))

    developer = relationship("Developer", backref="servizi")

class Nodo(Base):
    __tablename__ = 'nodi'
    hostname = Column(String, primary_key=True)
    sistema_operativo = Column(String)
    stato = Column(String)
    indirizzo_ip = Column(String)
    username_admin = Column(String, ForeignKey('admins.username'))
    admin = relationship("Admin", backref="nodi")

class Admin(Base):
    __tablename__ = 'admins'
    username = Column(String, primary_key=True)

class Developer(Base):
    __tablename__ = 'developers'
    username = Column(String, primary_key=True)
    password = Column(String)

class Container(Base):
    __tablename__ = 'containers'
    nome = Column(String, primary_key=True)
    nome_servizio = Column(String, ForeignKey('servizi.nome'), primary_key=True)
    stato = Column(String)
    hostname_nodo = Column(String, ForeignKey('nodi.hostname'))

    servizio = relationship("Servizio", backref="containers")
    nodo = relationship("Nodo", backref="containers")

class VolumeGlobale(Base):
    __tablename__ = 'volumiglobali'
    nome = Column(String, primary_key=True)
    dimensione = Column(Integer)
    path_fisico = Column(String)
    indirizzo_ip_server = Column(String)

class MontaggioGlobale(Base):
    __tablename__ = 'montaggiglobali'

    path_montaggio = Column(String)
    permessi = Column(String)
    container_nome = Column(String, primary_key=True)
    container_nome_servizio = Column(String, primary_key=True)
    nome_volume = Column(String, primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['container_nome', 'container_nome_servizio'],
            ['containers.nome', 'containers.nome_servizio']
        ),
        ForeignKeyConstraint(
            ['nome_volume'],
            ['volumiglobali.nome']
        ),
    )

    container = relationship("Container", backref="montaggi_globali")
    volume = relationship("VolumeGlobale", backref="montaggi_globali")

class VolumeDistribuito(Base):
    __tablename__ = 'volumidistribuiti'
    nome = Column(String, primary_key=True)
    dimensione = Column(Integer)
    path_fisico = Column(String)

class AllocazioneDistribuita(Base):
    __tablename__ = 'allocazionidistribuite'
    hostname_nodo = Column(String, ForeignKey('nodi.hostname'), primary_key=True)
    nome_volume = Column(String, ForeignKey('volumidistribuiti.nome'), primary_key=True)

    nodo = relationship("Nodo", backref="allocazioni_distribuite")
    volume = relationship("VolumeDistribuito", backref="allocazioni_distribuite")

class MontaggioDistribuito(Base):
    __tablename__ = 'montaggidistribuiti'

    path_montaggio = Column(String)
    permessi = Column(String)
    container_nome = Column(String, primary_key=True)
    container_nome_servizio = Column(String, primary_key=True)
    nome_volume = Column(String, primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['container_nome', 'container_nome_servizio'],
            ['containers.nome', 'containers.nome_servizio']
        ),
        ForeignKeyConstraint(
            ['nome_volume'],
            ['volumidistribuiti.nome']
        ),
    )

    container = relationship("Container", backref="montaggi_distribuiti")
    volume = relationship("VolumeDistribuito", backref="montaggi_distribuiti")


class VolumeLocale(Base):
    __tablename__ = 'volumilocali'
    nome = Column(String, primary_key=True)
    dimensione = Column(Integer)
    path_fisico = Column(String)
    hostname_nodo = Column(String, ForeignKey('nodi.hostname'))

    nodo = relationship("Nodo", backref="volumi_locali")

class MontaggioLocale(Base):
    __tablename__ = 'montaggilocali'

    path_montaggio = Column(String)
    permessi = Column(String)
    container_nome = Column(String, primary_key=True)
    container_nome_servizio = Column(String, primary_key=True)
    nome_volume = Column(String, primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['container_nome', 'container_nome_servizio'],
            ['containers.nome', 'containers.nome_servizio']
        ),
        ForeignKeyConstraint(
            ['nome_volume'],
            ['volumilocali.nome']
        ),
    )

    container = relationship("Container", backref="montaggi_locali")
    volume = relationship("VolumeLocale", backref="montaggi_locali")
    
## Nodi
admins = session.query(Admin).all()

for _ in range(10_000):
    nodo = Nodo(
        hostname=fake.hostname(),
        sistema_operativo=fake.linux_platform_token(),
        stato=random.choice(['Ready', 'Down', 'Drain']),
        indirizzo_ip=fake.ipv4(),
        username_admin=random.choice(admins).username
    )
    session.add(nodo)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")


servizi = session.query(Servizio).all()
nodi = session.query(Nodo).all()


## Containers

for _ in range(100_000):
    container = Container(
        nome = str(uuid.uuid4()),
        stato = random.choice(['running','created','paused','dead']),
        hostname_nodo = random.choice(nodi).hostname,
        nome_servizio = random.choice(servizi).nome,
    )
    session.add(container)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")

containers = session.query(Container).all()

## VolumiLocali

for _ in range(100_000):
    volumeLocali = VolumeLocale(
        nome = str(uuid.uuid4()),
        dimensione = random.randint(1000,10_000_000),
        path_fisico = fake.file_path(depth=3, category='text'),
        hostname_nodo = random.choice(nodi).hostname,
    )
    session.add(volumeLocali)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")

## VolumiGlobali
for _ in range(100_000):
    volumeGlob = VolumeGlobale(
        nome = str(uuid.uuid4()),
        dimensione = random.randint(1000,10_000_000),
        path_fisico = fake.file_path(depth=3, category='text'),
        indirizzo_ip_server = fake.ipv4(),
    )
    session.add(volumeGlob)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")

## Volumi Distribuiti
for _ in range(1_000_000):
    volumeDistr = VolumeDistribuito(
        nome = str(uuid.uuid4()),
        dimensione = random.randint(1000,10_000_000),
        path_fisico = fake.file_path(depth=3, category='text'),
    )
    session.add(volumeDistr)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")


volumiLocali = session.query(VolumeLocale).all()
volumiGlobali = session.query(VolumeGlobale).all()
volumiDistribuiti = session.query(VolumeDistribuito).all()


## Allocazioni Distribuite
for _ in range(100_000):
    allocazioneDistr = AllocazioneDistribuita(
        hostname_nodo = random.choice(nodi).hostname,
        nome_volume = random.choice(volumiDistribuiti).nome
    )
    session.add(allocazioneDistr)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")

allocazioniDistribuite = session.query(AllocazioneDistribuita).all()

## Montaggi Gloabli
for _ in range(100_000):
    container = random.choice(containers)
    montaggioGlob = MontaggioGlobale(
        path_montaggio = fake.file_path(depth=3, category='text'),
        permessi = random.choice(['r--','rwx','-w-','--x','rw-','-wx']),
        container_nome = container.nome,
        container_nome_servizio = container.nome_servizio,
        nome_volume = random.choice(volumiGlobali).nome,
    )
    session.add(montaggioGlob)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")

## Montaggi Locali
for _ in range(100_000):
    volumeLoc = random.choice(volumiLocali)
    randomContainers = volumeLoc.nodo.containers
    if randomContainers:
        container = random.choice(randomContainers)
    else:
        continue

    montaggioLoc = MontaggioLocale(
        path_montaggio = fake.file_path(depth=3, category='text'),
        permessi = random.choice(['r--','rwx','-w-','--x','rw-','-wx']),
        container_nome = container.nome,
        container_nome_servizio = container.nome_servizio,
        nome_volume = volumeLoc.nome,
    )
    session.add(montaggioLoc)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")


## Montaggi Distribuiti
for _ in range(1_000_000):
    volumeDistr = random.choice(volumiDistribuiti)
    if volumeDistr.allocazioni_distribuite:
        allocazioneDistr = random.choice(volumeDistr.allocazioni_distribuite)
    else:
        continue
    randomContainers = allocazioneDistr.nodo.containers
    if randomContainers:
        container = random.choice(randomContainers)
    else:
        continue

    montaggioDistr = MontaggioDistribuito(
        path_montaggio = fake.file_path(depth=3, category='text'),
        permessi = random.choice(['r--','rwx','-w-','--x','rw-','-wx']),
        container_nome = container.nome,
        container_nome_servizio = container.nome_servizio,
        nome_volume = volumeDistr.nome,
    )
    session.add(montaggioDistr)
    try:
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Inserimento fallito: {e}")




session.close()
print("Dati inseriti con successo.")