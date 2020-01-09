create database dent;
use dent;

-- this setting avoids ERROR 1418 (HY000) at slotIsAvailable function
SET GLOBAL log_bin_trust_function_creators = 1;

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
    medic_email         VARCHAR(40) NOT NULL,
    medic_pass          CHAR(64) NOT NULL,
    medic_tel           VARCHAR(15),
    medic_dataAngajare  DATE,
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
    istoric_data    DATE,
    FOREIGN KEY (operatie_id)
        REFERENCES operatie(operatie_id),
    FOREIGN KEY (client_id)
        REFERENCES clienti(client_id)
        ON DELETE CASCADE,  
    PRIMARY KEY ( istoric_id )
);

-- TODO: add operatie_id, make medic_id, client_id and operatie_id FOREIGN KEYs
CREATE TABLE programari (
    medic_id    INT UNSIGNED    NOT NULL,
    client_id   INT UNSIGNED    NOT NULL,       
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

-- Insert initial data for tests
INSERT INTO clienti VALUES (NULL, 'test client', 'testClient@gmail.com', 'parola', '0722110234');
INSERT INTO medici VALUES(NULL, 
                        'Bob Carry',
                        'bobcarry@antodent.com',
                        'parolaBob',
                        '0721353123',
                        '20170420',
                        '4500'
                        );
INSERT INTO medici VALUES(NULL, 
                        'Jean Smith',
                        'jsmith@antodent.com',
                        'parolaJean',
                        '0744053123',
                        '20150614',
                        '4500'
                        );
INSERT INTO medici VALUES(NULL, 
                        'Ricky Fisher',
                        'rfisher@antodent.com',
                        'parolaRick',
                        '0731203102',
                        '20141113',
                        '6000'
                        );


INSERT INTO operatie VALUES(NULL, 'Tooth Extraction', '220.0', '1');    -- 1
INSERT INTO operatie VALUES(NULL, 'Tooth Fillings', '180.50', '1');     -- 2
INSERT INTO operatie VALUES(NULL, 'Braces Install', '210.20', '1');     -- 3
INSERT INTO operatie VALUES(NULL, 'Tooth Cleaning', '75.50', '1');      -- 4
INSERT INTO operatie VALUES(NULL, 'Veneers', '120.00', '1');            -- 5
INSERT INTO operatie VALUES(NULL, 'Root Canals', '200.00', '1');        -- 6
INSERT INTO operatie VALUES(NULL, 'Teeth Whitening', '90.50', '1');     -- 7
INSERT INTO operatie VALUES(NULL, 'Dentures', '230.00', '1');           -- 8
INSERT INTO operatie VALUES(NULL, 'Crown', '210.00', '1');              -- 9 
INSERT INTO operatie VALUES(NULL, 'Cap', '195.50', '1');                -- 10
INSERT INTO operatie VALUES(NULL, 'Gum Surgery', '260.00', '1');        -- 11
INSERT INTO operatie VALUES(NULL, 'Dental Radiology', '125.00', '1');   -- 12
INSERT INTO operatie VALUES(NULL, 'Pediatric Dentistry', '75.00', '1'); -- 13


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


DELIMITER // 
CREATE PROCEDURE getClientPass(
    client_email            VARCHAR(40)
    )
BEGIN 
    SELECT client_pass FROM clienti AS c WHERE c.client_email = client_email;
END; //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE insertNewClient(
   client_nume      VARCHAR(56),
   client_email     VARCHAR(40),
   client_pass      CHAR(64),
   client_tel       VARCHAR(15)
)
BEGIN
INSERT INTO clienti VALUES (NULL, client_nume, client_email, client_pass, client_tel);
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE getClientId(
    client_email            VARCHAR(40)
    )
BEGIN 
    SELECT client_id FROM clienti AS c WHERE c.client_email = client_email;
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE getMedicId(
    medic_email            VARCHAR(40)
    )
BEGIN 
    SELECT medic_id FROM medici AS m WHERE m.medic_email = medic_email;
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE getMedicPass(
    medic_email            VARCHAR(40)
    )
BEGIN 
    SELECT medic_pass FROM medici AS m WHERE m.medic_email = medic_email;
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE insertNewAppointment(
    medic_id    INT,
    client_id   INT,       
    data        DATE,
    startTime   TIME(0),
    endTime     TIME(0)
    )
BEGIN 
    INSERT INTO programari VALUES(medic_id, client_id, data, startTime, endTime);
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE selectAppointment(medic_id INT)
BEGIN 
    SELECT c.client_nume, c.client_tel, p.data, p.startTime FROM 
            programari AS p, clienti AS c
            WHERE(p.medic_id = medic_id AND c.client_id = p.client_id);
END; //
DELIMITER ;

    -- SELECT c.client_nume, c.client_tel, p.data, p.startTime FROM 
    --         programari AS p, clienti AS c
    --         WHERE(p.medic_id = 1 AND c.client_id = p.client_id);