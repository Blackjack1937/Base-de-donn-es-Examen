-- C1
CREATE OR REPLACE TRIGGER trig_epr_time
BEFORE INSERT OR UPDATE ON HORAIRES
FOR EACH ROW
DECLARE
    i_end_time TIMESTAMP;
    i_duration INTERVAL DAY TO SECOND;
BEGIN
    SELECT E.DureeEpr INTO i_duration
    FROM EPREUVES E 
    WHERE E.NumEpr = :NEW.NumEpr;
    
    i_end_time := :NEW.DateHeureDebut + i_duration;
                                         
    IF TO_CHAR(i_end_time, 'HH24:MI') > '20:00' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Une épreuve ne peut pas se terminer après 20H00.');
    END IF;
END;
/


-- Tests C1
-- Opération validée par la contrainte
UPDATE HORAIRES SET DateHeureDebut = TIMESTAMP '2024-08-22 18:00:00' WHERE NumEpr = 1; 

-- Opération refusée par la contrainte
UPDATE HORAIRES SET DateHeureDebut = TIMESTAMP '2024-08-22 19:00:00' WHERE NumEpr = 1;

-- C2
CREATE OR REPLACE TRIGGER trig_check_student_schedule
BEFORE INSERT OR UPDATE ON INSCRIPTIONS
FOR EACH ROW
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_conflict_count INT;
BEGIN
    -- Récupération de l'heure de début et de fin de la nouvelle épreuve
    SELECT h.DateHeureDebut, h.DateHeureDebut + e.DureeEpr INTO v_start_time, v_end_time
    FROM HORAIRES h JOIN EPREUVES e ON h.NumEpr = e.NumEpr
    WHERE h.NumEpr = :NEW.NumEpr;
    
    -- Vérification de conflit d'horaire pour l'étudiant
    SELECT COUNT(*) INTO v_conflict_count
    FROM INSCRIPTIONS i
    JOIN HORAIRES h ON i.NumEpr = h.NumEpr
    JOIN EPREUVES e ON h.NumEpr = e.NumEpr
    WHERE i.NumEtu = :NEW.NumEtu
    AND (v_start_time < h.DateHeureDebut + e.DureeEpr AND v_end_time > h.DateHeureDebut);
    
    IF v_conflict_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Un étudiant ne peut pas avoir deux épreuves en même temps.');
    END IF;
END;
/

--Tests C2
-- Supposant que l'épreuve 5 n'a pas lieu en même temps que les épreuves existantes de l'étudiant 1.
INSERT INTO INSCRIPTIONS VALUES (1, 5);
-- Supposant que l'épreuve 4 a lieu en même temps que l'épreuve 1, à laquelle l'étudiant 1 est déjà inscrit.
INSERT INTO INSCRIPTIONS VALUES (1, 4);

-- C3

CREATE OR REPLACE TRIGGER trig_check_same_start_time
BEFORE INSERT OR UPDATE ON HORAIRES
FOR EACH ROW
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM HORAIRES h
    JOIN OCCUPATIONS o ON h.NumEpr = o.NumEpr
    JOIN EPREUVES e ON e.NumEpr = h.NumEpr
    WHERE o.NumSal IN (SELECT NumSal FROM OCCUPATIONS WHERE NumEpr = :NEW.NumEpr)
    AND (
        (h.DateHeureDebut BETWEEN :NEW.DateHeureDebut AND :NEW.DateHeureDebut + (SELECT DuréeEpr FROM EPREUVES WHERE NumEpr = :NEW.NumEpr))
        OR 
        (:NEW.DateHeureDebut BETWEEN h.DateHeureDebut AND h.DateHeureDebut + e.DuréeEpr)
    );

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Les épreuves qui se chevauchent dans la même salle doivent commencer en même temps.');
    END IF;
END;





-- Tests C3

INSERT INTO HORAIRES VALUES (7, TO_TIMESTAMP('2024-08-22 09:00:00','YYYY-MM-DD HH24-MI-SS')); -- Opération refusée car les épreuves se chevauchent
INSERT INTO HORAIRES VALUES (7, TO_TIMESTAMP('2024-08-22 09:00:00','YYYY-MM-DD HH24-MI-SS')); -- Opération validée car les épreuves ne se chevauchent pas




-- C4
CREATE OR REPLACE TRIGGER trig_check_salle_capacity
BEFORE INSERT OR UPDATE ON OCCUPATIONS
FOR EACH ROW
DECLARE
    total_occupied INT;
    salle_capacity INT;
BEGIN
    -- Si c'est une mise à jour, soustraire d'abord l'ancien nombre de places de l'occupation totale
    IF UPDATING THEN
        SELECT SUM(NbPlacesOcc) - NVL(:OLD.NbPlacesOcc, 0) INTO total_occupied
        FROM OCCUPATIONS
        WHERE NumSal = :NEW.NumSal;
    ELSE
        SELECT SUM(NbPlacesOcc) INTO total_occupied
        FROM OCCUPATIONS
        WHERE NumSal = :NEW.NumSal;
    END IF;

    -- Ajouter le nouveau nombre de places à l'occupation totale
    total_occupied := total_occupied + :NEW.NbPlacesOcc;

    -- Récupérer la capacité de la salle
    SELECT CapaciteSal INTO salle_capacity
    FROM SALLES
    WHERE NumSal = :NEW.NumSal;

    -- Vérifier si la capacité est dépassée
    IF total_occupied > salle_capacity THEN
        RAISE_APPLICATION_ERROR(-20002, 'La capacité de la salle est dépassée.');
    END IF;
END;

-- Tests C4
INSERT INTO OCCUPATIONS VALUES (1,1,150); -- Opération refusée car dépasse largement la capacité de la salle 1
INSERT INTO OCCUPATIONS VALUES (4,7,10); -- Opération validée car ne dépasse la capacité de la salle 4

--C5
CREATE OR REPLACE TRIGGER trig_check_surveillance_valide
BEFORE INSERT OR UPDATE ON SURVEILLANCES
FOR EACH ROW
DECLARE
    exam_count INT;
BEGIN
    -- Vérifie s'il y a une épreuve programmée dans la salle à l'heure donnée
    SELECT COUNT(*) INTO exam_count
    FROM HORAIRES H
    JOIN OCCUPATIONS O ON H.NumEpr = O.NumEpr
    WHERE O.NumSal = :NEW.NumSal AND H.DateHeureDebut = :NEW.DateHeureDebut;

    -- Si aucune épreuve n'est programmée, on a une erreur
    IF exam_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Aucune épreuve programmée pour cette salle et cet horaire.');
    END IF;
END;

-- Tests C5
INSERT INTO SURVEILLANCES VALUES (2, TIMESTAMP '2024-08-22 10:00:00', 1); -- Opération refusée car l'épreuve 7 se passe à la salle 4
INSERT INTO SURVEILLANCES VALUES (2, TIMESTAMP '2024-08-22 10:00:00', 4); -- Opération acceptée


