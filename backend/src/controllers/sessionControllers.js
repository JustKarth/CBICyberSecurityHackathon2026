import { getSessionsForUser } from "../services/loginServices.js";

export const listSessions = async (req, res) => {
  try {
    const sessions = await getSessionsForUser(req.user.user_id);
    res.status(200).json({
      success: true,
      count: sessions.length,
      sessions,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
