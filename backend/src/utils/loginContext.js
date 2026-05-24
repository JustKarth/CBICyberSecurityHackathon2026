export function extractLoginContext(req) {
  const forwarded = req.headers["x-forwarded-for"];
  const ip_address =
    (typeof forwarded === "string" ? forwarded.split(",")[0].trim() : null) ||
    req.ip ||
    req.socket?.remoteAddress ||
    "unknown";

  return {
    device_fingerprint: req.body.device_fingerprint,
    user_agent: req.body.user_agent || req.headers["user-agent"] || "unknown",
    login_location: req.body.login_location || "Unknown",
    ip_address,
    vpn_probability:
      req.body.vpn_probability !== undefined ? Number(req.body.vpn_probability) : null,
  };
}

export function validateDeviceContext(context) {
  if (!context.device_fingerprint) {
    throw Object.assign(new Error("device_fingerprint is required"), { statusCode: 400 });
  }
}
