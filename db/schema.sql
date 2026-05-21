--For Postgresql, RUN ONLY ONCE FOR SETUP
CREATE DATABASE db;

CREATE TABLE users(
    user_id SERIAL PRIMARY KEY,
    acc_holder_name VARCHAR(50) NOT NULL,
    acc_holder_phone_no VARCHAR(15) UNIQUE NOT NULL,
    acc_holder_dob DATE NOT NULL,
    pass_hash VARCHAR(2048) NOT NULL,
    has_PAN BOOLEAN NOT NULL,
    PAN_hash VARCHAR(2048) UNIQUE,
    form_60_acknowledgement_no VARCHAR(50) UNIQUE,
    aadhar_vault_token VARCHAR(64) UNIQUE,
    email VARCHAR(256) UNIQUE,
    CHECK(
        (has_PAN = FALSE AND form_60_acknowledgement_no IS NOT NULL) OR
        (has_PAN = TRUE AND PAN_hash IS NOT NULL)
    )
);

CREATE TABLE accounts(

);

CREATE TABLE logins(

);

CREATE TABLE user_devices(

);

CREATE TABLE user_locations(

);

CREATE TABLE transactions(

);

CREATE TABLE beneficiaries(

);

CREATE TABLE transaction_patterns(

);

CREATE TABLE fraud_alerts(

);

CREATE TABLE fraud_scores(

);