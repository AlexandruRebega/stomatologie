create database dent;
use dent;

-- this setting avoids ERROR 1418 (HY000) at slotIsAvailable function
log_bin_trust_function_creators = 1;

create table clienti(
   client_id        INT NOT NULL AUTO_INCREMENT,
   client_nume      VARCHAR(56) NOT NULL,
   client_email     VARCHAR(40) NOT NULL,
   client_pass      CHAR(64) NOT NULL,
   client_tel       VARCHAR(15) NOT NULL,
   PRIMARY KEY ( client_id )
);

create table medici(
    medic_id            INT NOT NULL AUTO_INCREMENT,
    medic_nume          VARCHAR(56) NOT NULL,
    medic_dataAngajare  Date,
    medic_salariu       INT,
    PRIMARY KEY ( medic_id )    
);

create table operatie(
    operatie_id     INT NOT NULL AUTO_INCREMENT,
    operatie_nume   VARCHAR(56) NOT NULL,
    operatie_pret   FLOAT NOT NULL,
    operatie_durata INT,
    PRIMARY KEY ( operatie_id )
);

create table istoric(
    istoric_id      INT NOT NULL AUTO_INCREMENT,
    operatie_id     INT NOT NULL,
    client_id       INT NOT NULL,
    istoric_data    Date,
    FOREIGN KEY (operatie_id)
        REFERENCES operatie(operatie_id),
    FOREIGN KEY (client_id)
        REFERENCES clienti(client_id)
        ON DELETE CASCADE,  
    PRIMARY KEY ( istoric_id )
);

CREATE TABLE programari (
    medic_id    INT UNSIGNED    NOT NULL,
    data        DATE            NOT NULL,
    startTime   TIME(0)         NOT NULL,
    endTime     TIME(0)         NOT NULL,

    CONSTRAINT PRIMARY KEY (medic_id, data, startTime),

    CONSTRAINT mustStartOnTenMinuteBoundary CHECK (
        EXTRACT(MINUTE FROM startTime) % 10 = 0
        AND EXTRACT(SECOND FROM startTime) = 0
    ),
    CONSTRAINT mustEndOnTenMinuteBoundary CHECK (
        EXTRACT(MINUTE FROM endTime) % 10 = 0
        AND EXTRACT(SECOND FROM endTime) = 0
    ),
    CONSTRAINT cannotStartBefore0900 CHECK (
        EXTRACT(HOUR FROM startTime) >= 9
    ),
    CONSTRAINT cannotEndAfter1700 CHECK (
        EXTRACT(HOUR FROM (startTime - INTERVAL 1 SECOND)) < 17
    ),
    CONSTRAINT mustEndAfterStart CHECK (
        endTime > startTime
    )
);


-- create table orar(
--  orar_id     INT NOT NULL AUTO_INCREMENT,
--  medic_id    INT,
--  FOREIGN KEY (medic_id)
--         REFERENCES medici(medic_id)
--         ON DELETE CASCADE,
--     orar_zi      Date,

--  PRIMARY KEY ( orar_id )
-- );

CREATE TABLE Numbers (number INT UNSIGNED PRIMARY KEY);

DELIMITER //

CREATE PROCEDURE populateNumbers()
BEGIN
    SET @x = 0;
    WHILE @x < 1024 DO
        INSERT INTO Numbers VALUES (@x);
        SET @x = @x + 1;
    END WHILE;
    SET @x = NULL;
END; //

DELIMITER ;

CALL populateNumbers;
DROP PROCEDURE populateNumbers;




DELIMITER //

CREATE FUNCTION slotIsAvailable(
    medic_id            INT,
    slotStartDateTime   DATETIME,
    slotEndDateTime     DATETIME
) RETURNS BOOLEAN NOT DETERMINISTIC
BEGIN
    RETURN CASE WHEN EXISTS (
        -- This table will contain records iff the slot clashes with an existing appointment
        SELECT TRUE
        FROM programari AS p
        WHERE
                CONVERT(slotStartDateTime, TIME) < p.endTime   -- These two conditions will both hold iff the slot overlaps
            AND CONVERT(slotEndDateTime,   TIME) > p.startTime -- with the existing appointment that it's being compared to
            AND p.medic_id = medic_id
            AND p.data = CONVERT(slotStartDateTime, DATE)
    ) THEN FALSE ELSE TRUE
    END;
END; //

DELIMITER ;




DELIMITER //

CREATE TRIGGER ensureNewAppointmentsDoNotClash
    BEFORE INSERT ON programari
    FOR EACH ROW
BEGIN
    IF NOT slotIsAvailable(
        NEW.medic_id,
        CAST( CONCAT(NEW.data, ' ', NEW.startTime)  AS DATETIME ),
        CAST( CONCAT(NEW.data, ' ', NEW.endTime)    AS DATETIME )
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment clashes with an existing appointment!';
    END IF;
END; //

DELIMITER ;

