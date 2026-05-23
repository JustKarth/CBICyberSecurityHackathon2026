import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import pool from "../config/db.js";

const SALT_ROUNDS = 10;

function sanitizeUser(user) {
  if (!user) return null;
  const { pass_hash, PAN_hash, ...safe } = user;
  return safe;
}

function buildAccountNumber(userId) {
  return String(100000000000 + Number(userId)).padStart(12, "0");
}

export async function registerUser(userData) {
  const {
    acc_holder_name,
    acc_holder_phone_no,
    acc_holder_dob,
    email,
    password,
    has_PAN,
    PAN,
    form_60_acknowledgement_no,
    IFSC_code = "SBIN0000001",
    initial_balance = 0,
  } = userData;

  if (!acc_holder_name || !acc_holder_phone_no || !acc_holder_dob || !email || !password) {
    throw Object.assign(new Error("Missing required fields"), { statusCode: 400 });
  }

  if (typeof has_PAN !== "boolean") {
    throw Object.assign(new Error("has_PAN must be true or false"), { statusCode: 400 });
  }

  if (has_PAN && !PAN) {
    throw Object.assign(new Error("PAN is required when has_PAN is true"), { statusCode: 400 });
  }

  if (!has_PAN && !form_60_acknowledgement_no) {
    throw Object.assign(
      new Error("form_60_acknowledgement_no is required when has_PAN is false"),
      { statusCode: 400 }
    );
  }

  const pass_hash = await bcrypt.hash(password, SALT_ROUNDS);
  const PAN_hash = has_PAN ? await bcrypt.hash(PAN, SALT_ROUNDS) : null;

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const userResult = await client.query(
      `INSERT INTO users (
        acc_holder_name,
        acc_holder_phone_no,
        acc_holder_dob,
        pass_hash,
        has_PAN,
        PAN_hash,
        form_60_acknowledgement_no,
        email
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING user_id, acc_holder_name, acc_holder_phone_no, acc_holder_dob, email, has_PAN`,
      [
        acc_holder_name,
        acc_holder_phone_no,
        acc_holder_dob,
        pass_hash,
        has_PAN,
        PAN_hash,
        has_PAN ? null : form_60_acknowledgement_no,
        email,
      ]
    );

    const user = userResult.rows[0];
    const acc_no = buildAccountNumber(user.user_id);

    const accountResult = await client.query(
      `INSERT INTO accounts (
        user_id,
        acc_no,
        IFSC_code,
        current_balance,
        acc_status
      ) VALUES ($1, $2, $3, $4, 'ACTIVE')
      RETURNING acc_id, acc_no, IFSC_code, current_balance, acc_status`,
      [user.user_id, acc_no, IFSC_code, initial_balance]
    );

    await client.query("COMMIT");

    return {
      user,
      account: accountResult.rows[0],
    };
  } catch (err) {
    await client.query("ROLLBACK");
    if (err.code === "23505") {
      throw Object.assign(new Error("Email or phone number already registered"), {
        statusCode: 409,
      });
    }
    if (err.code === "23514") {
      throw Object.assign(new Error("Invalid PAN / Form 60 data"), { statusCode: 400 });
    }
    throw err;
  } finally {
    client.release();
  }
}

export async function loginUser(email, password) {
  if (!email || !password) {
    throw Object.assign(new Error("Email and password are required"), { statusCode: 400 });
  }

  const result = await pool.query(
    `SELECT user_id, acc_holder_name, email, pass_hash
     FROM users
     WHERE email = $1`,
    [email]
  );

  if (result.rows.length === 0) {
    throw Object.assign(new Error("Invalid email or password"), { statusCode: 401 });
  }

  const user = result.rows[0];
  const isPasswordCorrect = await bcrypt.compare(password, user.pass_hash);

  if (!isPasswordCorrect) {
    throw Object.assign(new Error("Invalid email or password"), { statusCode: 401 });
  }

  const token = jwt.sign(
    { user_id: user.user_id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: "1d" }
  );

  return {
    token,
    user: sanitizeUser(user),
  };
}

export async function getUserProfile(userId) {
  const result = await pool.query(
    `SELECT
      u.user_id,
      u.acc_holder_name,
      u.acc_holder_phone_no,
      u.acc_holder_dob,
      u.email,
      u.has_PAN,
      a.acc_id,
      a.acc_no,
      a.IFSC_code,
      a.current_balance,
      a.acc_status,
      a.daily_transfer_limit
    FROM users u
    JOIN accounts a ON a.user_id = u.user_id
    WHERE u.user_id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw Object.assign(new Error("User not found"), { statusCode: 404 });
  }

  return result.rows[0];
}
