import { registerDevice } from "../services/deviceServices.js";

export const register = async (req, res) => {
  try {
    const { device_fingerprint, user_agent } = req.body;
    const device = await registerDevice({ device_fingerprint, user_agent });
    res.status(201).json({
      success: true,
      message: "Device registered",
      device,
    });
  } catch (error) {
    const status = error.statusCode || 500;
    res.status(status).json({ success: false, message: error.message });
  }
};
