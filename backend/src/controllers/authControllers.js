import { registerUser, loginUser, getUserProfile } from "../services/authServices.js";
import {
  recordLoginFromRequest,
  recordFailedLoginFromRequest,
} from "../services/loginServices.js";
import { validateDeviceContext, extractLoginContext } from "../utils/loginContext.js";

function handleAuthError(res, error, fallbackStatus = 500) {
  const status = error.statusCode || fallbackStatus;
  return res.status(status).json({
    success: false,
    message: error.message,
  });
}

export const register = async (req, res) => {
  try {
    const data = await registerUser(req.body);
    res.status(201).json({
      success: true,
      message: "User registered successfully",
      ...data,
    });
  } catch (error) {
    handleAuthError(res, error);
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    validateDeviceContext(extractLoginContext(req));
    const data = await loginUser(email, password);

    const tracking = await recordLoginFromRequest(req, {
      user_id: data.user.user_id,
      attempted_username: email,
      session_status: "LOGGED_IN",
    });

    res.status(200).json({
      success: true,
      message: "Login successful",
      ...data,
      login: tracking.login,
      device: tracking.device,
      riskAlerts: tracking.riskAlerts,
    });
  } catch (error) {
    if (email) {
      await recordFailedLoginFromRequest(req, email);
    }
    handleAuthError(res, error, 401);
  }
};

export const profile = async (req, res) => {
  try {
    const profileData = await getUserProfile(req.user.user_id);
    res.status(200).json({
      success: true,
      profile: profileData,
    });
  } catch (error) {
    handleAuthError(res, error, 404);
  }
};
