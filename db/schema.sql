    --For Postgresql, RUN ONLY ONCE FOR SETUP AFTER CONNECTING TO DB
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
        ),
        CONSTRAINT balance_check CHECK(
            current_balance>=0
        ),
        CONSTRAINT positive_transfer_limit CHECK(
            daily_transfer_limit > 0
        )
    );

    CREATE TABLE merchants(
        merchant_id SERIAL PRIMARY KEY,

        merchant_name VARCHAR(100) NOT NULL,

        merchant_account_id INT
        REFERENCES accounts(acc_id)
        ON DELETE SET NULL,

        acquiring_bank VARCHAR(100),

        merchant_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

        CONSTRAINT merchant_status_check CHECK(
            merchant_status IN ('ACTIVE', 'BLOCKED', 'SUSPENDED')
        )
    );

    CREATE TABLE transactions(
        transaction_id SERIAL PRIMARY KEY,
        acc_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE NOT NULL,
        transaction_amount DECIMAL(23,2) NOT NULL,
        transaction_status VARCHAR(50) NOT NULL DEFAULT 'FAILED',
        recipient_id INT REFERENCES accounts(acc_id) ON DELETE CASCADE,
        merchant_id INT REFERENCES merchants(merchant_id),
        product_code VARCHAR(10),
        transaction_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        transaction_type VARCHAR(30) NOT NULL,

        CONSTRAINT transaction_status_check CHECK(
            transaction_status IN ('SUCCESS', 'FAILED', 'BLOCKED')
        ),

        CONSTRAINT destination_check CHECK(
            (
                recipient_id IS NOT NULL
                AND merchant_id IS NULL
                AND product_code IS NULL
                AND transaction_type = 'P2P_TRANSFER'
            )
            OR
            (
                recipient_id IS NULL
                AND merchant_id IS NOT NULL
                AND product_code IS NOT NULL
                AND transaction_type = 'MERCHANT_PAYMENT'
            )
        ),

        CONSTRAINT prevent_self_transfers CHECK(
            recipient_id IS NULL
            OR acc_id<>recipient_id
        ),
        CONSTRAINT positive_transaction_amount CHECK(
            transaction_amount > 0
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
        VPN_probability DECIMAL(7, 6),
        CONSTRAINT VPN_probability_check CHECK(
            (VPN_probability>=0) AND (VPN_probability<=1)
        )
    );

    CREATE TABLE fraud_scores(
        fraud_score_id SERIAL PRIMARY KEY,
        transaction_id INT REFERENCES transactions(transaction_id) ON DELETE CASCADE,
        login_id INT REFERENCES logins(login_id) ON DELETE CASCADE,
        risk_score DECIMAL(5,2) NOT NULL,
        fraud_probability DECIMAL(8,6) NOT NULL,
        ml_model_version VARCHAR(50),
        evaluated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fraud_probability_check CHECK(
            (fraud_probability>=0) AND (fraud_probability<=1)
        ),
        CONSTRAINT fraud_target_check CHECK(
            (transaction_id IS NOT NULL)
            OR (login_id IS NOT NULL)
        )
    );

    CREATE TABLE fraud_alerts(
        alert_id SERIAL PRIMARY KEY,
        transaction_id INT REFERENCES transactions(transaction_id) ON DELETE CASCADE,
        user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
        fraud_score_id INT REFERENCES fraud_scores(fraud_score_id) ON DELETE CASCADE,
        alert_message TEXT NOT NULL,
        alert_status VARCHAR(50) NOT NULL DEFAULT 'OPEN',
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        resolved_at TIMESTAMPTZ,
        CONSTRAINT alert_status_check CHECK(
            alert_status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'FALSE_POSITIVE')
        ),
        CONSTRAINT alert_target_check CHECK(
            (transaction_id IS NOT NULL)
            OR (fraud_score_id IS NOT NULL)
        )
    );

    CREATE TABLE notification_logs(
        notification_id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
        alert_id INT REFERENCES fraud_alerts(alert_id) ON DELETE CASCADE,
        notification_type VARCHAR(50) NOT NULL,
        notification_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
        sent_at TIMESTAMPTZ,
        CONSTRAINT notification_type_check CHECK(
            notification_type IN ('EMAIL', 'SMS', 'PUSH_NOTIFICATION')
        ),
        CONSTRAINT notification_status_check CHECK(
            notification_status IN ('PENDING', 'SENT', 'FAILED')
        )
    );

    CREATE TABLE suspicious_sessions(
        suspicious_session_id SERIAL PRIMARY KEY,

        login_id INT REFERENCES logins(login_id) ON DELETE CASCADE,

        suspicion_reason TEXT NOT NULL,

        severity INT NOT NULL,

        detected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

        resolved BOOLEAN NOT NULL DEFAULT FALSE
    );



    CREATE INDEX idx_transactions_acc_id
    ON transactions(acc_id);

    CREATE INDEX idx_transactions_recipient
    ON transactions(recipient_id);

    CREATE INDEX idx_transactions_time
    ON transactions(transaction_time);

    CREATE INDEX idx_logins_user_id
    ON logins(user_id);

    CREATE INDEX idx_logins_time
    ON logins(login_time);

    CREATE INDEX idx_telemetry_login
    ON data_telemetry(login_id);

    CREATE INDEX idx_telemetry_transaction
    ON data_telemetry(transaction_id);

    CREATE INDEX idx_fraud_scores_transaction
    ON fraud_scores(transaction_id);

    CREATE INDEX idx_alerts_user
    ON fraud_alerts(user_id);

    CREATE INDEX idx_fraud_scores_login
    ON fraud_scores(login_id);

    CREATE INDEX idx_alerts_status
    ON fraud_alerts(alert_status);