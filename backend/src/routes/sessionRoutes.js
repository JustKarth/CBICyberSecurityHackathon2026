import express from "express";
import { listSessions } from "../controllers/sessionControllers.js";
import authMiddleware from "../middlewares/authMiddlewares.js";

const router = express.Router();

router.get("/", authMiddleware, listSessions);

export default router;
