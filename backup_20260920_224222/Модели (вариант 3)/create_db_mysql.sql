CREATE DATABASE IF NOT EXISTS air_tickets
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE air_tickets;

-- ======================= СПРАВОЧНИКИ =======================

CREATE TABLE countries (
    id        INT AUTO_INCREMENT,
    name      VARCHAR(100) NOT NULL,
    iso_code  CHAR(2)      NOT NULL,
    CONSTRAINT pk_countries PRIMARY KEY (id),
    CONSTRAINT uq_countries_iso UNIQUE (iso_code)
);

CREATE TABLE cities (
    id          INT AUTO_INCREMENT,
    country_id  INT          NOT NULL,
    name        VARCHAR(100) NOT NULL,
    timezone    VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_cities PRIMARY KEY (id),
    CONSTRAINT fk_cities_countries FOREIGN KEY (country_id)
        REFERENCES countries (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE airports (
    id         INT AUTO_INCREMENT,
    city_id    INT           NOT NULL,
    iata_code  CHAR(3)       NOT NULL,
    icao_code  CHAR(4)       NULL,
    name       VARCHAR(100)  NOT NULL,
    latitude   DECIMAL(8,6)  NOT NULL,
    longitude  DECIMAL(9,6)  NOT NULL,
    CONSTRAINT pk_airports PRIMARY KEY (id),
    CONSTRAINT uq_airports_iata UNIQUE (iata_code),
    CONSTRAINT fk_airports_cities FOREIGN KEY (city_id)
        REFERENCES cities (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_airports_lat CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_airports_lon CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE airlines (
    id         INT AUTO_INCREMENT,
    iata_code  CHAR(2)      NOT NULL,
    name       VARCHAR(100) NOT NULL,
    CONSTRAINT pk_airlines PRIMARY KEY (id),
    CONSTRAINT uq_airlines_iata UNIQUE (iata_code)
);

CREATE TABLE aircraft_models (
    id            INT AUTO_INCREMENT,
    name          VARCHAR(50) NOT NULL,
    manufacturer  VARCHAR(50) NOT NULL,
    range_km      INT         NOT NULL,
    CONSTRAINT pk_aircraft_models PRIMARY KEY (id),
    CONSTRAINT chk_models_range CHECK (range_km > 0)
);

CREATE TABLE aircrafts (
    id          INT AUTO_INCREMENT,
    model_id    INT         NOT NULL,
    airline_id  INT         NOT NULL,
    reg_number  VARCHAR(10) NOT NULL,
    built_year  SMALLINT    NULL,
    CONSTRAINT pk_aircrafts PRIMARY KEY (id),
    CONSTRAINT uq_aircrafts_reg UNIQUE (reg_number),
    CONSTRAINT fk_aircrafts_models FOREIGN KEY (model_id)
        REFERENCES aircraft_models (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aircrafts_airlines FOREIGN KEY (airline_id)
        REFERENCES airlines (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE fare_conditions (
    id    TINYINT AUTO_INCREMENT,
    code  VARCHAR(10) NOT NULL,
    name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_fare_conditions PRIMARY KEY (id),
    CONSTRAINT uq_fare_conditions_code UNIQUE (code)
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

CREATE TABLE flight_statuses (
    id    TINYINT AUTO_INCREMENT,
    code  VARCHAR(20) NOT NULL,
    name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_flight_statuses PRIMARY KEY (id),
    CONSTRAINT uq_flight_statuses_code UNIQUE (code)
);

CREATE TABLE booking_statuses (
    id    TINYINT AUTO_INCREMENT,
    code  VARCHAR(20) NOT NULL,
    name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_booking_statuses PRIMARY KEY (id),
    CONSTRAINT uq_booking_statuses_code UNIQUE (code)
);

-- ========================= РЕЙСЫ ===========================

CREATE TABLE flights (
    id                    INT AUTO_INCREMENT,
    flight_no             VARCHAR(6) NOT NULL,
    airline_id            INT        NOT NULL,
    aircraft_id           INT        NOT NULL,
    departure_airport_id  INT        NOT NULL,
    arrival_airport_id    INT        NOT NULL,
    scheduled_departure   DATETIME   NOT NULL,
    scheduled_arrival     DATETIME   NOT NULL,
    actual_departure      DATETIME   NULL,
    actual_arrival        DATETIME   NULL,
    status_id             TINYINT    NOT NULL,
    CONSTRAINT pk_flights PRIMARY KEY (id),
    CONSTRAINT uq_flights_no_departure UNIQUE (flight_no, scheduled_departure),
    CONSTRAINT fk_flights_airlines FOREIGN KEY (airline_id)
        REFERENCES airlines (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_aircrafts FOREIGN KEY (aircraft_id)
        REFERENCES aircrafts (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_dep_airports FOREIGN KEY (departure_airport_id)
        REFERENCES airports (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_arr_airports FOREIGN KEY (arrival_airport_id)
        REFERENCES airports (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_flights_statuses FOREIGN KEY (status_id)
        REFERENCES flight_statuses (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_flights_airports CHECK (departure_airport_id <> arrival_airport_id),
    CONSTRAINT chk_flights_time CHECK (scheduled_arrival > scheduled_departure)
);

CREATE INDEX ix_flights_departure ON flights (scheduled_departure);
CREATE INDEX ix_flights_route ON flights (departure_airport_id, arrival_airport_id, scheduled_departure);

-- ======================== ПРОДАЖИ ==========================

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
    status_id      TINYINT        NOT NULL,
    total_amount   DECIMAL(10,2)  NOT NULL,
    currency_code  CHAR(3)        NOT NULL DEFAULT 'BYN',
    contact_email  VARCHAR(100)   NULL,
    contact_phone  VARCHAR(20)    NULL,
    CONSTRAINT pk_bookings PRIMARY KEY (id),
    CONSTRAINT uq_bookings_ref UNIQUE (book_ref),
    CONSTRAINT fk_bookings_statuses FOREIGN KEY (status_id)
        REFERENCES booking_statuses (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_bookings_amount CHECK (total_amount >= 0)
);

CREATE TABLE tickets (
    id            BIGINT AUTO_INCREMENT,
    ticket_no     CHAR(13) NOT NULL,
    booking_id    BIGINT   NOT NULL,
    passenger_id  BIGINT   NOT NULL,
    issued_at     DATETIME NOT NULL,
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
    currency_code      CHAR(3)       NOT NULL DEFAULT 'BYN',
    CONSTRAINT pk_ticket_flights PRIMARY KEY (id),
    CONSTRAINT uq_ticket_flights UNIQUE (ticket_id, flight_id),
    CONSTRAINT uq_ticket_flights_id_flight UNIQUE (id, flight_id),
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
    ticket_flight_id  BIGINT      NOT NULL,
    flight_id         INT         NOT NULL,
    seat_id           INT         NOT NULL,
    boarding_no       SMALLINT    NOT NULL,
    issued_at         DATETIME    NOT NULL,
    gate              VARCHAR(10) NULL,
    CONSTRAINT pk_boarding_passes PRIMARY KEY (id),
    CONSTRAINT uq_boarding_passes_tf UNIQUE (ticket_flight_id),
    CONSTRAINT uq_boarding_passes_seat UNIQUE (flight_id, seat_id),
    CONSTRAINT fk_boarding_passes_tf FOREIGN KEY (ticket_flight_id, flight_id)
        REFERENCES ticket_flights (id, flight_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_boarding_passes_seats FOREIGN KEY (seat_id)
        REFERENCES seats (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_boarding_no CHECK (boarding_no > 0)
);

CREATE TABLE payments (
    id             BIGINT AUTO_INCREMENT,
    booking_id     BIGINT        NOT NULL,
    paid_at        DATETIME      NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    currency_code  CHAR(3)       NOT NULL DEFAULT 'BYN',
    method         VARCHAR(20)   NOT NULL,
    CONSTRAINT pk_payments PRIMARY KEY (id),
    CONSTRAINT fk_payments_bookings FOREIGN KEY (booking_id)
        REFERENCES bookings (id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
);

-- Количество свободных мест на рейсе (вместо производных атрибутов
-- city.airports_amount и Booking.total_book_ammount исходной модели)
CREATE VIEW v_flight_free_seats AS
SELECT f.id AS flight_id,
       f.flight_no,
       f.scheduled_departure,
       COUNT(DISTINCT s.id) - COUNT(DISTINCT tf.id) AS free_seats
FROM flights f
         JOIN seats s ON s.aircraft_id = f.aircraft_id
         LEFT JOIN ticket_flights tf ON tf.flight_id = f.id
GROUP BY f.id, f.flight_no, f.scheduled_departure;
