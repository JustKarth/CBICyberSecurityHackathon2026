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
    --is_pseudo_user BOOLEAN NOT NULL
    CONSTRAINT PAN_or_form_60 CHECK(
        (has_PAN = FALSE AND form_60_acknowledgement_no IS NOT NULL) OR
        (has_PAN = TRUE AND PAN_hash IS NOT NULL)
    )
);

CREATE TABLE accounts(
    acc_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
    acc_no VARCHAR(26) NOT NULL UNIQUE,
    acc_hash VARCHAR(64) UNIQUE, --NULL if the user is real
    IFSC_code VARCHAR(11) NOT NULL,
    current_balance DECIMAL(21,2) NOT NULL,
    acc_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    daily_transfer_limit DECIMAL(21,2) NOT NULL DEFAULT 50000.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT acc_status_check CHECK(
        acc_status IN ('ACTIVE', 'CLOSED', 'BLOCKED')
    )
);

CREATE TABLE transactions(
    transaction_id INT PRIMARY KEY,
    acc_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE NOT NULL,
    transaction_amount DECIMAL(21,2) NOT NULL,
    transaction_status VARCHAR(50) NOT NULL DEFAULT 'FAILED',
    recipient_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE,
    merchant_name VARCHAR(100),
    product_code VARCHAR(10),
    transaction_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT transaction_status_check CHECK(
        transaction_status IN ('SUCCESS', 'FAILED', 'BLOCKED')
    ),

    CONSTRAINT destination_check CHECK(
        (recipient_id IS NOT NULL) OR
        (merchant_name IS NOT NULL AND product_code IS NOT NULL)
    )
);

CREATE TABLE logins(
    login_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
    login_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP,
    session_status VARCHAR(50) NOT NULL DEFAULT 'LOGGED_IN',  
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT NOT NULL, --for identifying browser/os
    CONSTRAINT session_status_check CHECK(
        session_status IN ('LOGGED_IN', 'LOGGED_OUT', 'BLOCKED', 'EXPIRED', 'INACTIVE')
    )
);

CREATE TABLE beneficiaries(
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
    target_acc_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE NOT NULL,
    nickaname VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(user_id, target_acc_id) --remember to write the function to check for self beneficiaries before inserting
);

