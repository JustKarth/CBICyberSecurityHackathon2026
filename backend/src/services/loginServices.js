import pool from "../config/db.js";
import { getOrCreateDevice } from "./deviceServices.js";
import { extractLoginContext, validateDeviceContext } from "../utils/loginContext.js";

export async function saveLoginAttempt({
  user_id,
  attempted_username,
  device_id,
  ip_address,
  login_location,
  session_status,
}) {
  const result = await pool.query(
    `INSERT INTO logins (
      user_id,
      attempted_username,
      device_id,
      ip_address,
      login_location,
      session_status
    ) VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING login_id, user_id, attempted_username, device_id, ip_address,
              login_location, session_status, login_time`,
    [user_id, attempted_username, device_id, ip_address, login_location, session_status]
  );

  return result.rows[0];
}

export async function getUserIdByEmail(email) {
  const result = await pool.query(`SELECT user_id FROM users WHERE email = $1`, [email]);
  return result.rows[0]?.user_id ?? null;
}

export async function isNewDeviceForUser(user_id, device_id) {
  const result = await pool.query(
    `SELECT COUNT(*)::int AS count
     FROM logins
     WHERE user_id = $1
       AND device_id = $2
       AND session_status = 'LOGGED_IN'`,
    [user_id, device_id]
  );
  return result.rows[0].count === 0;
}

export async function countRecentFailedLogins(ip_address, minutes = 60) {
  const result = await pool.query(
    `SELECT COUNT(*)::int AS count
     FROM logins
     WHERE ip_address = $1
       AND session_status = 'FAILED'
       AND login_time >= NOW() - ($2 || ' minutes')::interval`,
    [ip_address, minutes]
  );
  return result.rows[0].count;
}

export async function createSuspiciousSession(login_id, suspicion_reason, severity) {
  const result = await pool.query(
    `INSERT INTO suspicious_sessions (login_id, suspicion_reason, severity)
     VALUES ($1, $2, $3)
     RETURNING suspicious_session_id, login_id, suspicion_reason, severity, detected_at, resolved`,
    [login_id, suspicion_reason, severity]
  );
  return result.rows[0];
}

async function runLoginRiskChecks({ loginRecord, user_id, device_id, context, isNewDevice }) {
  const alerts = [];

  if (isNewDevice && user_id) {
    const suspicious = await createSuspiciousSession(
      loginRecord.login_id,
      "Login from a new device for this user",
      6
    );
    alerts.push({ type: "NEW_DEVICE", suspicious });
  }

  const failedCount = await countRecentFailedLogins(context.ip_address);
  if (failedCount >= 3) {
    const suspicious = await createSuspiciousSession(
      loginRecord.login_id,
      `Multiple failed login attempts from IP ${context.ip_address}`,
      8
    );
    alerts.push({ type: "FAILED_LOGINS", suspicious });
  }

  if (context.vpn_probability !== null && context.vpn_probability >= 0.8) {
    const suspicious = await createSuspiciousSession(
      loginRecord.login_id,
      "High VPN probability detected at login",
      7
    );
    alerts.push({ type: "VPN_LOGIN", suspicious });
  }

  if (context.login_location === "Unknown") {
    const suspicious = await createSuspiciousSession(
      loginRecord.login_id,
      "Login from unknown location",
      5
    );
    alerts.push({ type: "UNKNOWN_LOCATION", suspicious });
  }

  return alerts;
}

export async function recordLoginFromRequest(req, {
  user_id,
  attempted_username,
  session_status,
}) {
  const context = extractLoginContext(req);
  validateDeviceContext(context);

  const device = await getOrCreateDevice(context.device_fingerprint, context.user_agent);

  const isNewDevice =
    session_status === "LOGGED_IN" && user_id
      ? await isNewDeviceForUser(user_id, device.device_id)
      : false;

  const loginRecord = await saveLoginAttempt({
    user_id,
    attempted_username,
    device_id: device.device_id,
    ip_address: context.ip_address,
    login_location: context.login_location,
    session_status,
  });

  let riskAlerts = [];
  if (session_status === "LOGGED_IN" && user_id) {
    riskAlerts = await runLoginRiskChecks({
      loginRecord,
      user_id,
      device_id: device.device_id,
      context,
      isNewDevice,
    });
  }

  return { login: loginRecord, device, riskAlerts, context };
}

export async function recordFailedLoginFromRequest(req, email) {
  try {
    const user_id = email ? await getUserIdByEmail(email) : null;
    return await recordLoginFromRequest(req, {
      user_id,
      attempted_username: email || "unknown",
      session_status: "FAILED",
    });
  } catch (err) {
    console.error("Failed to record failed login attempt:", err.message);
    return null;
  }
}

export async function getSessionsForUser(user_id) {
  const result = await pool.query(
    `SELECT
      l.login_id,
      l.attempted_username,
      l.session_status,
      l.ip_address,
      l.login_location,
      l.login_time,
      l.logout_time,
      d.device_id,
      d.device_fingerprint,
      d.user_agent
    FROM logins l
    JOIN known_devices d ON d.device_id = l.device_id
    WHERE l.user_id = $1
    ORDER BY l.login_time DESC`,
    [user_id]
  );
  return result.rows;
}
