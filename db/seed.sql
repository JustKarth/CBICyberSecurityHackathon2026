--Made this using AI
-- =========================================================
-- USERS
-- =========================================================

INSERT INTO users(
    acc_holder_name,
    acc_holder_phone_no,
    acc_holder_dob,
    pass_hash,
    has_PAN,
    PAN_hash,
    email
)
VALUES
('Rahul Sharma','9876543210','2000-05-10','hash1',TRUE,'panhash1','rahul@example.com'),
('Priya Verma','9123456780','1999-08-21','hash2',TRUE,'panhash2','priya@example.com'),
('Arjun Reddy','9012345678','2001-01-15','hash3',TRUE,'panhash3','arjun@example.com'),
('Sneha Kapoor','9988776655','2002-03-11','hash4',TRUE,'panhash4','sneha@example.com'),
('Karan Mehta','9876501234','1998-12-01','hash5',TRUE,'panhash5','karan@example.com'),
('Aditi Rao','9765432101','2001-06-19','hash6',TRUE,'panhash6','aditi@example.com'),
('Vikram Singh','9654321098','1997-02-14','hash7',TRUE,'panhash7','vikram@example.com'),
('Neha Joshi','9543210987','1996-09-30','hash8',TRUE,'panhash8','neha@example.com'),
('Ramesh Kumar','9432109876','1985-11-30','hash9',FALSE,NULL,'ramesh@example.com'),
('Pooja Nair','9321098765','2003-04-05','hash10',TRUE,'panhash10','pooja@example.com'),
('Manoj Patel','9210987654','1994-08-09','hash11',TRUE,'panhash11','manoj@example.com'),
('Ishita Sen','9109876543','2000-10-20','hash12',TRUE,'panhash12','ishita@example.com');

INSERT INTO users(
    acc_holder_name,
    acc_holder_phone_no,
    acc_holder_dob,
    pass_hash,
    has_PAN,
    form_60_acknowledgement_no,
    email
)
VALUES
('Temporary User','9090909090','1990-01-01','hash13',FALSE,'FORM60-001','temp@example.com');



-- =========================================================
-- ACCOUNTS
-- =========================================================

INSERT INTO accounts(
    user_id,
    acc_no,
    IFSC_code,
    current_balance,
    acc_status,
    daily_transfer_limit
)
VALUES
(1,'100000000001','SBIN0001001',85000.00,'ACTIVE',100000),
(2,'100000000002','HDFC0002002',42000.00,'ACTIVE',75000),
(3,'100000000003','ICIC0003003',120000.00,'ACTIVE',200000),
(4,'100000000004','AXIS0004004',5000.00,'BLOCKED',25000),
(5,'100000000005','KKBK0005005',15000.00,'ACTIVE',50000),
(6,'100000000006','SBIN0006006',76000.00,'ACTIVE',100000),
(7,'100000000007','YES0007007',250000.00,'ACTIVE',300000),
(8,'100000000008','PNB0008008',8000.00,'ACTIVE',30000),
(9,'100000000009','IDFB0009009',95000.00,'ACTIVE',80000),
(10,'100000000010','BARB001010',45000.00,'ACTIVE',60000),
(11,'100000000011','CNRB001111',72000.00,'ACTIVE',70000),
(12,'100000000012','UBIN001212',130000.00,'ACTIVE',150000),
(13,'100000000013','IOBA001313',2000.00,'ACTIVE',10000);



-- =========================================================
-- MERCHANTS
-- =========================================================

INSERT INTO merchants(
    merchant_name,
    merchant_account_id,
    acquiring_bank,
    merchant_status
)
VALUES
('Amazon',2,'HDFC Bank','ACTIVE'),
('Flipkart',3,'ICICI Bank','ACTIVE'),
('Swiggy',5,'Kotak Bank','ACTIVE'),
('Zomato',6,'SBI Bank','ACTIVE'),
('Steam Games',7,'YES Bank','ACTIVE'),
('Fake Electronics Store',4,'Unknown Bank','SUSPENDED'),
('CryptoQuick',8,'Unknown Bank','BLOCKED'),
('Myntra',9,'IDFC Bank','ACTIVE'),
('Uber',10,'BOB Bank','ACTIVE'),
('BookMyShow',11,'Canara Bank','ACTIVE');



-- =========================================================
-- DEVICES
-- =========================================================

