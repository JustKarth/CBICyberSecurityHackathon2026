import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import cookieParser from "cookie-parser";
import testRoutes from "./routes/testRoutes.js";


const app = express();

app.use(cors());
app.use(helmet());
app.use(morgan("dev"));
app.use(cookieParser());
app.use(express.json());

app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Backend is running",
  });
});

app.use("/api",testRoutes);

export default app;
