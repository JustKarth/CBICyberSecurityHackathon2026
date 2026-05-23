import pg from "pg";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set in backend/.env");
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on("error", (err) => {
  console.error("Unexpected PostgreSQL pool error:", err.message);
});

export async function connectDatabase() {
  const client = await pool.connect();
  try {
    await client.query("SELECT 1");
    console.log("Database connected");
  } finally {
    client.release();
  }
}

export default pool;
