import pool from "../config/db.js";

export async function getOrCreateDevice(device_fingerprint, user_agent) {
  const existing = await pool.query(
    `SELECT device_id, device_fingerprint, user_agent, first_seen, last_seen
     FROM known_devices
     WHERE device_fingerprint = $1`,
    [device_fingerprint]
  );

  if (existing.rows.length > 0) {
    const updated = await pool.query(
      `UPDATE known_devices
       SET last_seen = CURRENT_TIMESTAMP,
           user_agent = $2
       WHERE device_id = $1
       RETURNING device_id, device_fingerprint, user_agent, first_seen, last_seen`,
      [existing.rows[0].device_id, user_agent]
    );
    return updated.rows[0];
  }

  const created = await pool.query(
    `INSERT INTO known_devices (device_fingerprint, user_agent)
     VALUES ($1, $2)
     RETURNING device_id, device_fingerprint, user_agent, first_seen, last_seen`,
    [device_fingerprint, user_agent]
  );

  return created.rows[0];
}

export async function registerDevice({ device_fingerprint, user_agent }) {
  if (!device_fingerprint || !user_agent) {
    throw Object.assign(new Error("device_fingerprint and user_agent are required"), {
      statusCode: 400,
    });
  }
  return getOrCreateDevice(device_fingerprint, user_agent);
}
