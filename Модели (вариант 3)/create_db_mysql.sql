CREATE DATABASE IF NOT EXISTS air_tickets
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE air_tickets;

-- ======================= СПРАВОЧНИКИ =======================

CREATE TABLE cities (
    id    INT AUTO_INCREMENT,
    name  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_cities PRIMARY KEY (id)
);

CREATE TABLE airports (
    id         INT AUTO_INCREMENT,
    city_id    INT           NOT NULL,
    iata_code  CHAR(3)       NOT NULL,
    name       VARCHAR(100)  NOT NULL,
    latitude   DECIMAL(8,6)  NOT NULL,
    longitude  DECIMAL(9,6)  NOT NULL,
    timezone   VARCHAR(50)   NOT NULL,
    CONSTRAINT pk_airports PRIMARY KEY (id),
    CONSTRAINT uq_airports_iata UNIQUE (iata_code),
    CONSTRAINT fk_airports_cities FOREIGN KEY (city_id)
        REFERENCES cities (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_airports_lat CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_airports_lon CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE aircrafts (
    id          INT AUTO_INCREMENT,
    reg_number  VARCHAR(10) NOT NULL,
    model       VARCHAR(50) NOT NULL,
    range_km    INT         NOT NULL,
    CONSTRAINT pk_aircrafts PRIMARY KEY (id),
    CONSTRAINT uq_aircrafts_reg UNIQUE (reg_number),
    CONSTRAINT chk_aircrafts_range CHECK (range_km > 0)
);

CREATE TABLE fare_conditions (
    id    TINYINT AUTO_INCREMENT,
    code  VARCHAR(10) NOT NULL,
    name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_fare_conditions PRIMARY KEY (id),
    CONSTRAINT uq_fare_conditions_code UNIQUE (code)
);

CREATE TABLE flight_statuses (
    id    TINYINT AUTO_INCREMENT,
    code  VARCHAR(20) NOT NULL,
    name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_flight_statuses PRIMARY KEY (id),
    CONSTRAINT uq_flight_statuses_code UNIQUE (code)
);

CREATE TABLE seats (
    id                 INT AUTO_INCREMENT,
    aircraft_id        INT        NOT NULL,
    fare_condition_id  TINYINT    NOT NULL,
    seat_no            VARCHAR(4) NOT NULL,
    CONSTRAINT pk_seats PRIMARY KEY (id),
    CONSTRAINT uq_seats_aircraft_no UNIQUE (aircraft_id, seat_no),
    CONSTRAINT fk_seats_aircrafts FOREIGN KEY (aircraft_id)
        REFERENCES aircrafts (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_seats_fare_conditions FOREIGN KEY (fare_condition_id)
        REFERENCES fare_conditions (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ========================= РАСПИСАНИЕ =========================

CREATE TABLE flights (
    id                    INT AUTO_INCREMENT,
    flight_no             VARCHAR(6)  NOT NULL,
    aircraft_id           INT         NOT NULL,
    departure_airport_id  INT         NOT NULL,
    arrival_airport_id    INT         NOT NULL,
    scheduled_departure   DATETIME    NOT NULL,
    scheduled_arrival     DATETIME    NOT NULL,
    actual_departure      DATETIME    NULL,
    actual_arrival        DATETIME    NULL,
    status_id             TINYINT     NOT NULL,
    CONSTRAINT pk_flights PRIMARY KEY (id),
    CONSTRAINT uq_flights_no_departure UNIQUE (flight_no, scheduled_departure),
    CONSTRAINT fk_flights_aircrafts FOREIGN KEY (aircraft_id)
        REFERENCES aircrafts (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_dep_airports FOREIGN KEY (departure_airport_id)
        REFERENCES airports (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_arr_airports FOREIGN KEY (arrival_airport_id)
        REFERENCES airports (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_statuses FOREIGN KEY (status_id)
        REFERENCES flight_statuses (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_flights_airports CHECK (departure_airport_id <> arrival_airport_id),
    CONSTRAINT chk_flights_schedule CHECK (scheduled_arrival > scheduled_departure)
);

CREATE INDEX ix_flights_departure ON flights (departure_airport_id, scheduled_departure);
CREATE INDEX ix_flights_arrival   ON flights (arrival_airport_id, scheduled_departure);

-- ====================== ПРОДАЖА БИЛЕТОВ ======================

CREATE TABLE passengers (
    id             BIGINT AUTO_INCREMENT,
    last_name      VARCHAR(50)  NOT NULL,
    first_name     VARCHAR(50)  NOT NULL,
    middle_name    VARCHAR(50)  NULL,
    birth_date     DATE         NOT NULL,
    document_type  VARCHAR(20)  NOT NULL,
    document_no    VARCHAR(20)  NOT NULL,
    phone          VARCHAR(20)  NULL,
    email          VARCHAR(100) NULL,
    CONSTRAINT pk_passengers PRIMARY KEY (id),
    CONSTRAINT uq_passengers_document UNIQUE (document_type, document_no)
);

CREATE TABLE bookings (
    id             BIGINT AUTO_INCREMENT,
    book_ref       CHAR(6)        NOT NULL,
    booked_at      DATETIME       NOT NULL,
    total_amount   DECIMAL(10,2)  NOT NULL,
    contact_phone  VARCHAR(20)    NULL,
    contact_email  VARCHAR(100)   NULL,
    CONSTRAINT pk_bookings PRIMARY KEY (id),
    CONSTRAINT uq_bookings_ref UNIQUE (book_ref),
    CONSTRAINT chk_bookings_amount CHECK (total_amount >= 0)
);

CREATE TABLE tickets (
    id            BIGINT AUTO_INCREMENT,
    ticket_no     CHAR(13) NOT NULL,
    booking_id    BIGINT   NOT NULL,
    passenger_id  BIGINT   NOT NULL,
    CONSTRAINT pk_tickets PRIMARY KEY (id),
    CONSTRAINT uq_tickets_no UNIQUE (ticket_no),
    CONSTRAINT fk_tickets_bookings FOREIGN KEY (booking_id)
        REFERENCES bookings (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tickets_passengers FOREIGN KEY (passenger_id)
        REFERENCES passengers (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE ticket_flights (
    id                 BIGINT AUTO_INCREMENT,
    ticket_id          BIGINT        NOT NULL,
    flight_id          INT           NOT NULL,
    fare_condition_id  TINYINT       NOT NULL,
    amount             DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_ticket_flights PRIMARY KEY (id),
    CONSTRAINT uq_ticket_flights UNIQUE (ticket_id, flight_id),
    CONSTRAINT fk_ticket_flights_tickets FOREIGN KEY (ticket_id)
        REFERENCES tickets (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ticket_flights_flights FOREIGN KEY (flight_id)
        REFERENCES flights (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_flights_fare FOREIGN KEY (fare_condition_id)
        REFERENCES fare_conditions (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_ticket_flights_amount CHECK (amount >= 0)
);

CREATE TABLE boarding_passes (
    id                BIGINT AUTO_INCREMENT,
    ticket_flight_id  BIGINT   NOT NULL,
    seat_id           INT      NOT NULL,
    boarding_no       SMALLINT NOT NULL,
    CONSTRAINT pk_boarding_passes PRIMARY KEY (id),
    CONSTRAINT uq_boarding_passes_tf UNIQUE (ticket_flight_id),
    CONSTRAINT fk_boarding_passes_tf FOREIGN KEY (ticket_flight_id)
        REFERENCES ticket_flights (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_boarding_passes_seats FOREIGN KEY (seat_id)
        REFERENCES seats (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_boarding_passes_no CHECK (boarding_no > 0)
);

-- Одно место не может быть выдано дважды на одном рейсе. Рейс определяется
-- через ticket_flights, поэтому правило проверяется триггером.
DELIMITER $$
CREATE TRIGGER trg_boarding_passes_seat_unique
BEFORE INSERT ON boarding_passes
FOR EACH ROW
BEGIN
    DECLARE v_flight_id INT;
    DECLARE v_cnt INT;
    SELECT flight_id INTO v_flight_id
        FROM ticket_flights WHERE id = NEW.ticket_flight_id;
    SELECT COUNT(*) INTO v_cnt
        FROM boarding_passes bp
        JOIN ticket_flights tf ON tf.id = bp.ticket_flight_id
        WHERE tf.flight_id = v_flight_id AND bp.seat_id = NEW.seat_id;
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Место уже занято на этом рейсе';
    END IF;
END$$
DELIMITER ;

-- ===================== СЛУЖЕБНЫЕ ОБЪЕКТЫ =====================

-- Количество свободных мест на рейсе.
CREATE VIEW v_flight_free_seats AS
SELECT f.id            AS flight_id,
       f.flight_no,
       f.scheduled_departure,
       (SELECT COUNT(*) FROM seats s WHERE s.aircraft_id = f.aircraft_id)
       - (SELECT COUNT(*) FROM ticket_flights tf WHERE tf.flight_id = f.id) AS free_seats
FROM flights f;

-- Количество аэропортов в городе.
CREATE VIEW v_city_airports AS
SELECT c.id AS city_id, c.name, COUNT(a.id) AS airports_amount
FROM cities c
LEFT JOIN airports a ON a.city_id = c.id
GROUP BY c.id, c.name;
