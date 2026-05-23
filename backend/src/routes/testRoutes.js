import { Router } from "express";
import pool from "../config/db.js";

const router = Router();

router.get("/db-test", async (req, res) => {
  try {
    const result = await pool.query("SELECT COUNT(*)::int AS user_count FROM users");
    res.status(200).json({
      success: true,
      message: "Database connected",
      userCount: result.rows[0].user_count,
    });
  } catch (err) {
    console.error("Database connection error:", err.message);
    res.status(500).json({
      success: false,
      message: "Database connection failed",
      error: err.message,
    });
  }
});

export default router;
