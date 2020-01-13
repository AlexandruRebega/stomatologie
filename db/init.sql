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


CREATE TABLE programari (
    medic_id    INT UNSIGNED    NOT NULL,
    client_id   INT UNSIGNED    NOT NULL,       
    data        DATE            NOT NULL,
    startTime   TIME(0)         NOT NULL,
    endTime     TIME(0)         NOT NULL,
    operatie_id INT,

    CONSTRAINT PRIMARY KEY (medic_id, data, startTime),

    FOREIGN KEY (operatie_id)
        REFERENCES operatie(operatie_id),

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


-- CREATE TABLE Numbers (number INT UNSIGNED PRIMARY KEY);

-- DELIMITER //
-- CREATE PROCEDURE populateNumbers()
-- BEGIN
--     SET @x = 0;
--     WHILE @x < 1024 DO
--         INSERT INTO Numbers VALUES (@x);
--         SET @x = @x + 1;
--     END WHILE;
--     SET @x = NULL;
-- END; //
-- DELIMITER ;

-- CALL populateNumbers;
-- DROP PROCEDURE populateNumbers;


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
    endTime     TIME(0),
    operatie_id INT
    )
BEGIN 
    INSERT INTO programari VALUES(medic_id, client_id, data, startTime, endTime, operatie_id);
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE selectAppointment(medic_id INT)
BEGIN 
    SELECT c.client_nume, c.client_tel, p.data, p.startTime, p.operatie_id, op.operatie_nume 
        FROM 
            programari AS p, clienti AS c, operatie AS op
        WHERE(p.medic_id = medic_id AND 
              c.client_id = p.client_id AND 
              op.operatie_id = p.operatie_id);
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE getAllOperations()
BEGIN 
    SELECT * FROM operatie;
END; //
DELIMITER ;

DELIMITER // 
CREATE PROCEDURE getAllDiscountOperations(
    client_email VARCHAR(40))
BEGIN 
    SELECT o.operatie_id, o.operatie_nume, o.operatie_pret, FORMAT(0.8 * o.operatie_pret, 2) AS operatie_discount, o.operatie_durata
    FROM operatie AS o,
         clienti AS c,
         istoric AS i
    WHERE (c.client_email = client_email AND
           i.client_id = c.client_id AND
           o.operatie_pret > 200 AND
           (SELECT COUNT(*) FROM istoric AS j
            WHERE j.client_id = c.client_id AND
            j.istoric_data > DATE_SUB(now(), INTERVAL 6 MONTH)) > 3)
    GROUP BY o.operatie_id;
END; //
DELIMITER ;

DELIMITER // 
CREATE PROCEDURE insertNewIstoricRecord(
    operatie_id     INT,
    client_id       INT,
    istoric_data    DATE)
BEGIN 
    INSERT INTO istoric VALUES (NULL, operatie_id, client_id, istoric_data);
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE getAllIstoricRecords()
BEGIN 
    SELECT * FROM istoric;
END; //
DELIMITER ;


DELIMITER // 
CREATE PROCEDURE getClientRecords(client_id INT)
BEGIN 
    SELECT c.client_nume, c.client_tel, o.operatie_nume, i.istoric_data
    FROM clienti AS c,
         istoric AS i,
         operatie AS o
         WHERE (i.client_id = client_id AND 
                i.client_id = c.client_id AND
                i.operatie_id = o.operatie_id);
END; //
DELIMITER ;


-- START EVENT THREAD
SET GLOBAL event_scheduler = ON;

DELIMITER // 
CREATE EVENT removeOldAppointmetsEvent
    ON SCHEDULE
      EVERY 1 DAY
ON COMPLETION PRESERVE
    DO
      BEGIN
            INSERT INTO istoric (operatie_id, client_id, data)
                SELECT operatie_id, client_id, data FROM programari AS p
                WHERE p.data <= DATE(NOW());
            DELETE FROM programari p WHERE p.data <= DATE(NOW());
      END //

DELIMITER ;

-- insert into programari values('1', '1', '20190420', '09:00:00', '10:00:00', '7' );
-- This procedure is not used by the application but can be used to manually test the remove event:'removeOldAppointmetsEvent'
DELIMITER // 
CREATE PROCEDURE testRemoveEvent()
    BEGIN 
        INSERT INTO istoric (operatie_id, client_id, istoric_data)
            SELECT operatie_id, client_id, data 
            FROM programari AS p
            WHERE p.data <= DATE(NOW());
        DELETE FROM programari p WHERE p.data <= DATE(NOW());
    END; //
DELIMITER ;

