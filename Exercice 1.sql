-- Création des tables

CREATE TABLE ETUDIANTS (
    NumEtu INT PRIMARY KEY,
    NomEtu VARCHAR(255) NOT NULL,
    PrenomEtu VARCHAR(255) NOT NULL
);

CREATE TABLE ENSEIGNANTS (
    NumEns INT PRIMARY KEY,
    NomEns VARCHAR(255) NOT NULL,
    PrenomEns VARCHAR(255) NOT NULL
);

CREATE TABLE SALLES (
    NumSal INT PRIMARY KEY,
    NomSal VARCHAR(255) NOT NULL,
    CapaciteSal INT NOT NULL CHECK (CapaciteSal > 0)
);

CREATE TABLE EPREUVES (
    NumEpr INT PRIMARY KEY,
    NomEpr VARCHAR(255) NOT NULL,
    DureeEpr INTERVAL DAY TO SECOND NOT NULL,
    Quota INT
);

CREATE TABLE HORAIRES (
    NumEpr INT PRIMARY KEY REFERENCES EPREUVES (NumEpr),
    DateHeureDebut TIMESTAMP NOT NULL
);

CREATE TABLE INSCRIPTIONS (
    NumEtu INT REFERENCES ETUDIANTS (NumEtu),
    NumEpr INT REFERENCES EPREUVES (NumEpr),
    PRIMARY KEY (NumEtu, NumEpr)
);

CREATE TABLE OCCUPATIONS (
    NumSal INT REFERENCES SALLES (NumSal),
    NumEpr INT REFERENCES EPREUVES (NumEpr),
    NbPlacesOcc INT NOT NULL CHECK (NbPlacesOcc > 0),
    PRIMARY KEY (NumSal, NumEpr)
);

CREATE TABLE SURVEILLANCES (
    NumEns INT REFERENCES ENSEIGNANTS (NumEns),
    DateHeureDebut TIMESTAMP NOT NULL,
    NumSal INT REFERENCES SALLES (NumSal),
    PRIMARY KEY (NumEns, DateHeureDebut, NumSal)
);

#Insertion des données

-- Insertion des étudiants
INSERT INTO ETUDIANTS VALUES (1, 'Ridaoui', 'Hatim');
INSERT INTO ETUDIANTS VALUES (2, 'Mahdi', 'Badr');
INSERT INTO ETUDIANTS VALUES (3, 'Alaoui', 'Hassan');

-- Insertion des enseignants
INSERT INTO ENSEIGNANTS VALUES (1, 'Azzouz', 'Richard');
INSERT INTO ENSEIGNANTS VALUES (2, 'Benbarka', 'Mehdi');
INSERT INTO ENSEIGNANTS VALUES (3, 'Macron', 'Emmanuel');

-- Insertion des salles
INSERT INTO SALLES VALUES (1, 'Salle 10', 50);
INSERT INTO SALLES VALUES (2, 'Salle 11', 70);
INSERT INTO SALLES VALUES (3, 'Salle 12', 150);

-- Insertion des épreuves
INSERT INTO EPREUVES VALUES (1, 'Physique', INTERVAL '2' HOUR, 50);
INSERT INTO EPREUVES VALUES (2, 'Chimie', INTERVAL '1' HOUR, NULL);
INSERT INTO EPREUVES VALUES (3, 'Philosophie', INTERVAL '3' HOUR, NULL);
INSERT INTO EPREUVES VALUES (5, 'Bases de données', INTERVAL '3' HOUR, NULL);
INSERT INTO EPREUVES VALUES (4, 'Mathématiques avancées', INTERVAL '3' HOUR, NULL);

-- Insertion des horaires
INSERT INTO HORAIRES VALUES (1, TIMESTAMP '2024-08-22 08:30:00');
INSERT INTO HORAIRES VALUES (2, TIMESTAMP '2024-06-08 14:30:00');
INSERT INTO HORAIRES VALUES (3, TIMESTAMP '2024-05-08 08:30:00');
INSERT INTO HORAIRES VALUES (4, TIMESTAMP '2024-05-10 15:30:00');
INSERT INTO HORAIRES VALUES (5, TIMESTAMP '2024-05-10 15:30:00');


-- Insertion des inscriptions
INSERT INTO INSCRIPTIONS VALUES (1, 1);
INSERT INTO INSCRIPTIONS VALUES (2, 2);
INSERT INTO INSCRIPTIONS VALUES (3, 3);

-- Insertion des occupations
INSERT INTO OCCUPATIONS VALUES (1, 1, 70);
INSERT INTO OCCUPATIONS VALUES (2, 2, 50);
INSERT INTO OCCUPATIONS VALUES (3, 3, 25);

-- Insertion des surveillances
INSERT INTO SURVEILLANCES VALUES (1, TIMESTAMP '2024-08-22 08:30:00', 1);
INSERT INTO SURVEILLANCES VALUES (2, TIMESTAMP '2024-06-08 14:30:00', 2);
INSERT INTO SURVEILLANCES VALUES (3, TIMESTAMP '2024-05-08 08:30:00', 3);
