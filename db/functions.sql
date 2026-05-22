CREATE OR REPLACE FUNCTION transfer_money(
    sender_acc_id INT,
    receiver_acc_id INT,
    amount DECIMAL(23, 2)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    sender_balance DECIMAL(23,2);
BEGIN
    IF sender_acc_id = receiver_acc_id THEN
        RAISE EXCEPTION 'Cannot transfer to the same account';
    END IF;

    SELECT current_balance
    INTO sender_balance
    FROM accounts
    WHERE acc_id = sender_acc_id;

    IF sender_balance IS NULL THEN
        RAISE EXCEPTION 'Sender not found';
    END IF;

    IF sender_balance<amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM accounts
        WHERE acc_id = receiver_acc_id
    ) THEN
        RAISE EXCEPTION 'Receiver account not found';
    END IF;

    UPDATE accounts
    SET current_balance = current_balance-amount
    WHERE acc_id = sender_acc_id;

    UPDATE accounts
    SET current_balance = current_balance + amount
    WHERE acc_id = receiver_acc_id;

    INSERT INTO transactions(
        acc_id,
        transaction_amount,
        transaction_status,
        recipient_id,
        transaction_type
    )
    VALUES(
        sender_acc_id,
        amount,
        'SUCCESS',
        receiver_acc_id,
        'P2P_TRANSFER'
    );
END;
$$;

CREATE OR REPLACE FUNCTION merchant_payment(
    sender_acc_id INT,
    target_merchant_id INT,
    amount DECIMAL(23,2),
    product VARCHAR(10)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$

DECLARE
    sender_balance DECIMAL(23,2);
    sender_status VARCHAR(50);

    merchant_acc_id INT;
    merchant_status VARCHAR(30);

BEGIN

    IF amount <= 0 THEN
        RAISE EXCEPTION 'Payment amount must be positive';
    END IF;

    SELECT current_balance, acc_status
    INTO sender_balance, sender_status
    FROM accounts
    WHERE acc_id = sender_acc_id;

    IF sender_balance IS NULL THEN
        RAISE EXCEPTION 'Sender account not found';
    END IF;

    IF sender_status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Sender account is not active';
    END IF;

    IF sender_balance < amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    SELECT merchant_account_id, merchant_status
    INTO merchant_acc_id, merchant_status
    FROM merchants
    WHERE merchant_id = target_merchant_id;

    IF merchant_acc_id IS NULL THEN
        RAISE EXCEPTION 'Merchant not found';
    END IF;

    IF merchant_status <> 'ACTIVE' THEN
        RAISE EXCEPTION 'Merchant is not active';
    END IF;

    UPDATE accounts
    SET current_balance = current_balance - amount
    WHERE acc_id = sender_acc_id;

    UPDATE accounts
    SET current_balance = current_balance + amount
    WHERE acc_id = merchant_acc_id;

    INSERT INTO transactions(
        acc_id,
        transaction_amount,
        transaction_status,
        merchant_id,
        product_code,
        transaction_type
    )
    VALUES(
        sender_acc_id,
        amount,
        'SUCCESS',
        target_merchant_id,
        product,
        'MERCHANT_PAYMENT'
    );

END;

$$;

CREATE OR REPLACE FUNCTION add_beneficiary(
    owner_user_id INT,
    beneficiary_acc_id INT,
    beneficiary_nickname VARCHAR(50)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$

DECLARE
    owner_acc_id INT;

BEGIN

    SELECT acc_id
    INTO owner_acc_id
    FROM accounts
    WHERE user_id = owner_user_id;

    IF owner_acc_id = beneficiary_acc_id THEN
        RAISE EXCEPTION 'Cannot add self as beneficiary';
    END IF;

    INSERT INTO beneficiaries(
        user_id,
        target_acc_id,
        nickname
    )
    VALUES(
        owner_user_id,
        beneficiary_acc_id,
        beneficiary_nickname
    );

END;

$$;

CREATE OR REPLACE FUNCTION block_account(
    target_acc_id INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$

BEGIN

    UPDATE accounts
    SET acc_status = 'BLOCKED'
    WHERE acc_id = target_acc_id;

END;

$$;

CREATE OR REPLACE FUNCTION create_fraud_alert(
    target_transaction_id INT,
    target_user_id INT,
    target_fraud_score_id INT,
    message TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$

BEGIN

    INSERT INTO fraud_alerts(
        transaction_id,
        user_id,
        fraud_score_id,
        alert_message
    )
    VALUES(
        target_transaction_id,
        target_user_id,
        target_fraud_score_id,
        message
    );

END;

$$;

CREATE OR REPLACE FUNCTION mark_alert_resolved(
    target_alert_id INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$

BEGIN

    UPDATE fraud_alerts
    SET
        alert_status = 'RESOLVED',
        resolved_at = CURRENT_TIMESTAMP
    WHERE alert_id = target_alert_id;

END;

$$;

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$

BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;

$$;