INSERT INTO known_devices(
    device_fingerprint,
    user_agent
)
VALUES
('device_fp_001','Chrome Windows 11'),
('device_fp_002','Firefox Ubuntu'),
('device_fp_003','Safari iPhone'),
('device_fp_004','Edge Windows 10'),
('device_fp_005','Chrome Android'),
('device_fp_006','Opera Linux'),
('device_fp_007','Safari MacOS'),
('device_fp_008','Chrome Android Samsung'),
('device_fp_009','Brave Windows'),
('device_fp_010','Firefox Android');



-- =========================================================
-- LOGINS
-- =========================================================

INSERT INTO logins(
    user_id,
    attempted_username,
    device_id,
    session_status,
    ip_address,
    login_location
)
VALUES
(1,'rahul@example.com',1,'LOGGED_IN','192.168.1.10','Hyderabad'),
(2,'priya@example.com',2,'FAILED','45.113.22.11','Delhi'),
(3,'arjun@example.com',3,'LOGGED_OUT','103.88.77.66','Bangalore'),
(4,'sneha@example.com',4,'BLOCKED','188.21.44.11','Moscow'),
(5,'karan@example.com',5,'LOGGED_IN','122.172.1.1','Mumbai'),
(6,'aditi@example.com',6,'LOGGED_OUT','49.32.10.8','Chennai'),
(7,'vikram@example.com',7,'FAILED','91.22.11.9','Berlin'),
(8,'neha@example.com',8,'LOGGED_IN','172.16.1.7','Pune'),
(9,'ramesh@example.com',9,'FAILED','202.54.11.90','Unknown'),
(10,'pooja@example.com',10,'LOGGED_OUT','33.55.77.11','Kochi');



-- =========================================================
-- BENEFICIARIES
-- =========================================================

INSERT INTO beneficiaries(
    user_id,
    target_acc_id,
    nickname
)
VALUES
(1,2,'Priya'),
(1,3,'Arjun'),
(2,1,'Rahul'),
(3,5,'Karan'),
(5,7,'Vikram'),
(6,8,'Neha'),
(7,10,'Pooja'),
(8,12,'Ishita');



-- =========================================================
-- TRANSACTIONS
-- =========================================================

INSERT INTO transactions(
    acc_id,
    transaction_amount,
    transaction_status,
    recipient_id,
    transaction_type
)
VALUES
(1,2500.00,'SUCCESS',2,'P2P_TRANSFER'),
(2,1000.00,'SUCCESS',3,'P2P_TRANSFER'),
(3,5500.00,'SUCCESS',5,'P2P_TRANSFER'),
(5,900.00,'SUCCESS',1,'P2P_TRANSFER'),
(6,15000.00,'SUCCESS',7,'P2P_TRANSFER'),
(7,50000.00,'SUCCESS',3,'P2P_TRANSFER'),
(8,2000.00,'FAILED',2,'P2P_TRANSFER'),
(9,1200.00,'SUCCESS',6,'P2P_TRANSFER'),
(10,3500.00,'SUCCESS',8,'P2P_TRANSFER'),
(11,99999.00,'BLOCKED',1,'P2P_TRANSFER'),
(12,45000.00,'SUCCESS',7,'P2P_TRANSFER'),
(1,75000.00,'BLOCKED',9,'P2P_TRANSFER');



-- =========================================================
-- MERCHANT TRANSACTIONS
-- =========================================================

INSERT INTO transactions(
    acc_id,
    transaction_amount,
    transaction_status,
    merchant_id,
    product_code,
    transaction_type
)
VALUES
(1,4999.00,'SUCCESS',1,'PRD001','MERCHANT_PAYMENT'),
(2,899.00,'SUCCESS',3,'FOOD01','MERCHANT_PAYMENT'),
(3,12000.00,'SUCCESS',5,'GAME22','MERCHANT_PAYMENT'),
(4,75000.00,'BLOCKED',6,'SCAM01','MERCHANT_PAYMENT'),
(5,3500.00,'SUCCESS',8,'FASH11','MERCHANT_PAYMENT'),
(6,999.00,'SUCCESS',4,'FOOD88','MERCHANT_PAYMENT'),
(7,150000.00,'BLOCKED',7,'CRYPTO','MERCHANT_PAYMENT'),
(8,1200.00,'SUCCESS',9,'CAB101','MERCHANT_PAYMENT'),
(9,450.00,'SUCCESS',10,'MOV555','MERCHANT_PAYMENT'),
(10,6700.00,'SUCCESS',1,'TECH22','MERCHANT_PAYMENT'),
(11,25000.00,'SUCCESS',2,'ELX111','MERCHANT_PAYMENT'),
(12,99999.00,'BLOCKED',6,'FRAUDX','MERCHANT_PAYMENT');



