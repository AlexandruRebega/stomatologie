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
END
DELIMITER ;

