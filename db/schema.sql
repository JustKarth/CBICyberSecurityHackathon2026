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
    current_balance DECIMAL(23,2) NOT NULL,
    acc_status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    daily_transfer_limit DECIMAL(23,2) NOT NULL DEFAULT 50000.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT acc_status_check CHECK(
        acc_status IN ('ACTIVE', 'CLOSED', 'BLOCKED')
    )
);

CREATE TABLE transactions(
    transaction_id SERIAL PRIMARY KEY,
    acc_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE NOT NULL,
    transaction_amount DECIMAL(23,2) NOT NULL,
    transaction_status VARCHAR(50) NOT NULL DEFAULT 'FAILED',
    recipient_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE,
    merchant_name VARCHAR(100),
    product_code VARCHAR(10),
    transaction_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT transaction_status_check CHECK(
        transaction_status IN ('SUCCESS', 'FAILED', 'BLOCKED')
    ),

    CONSTRAINT destination_check CHECK(
        (recipient_id IS NOT NULL) OR
        (merchant_name IS NOT NULL AND product_code IS NOT NULL)
    )
);

CREATE TABLE known_devices(
    device_id SERIAL PRIMARY KEY,
    device_fingerprint VARCHAR(256) NOT NULL UNIQUE,
    user_agent TEXT NOT NULL, --for identifying browser/os
    first_seen TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE logins(
    login_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    attempted_username VARCHAR(256) NOT NULL,
    device_id INT REFERENCES known_devices(device_id) NOT NULL,
    login_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMPTZ,
    session_status VARCHAR(50) NOT NULL DEFAULT 'LOGGED_IN',  
    ip_address VARCHAR(45) NOT NULL,
    login_location VARCHAR(100) NOT NULL,
    CONSTRAINT session_status_check CHECK(
        session_status IN ('LOGGED_IN', 'LOGGED_OUT', 'BLOCKED', 'EXPIRED', 'INACTIVE', 'FAILED')
    )
);

CREATE TABLE beneficiaries(
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
    target_acc_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE NOT NULL,
    nickname VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(user_id, target_acc_id) --remember to write the function to check for self beneficiaries before inserting
);

CREATE TABLE data_telemetry(
    entry_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    login_id INT REFERENCES logins(login_id) ON DELETE CASCADE NOT NULL,
    entry_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    entry_trigger VARCHAR(100) NOT NULL,--what high risk action triggered this entry
    transaction_id INT REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    avg_mouse_speed DECIMAL(8, 2),
    avg_typing_speed DECIMAL(8, 2),
    avg_click_speed DECIMAL(8, 2),
    amount_to_balance_percentage DOUBLE PRECISION,
    amount_to_limit_percentage DOUBLE PRECISION,
    no_of_prior_transfers_to_recipient INT,
    travel_speed DECIMAL(10, 2), --Calculated by taking current entry and last entry and finding distance between locations and then divide by timestamp difference
    failed_logins INT DEFAULT 0,
    copy_paste_used INT DEFAULT 0, --no of times copy paste is used
    deviation_from_avg_amount DECIMAL(23, 2),
    frequency_of_transactions INT DEFAULT 0, --per session
    VPN_probability DECIMAL(7, 6)
);