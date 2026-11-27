CREATE TABLE theatre (
theatre_id BIGINT AUTO_INCREMENT PRIMARY KEY,
theatre_name VARCHAR(150) NOT NULL,
city VARCHAR(100) NOT NULL,
address VARCHAR(500) NOT NULL
);


CREATE TABLE screen (
screen_id BIGINT AUTO_INCREMENT PRIMARY KEY,
theatre_id BIGINT NOT NULL,
screen_name VARCHAR(100) NOT NULL,
capacity INT NOT NULL,
FOREIGN KEY(theatre_id) REFERENCES theatre(theatre_id)
);

CREATE TABLE seat (
seat_id BIGINT AUTO_INCREMENT PRIMARY KEY,
screen_id BIGINT NOT NULL,
row_label VARCHAR(10),
seat_number INT,
seat_type ENUM('REGULAR','PREMIUM','RECLINER'),
UNIQUE(screen_id,row_label,seat_number),
FOREIGN KEY(screen_id) REFERENCES screen(screen_id)
);
ALTER TABLE seat AUTO_INCREMENT = 1001;


CREATE TABLE show_details (
show_id BIGINT AUTO_INCREMENT PRIMARY KEY,
screen_id BIGINT NOT NULL,
movie_name VARCHAR(255),
show_date DATE,
start_time DATETIME,
end_time DATETIME,
FOREIGN KEY(screen_id) REFERENCES screen(screen_id)
);


ALTER TABLE show_details AUTO_INCREMENT = 5001;

CREATE TABLE show_seat_inventory (
inventory_id BIGINT AUTO_INCREMENT PRIMARY KEY,
show_id BIGINT NOT NULL,
seat_id BIGINT NOT NULL,
seat_status ENUM(
'AVAILABLE','HELD','PAYMENT_IN_PROGRESS','BOOKED'
) DEFAULT 'AVAILABLE',
lock_user_id BIGINT,
hold_started_at DATETIME,
hold_expires_at DATETIME,
payment_started_at DATETIME,
booking_id BIGINT,
version_no INT DEFAULT 1,
UNIQUE(show_id, seat_id),
INDEX idx_show_status(show_id, seat_status),
INDEX idx_hold_expiry(hold_expires_at)
);


