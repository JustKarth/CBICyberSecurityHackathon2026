import "dotenv/config";
import app from "./app.js";
import { connectDatabase } from "./config/db.js";

const PORT = process.env.PORT || 8080;

try {
  await connectDatabase();
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
} catch (err) {
  console.error("Database connection failed:", err.message);
  process.exit(1);
}
