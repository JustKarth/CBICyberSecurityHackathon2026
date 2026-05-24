import { registerUser, loginUser, getUserProfile } from "../services/authServices.js";

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
  try {
    const { email, password } = req.body;
    const data = await loginUser(email, password);
    res.status(200).json({
      success: true,
      message: "Login successful",
      ...data,
    });
  } catch (error) {
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