CREATE TABLE booking (
booking_id BIGINT AUTO_INCREMENT PRIMARY KEY,
show_id BIGINT NOT NULL,
user_id BIGINT NOT NULL,
booking_status ENUM('PENDING','CONFIRMED','FAILED','CANCELLED'),
created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE payment_transaction (
payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
booking_id BIGINT,
gateway_order_id VARCHAR(255) UNIQUE,
gateway_payment_id VARCHAR(255),
amount DECIMAL(10,2),
payment_status ENUM('INITIATED','SUCCESS','FAILED')
);


CREATE TABLE webhook_event (
event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
gateway_event_id VARCHAR(255) UNIQUE,
payment_id BIGINT,
event_type VARCHAR(50),
processed_at DATETIME
);


/***********************Insert in theatre table***********************/
INSERT INTO theatre
(
    theatre_name,
    city,
    address
)
VALUES
(
    'PVR Ambience Mall',
    'Gurgaon',
    'Ambience Mall, NH-8'
);

/***********************Insert in screen table***********************/
INSERT INTO screen
(
    theatre_id,
    screen_name,
    capacity
)
VALUES
(1,'Screen 1',250),(1,'Screen 2',180);

/***********************Insert in seat table***********************/
INSERT INTO seat
(
    
    screen_id,
    row_label,
    seat_number,
    seat_type)
VALUES
(1,'A',1,'PREMIUM'), (1,'A',2,'PREMIUM'), 
(1,'A',3,'PREMIUM'), (1,'B',1,'REGULAR'), 
(1,'B',2,'REGULAR'), (1,'B',3,'REGULAR'),
(1,'C',1,'RECLINER'), 
(1,'C',2,'RECLINER'), (1,'C',3,'RECLINER');

/***********************Insert in show_details table***********************/
INSERT INTO show_details
(
    screen_id,
    movie_name,
    show_date,
    start_time,
    end_time
)
VALUES
(
    1,
    'Avengers Endgame',
    '2026-12-01',
    '2026-12-01 18:00:00',
    '2026-12-01 21:00:00'
),

(
    1,
    'Avengers Endgame',
    '2026-12-01',
    '2026-12-01 22:00:00',
    '2026-12-02 01:00:00'
);

/***********************Insert in show_seat_inventory table***********************/
INSERT INTO show_seat_inventory
(
    show_id,
    seat_id,
    seat_status,
    version_no
)
VALUES

(5001,1001,'AVAILABLE',1),
(5001,1002,'AVAILABLE',1),
(5001,1003,'AVAILABLE',1),
(5001,1004,'AVAILABLE',1),
(5001,1005,'AVAILABLE',1),
(5001,1006,'AVAILABLE',1),
(5001,1007,'AVAILABLE',1),
(5001,1008,'AVAILABLE',1),
(5001,1009,'AVAILABLE',1),
(5002,1001,'AVAILABLE',1),
(5002,1002,'AVAILABLE',1),
(5002,1003,'AVAILABLE',1),
(5002,1004,'AVAILABLE',1),
(5002,1005,'AVAILABLE',1),
(5002,1006,'AVAILABLE',1),
(5002,1007,'AVAILABLE',1),
(5002,1008,'AVAILABLE',1),
(5002,1009,'AVAILABLE',1);

/*Select * from tables screen, seat and show_details*/
select * from screen;
select * from seat;
select * from show_details;

/***********************User Holds Seat A1***********************/
UPDATE show_seat_inventory
SET
    seat_status='HELD',
    lock_user_id=101,
    hold_started_at=NOW(),
    hold_expires_at=DATE_ADD(NOW(),INTERVAL 5 MINUTE)
WHERE inventory_id=1;


/***********************Booking***********************/
INSERT INTO booking
(
    booking_id,
    show_id,
    user_id,
    booking_status,
    created_at
)
VALUES
(
    9001,
    5001,
    101,
    'PENDING',
    NOW()
);

/***********************Payment Started***********************/
UPDATE show_seat_inventory
SET
    seat_status='PAYMENT_IN_PROGRESS',
    payment_started_at=NOW()
WHERE inventory_id=1;

/***********************Payment Transaction***********************/
INSERT INTO payment_transaction
(
    payment_id,
    booking_id,
    gateway_order_id,
    gateway_payment_id,
    amount,
    payment_status
)
VALUES
(
    7001,
    9001,
    'ORDER_ABC123',
    'PAY_XYZ456',
    550.00,
    'SUCCESS'
);

/***********************-On getting Webhook Event of successful payment***********************/
INSERT INTO webhook_event
(
    event_id,
    gateway_event_id,
    payment_id,
    event_type,
    processed_at
)
VALUES
(
    8001,
    'EVT_SUCCESS_001',
    7001,
    'PAYMENT_SUCCESS',
    NOW()
);

/***********************update booking status to confirmed***********************/
UPDATE booking
SET booking_status='CONFIRMED'
WHERE booking_id=9001;


/***********************update seat status to booked***********************/
UPDATE show_seat_inventory
SET
    seat_status='BOOKED',
    booking_id=9001,
    hold_expires_at=NULL
WHERE inventory_id=1;



/***********************Select query to get count of available seat of all shows of theatre for a particular date***********************/
SELECT
s.show_id,
s.movie_name,
s.show_date,
TIME_FORMAT(s.start_time,'%H:%i') AS start_time,
TIME_FORMAT(s.end_time,'%H:%i') AS end_time,
sc.screen_name,
group_query.seat_type,
group_query.available_seats
FROM show_details s
JOIN screen sc ON s.screen_id=sc.screen_id
JOIN (select sh.show_id,count(*) as available_seats, s.seat_type from show_seat_inventory inven, seat s, screen sc , show_details sh
where sc.screen_id = sh.screen_id
and sh.screen_id = s.screen_id
and s.seat_id = inven.seat_id 
and inven.show_id = sh.show_id
and inven.seat_status='AVAILABLE'
group by seat_type, show_id) group_query ON group_query.show_id = s.show_id
WHERE sc.theatre_id=1
and s.show_date='2026-12-01'
ORDER BY s.start_time;

