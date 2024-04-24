-- Gestion de colonne dérivée

-- Ajouter la colonne Nb_Inscrits à la table EPREUVES (initiée à 0)
ALTER TABLE EPREUVES
ADD Nb_Inscrits INT DEFAULT 0;

-- Mettre à jour la valeur de Nb_Inscrits pour les épreuves existantes
UPDATE EPREUVES Epr
SET Nb_Inscrits = (
    SELECT COUNT(*)
    FROM INSCRIPTIONS Ins
    WHERE Ins.NumEpr = Epr.NumEpr
);

--  Trigger qui initialise Nb_Inscrits lorsqu’une nouvelle épreuve est créée
CREATE OR REPLACE TRIGGER trig_init_nb_ins
BEFORE INSERT ON EPREUVES
FOR EACH ROW
BEGIN
    :NEW.Nb_Inscrits := 0;
END;

-- Trigger qui actualise la valeur de Nb_Inscrits lorsque la table INSCRIPTIONS est mise à jour
CREATE OR REPLACE TRIGGER trig_insert_ins
AFTER INSERT ON INSCRIPTIONS
FOR EACH ROW
BEGIN
    UPDATE EPREUVES
    SET Nb_Inscrits = Nb_Inscrits + 1
    WHERE NumEpr = :NEW.NumEpr;
END;
/

CREATE OR REPLACE TRIGGER trig_delete_ins
AFTER DELETE ON INSCRIPTIONS
FOR EACH ROW
BEGIN
    UPDATE EPREUVES
    SET Nb_Inscrits = Nb_Inscrits - 1
    WHERE NumEpr = :OLD.NumEpr;
END;
/

-- NB :NumEpr ne peut pas être modifié, car c'est une clé primaire (identifiant unique non modifiable).

-- Contrainte : Pour une épreuve, le nombre d’étudiants inscrits ne doit pas dépasser le quota fixé.
CREATE OR REPLACE TRIGGER trig_verif_quota
BEFORE INSERT ON INSCRIPTIONS
FOR EACH ROW
DECLARE
    i_quota INT;
    i_nb_inscrits INT;
BEGIN
    SELECT Quota, Nb_Inscrits INTO i_quota, i_nb_inscrits
    FROM EPREUVES
    WHERE NumEpr = :NEW.NumEpr;

    IF i_quota IS NOT NULL AND i_nb_inscrits >= i_quota THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le nombre d''inscriptions maximal est dépassé pour cette épreuve.');
    END IF;
END;
/

-- Tests 

INSERT INTO INSCRIPTIONS VALUES (1, 1); -- Doit réussir
SELECT Nb_Inscrits FROM EPREUVES WHERE NumEpr = 1; -- Doit retourner 1

-- Supposons qu'une épreuve a un quota de 1
INSERT INTO INSCRIPTIONS VALUES (2, 1); -- Doit échouer car le quota est atteint

DELETE FROM INSCRIPTIONS WHERE NumEtu = 1 AND NumEpr = 1; -- Supposer que cette inscription existe
SELECT Nb_Inscrits FROM EPREUVES WHERE NumEpr = 1; -- Doit retourner 0

-- Tenter d'insérer des données invalides et s'assurer qu'une erreur est levée
INSERT INTO INSCRIPTIONS VALUES (9999, 1); -- 9999 suppose qu'il n'existe pas dans ETUDIANTS, donc cela doit échouer
INSERT INTO OCCUPATIONS VALUES (1, 1, 0); -- Doit échouer car NbPlacesOcc doit être > 0

-- Tester l'insertion et la suppression dans INSCRIPTIONS et vérifier que Nb_Inscrits est mis à jour correctement dans EPREUVES
INSERT INTO INSCRIPTIONS VALUES (1, 1); -- Doit réussir et incrémenter Nb_Inscrits
DELETE FROM INSCRIPTIONS WHERE NumEtu = 1 AND NumEpr = 1; -- Doit réussir et décrémenter Nb_Inscrits

-- Supposer que l'épreuve 1 occupe déjà 50 places dans la salle 1
INSERT INTO OCCUPATIONS VALUES (1, 2, 10); -- Doit réussir car la capacité totale de la salle 1 est de 50
INSERT INTO OCCUPATIONS VALUES (1, 3, 20); -- Doit échouer car cela dépasserait la capacité totale de la salle 1