-- =========================================================
-- TELEMETRY
-- =========================================================

INSERT INTO data_telemetry(
    user_id,
    login_id,
    entry_trigger,
    transaction_id,
    avg_mouse_speed,
    avg_typing_speed,
    avg_click_speed,
    amount_to_balance_percentage,
    amount_to_limit_percentage,
    no_of_prior_transfers_to_recipient,
    travel_speed,
    failed_logins,
    copy_paste_used,
    deviation_from_avg_amount,
    frequency_of_transactions,
    VPN_probability
)
VALUES
(1,1,'HIGH_VALUE_TRANSACTION',13,120.5,85,40,0.25,0.10,5,15,0,0,1500,3,0.02),
(3,3,'SUSPICIOUS_MERCHANT_PAYMENT',16,300,15,120,0.80,0.90,0,950,4,7,60000,15,0.95),
(4,4,'IMPOSSIBLE_TRAVEL',16,500,10,150,0.95,1.00,0,5000,8,10,70000,20,0.99),
(5,5,'RAPID_TRANSFERS',5,140,60,70,0.45,0.30,10,40,0,1,2500,11,0.10),
(6,6,'VPN_LOGIN',18,100,55,60,0.15,0.05,2,25,1,0,500,2,0.82),
(7,7,'FAILED_LOGINS',19,250,20,130,0.70,0.95,0,1000,9,4,90000,18,0.97),
(8,8,'NORMAL_ACTIVITY',20,110,80,35,0.05,0.02,6,12,0,0,100,1,0.01),
(9,9,'UNKNOWN_LOCATION',21,400,12,140,0.85,0.88,0,3000,7,6,50000,14,0.93);



-- =========================================================
-- FRAUD SCORES
-- =========================================================

INSERT INTO fraud_scores(
    transaction_id,
    login_id,
    risk_score,
    fraud_probability,
    ml_model_version
)
VALUES
(16,3,95.50,0.982100,'fraud_model_v1'),
(13,1,22.10,0.102300,'fraud_model_v1'),
(17,4,99.90,0.999100,'fraud_model_v1'),
(19,7,88.75,0.911000,'fraud_model_v1'),
(21,9,92.40,0.955000,'fraud_model_v2'),
(18,6,65.10,0.701100,'fraud_model_v2'),
(20,8,10.00,0.010100,'fraud_model_v1');



-- =========================================================
-- FRAUD ALERTS
-- =========================================================

INSERT INTO fraud_alerts(
    transaction_id,
    user_id,
    fraud_score_id,
    alert_message,
    alert_status
)
VALUES
(16,4,1,'High probability fraudulent merchant transaction detected','OPEN'),
(17,7,3,'Possible crypto laundering transaction','INVESTIGATING'),
(19,7,4,'Rapid high value suspicious transfers','OPEN'),
(21,9,5,'Impossible travel login and payment pattern','OPEN'),
(18,6,6,'VPN-based suspicious transaction','FALSE_POSITIVE');



-- =========================================================
-- NOTIFICATIONS
-- =========================================================

INSERT INTO notification_logs(
    user_id,
    alert_id,
    notification_type,
    notification_status,
    sent_at
)
VALUES
(4,1,'EMAIL','SENT',CURRENT_TIMESTAMP),
(4,1,'SMS','SENT',CURRENT_TIMESTAMP),
(7,2,'EMAIL','SENT',CURRENT_TIMESTAMP),
(7,3,'PUSH_NOTIFICATION','SENT',CURRENT_TIMESTAMP),
(9,4,'SMS','FAILED',CURRENT_TIMESTAMP),
(6,5,'EMAIL','SENT',CURRENT_TIMESTAMP);



-- =========================================================
-- SUSPICIOUS SESSIONS
-- =========================================================

INSERT INTO suspicious_sessions(
    login_id,
    suspicion_reason,
    severity,
    resolved
)
VALUES
(4,'Login from impossible geographic location',10,FALSE),
(7,'Multiple failed logins followed by high value transaction',9,FALSE),
(9,'VPN and TOR exit node detected',8,FALSE),
(3,'Abnormally high transaction velocity',7,TRUE),
(6,'Frequent IP switching during session',6,FALSE);