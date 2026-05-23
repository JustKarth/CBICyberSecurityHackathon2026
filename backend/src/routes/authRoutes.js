import express from "express";
import { register, login, profile } from "../controllers/authControllers.js";
import authMiddleware from "../middlewares/authMiddlewares.js";

const router = express.Router();

router.post("/register", register);
router.post("/login", login);
router.get("/profile", authMiddleware, profile);

export default router;
