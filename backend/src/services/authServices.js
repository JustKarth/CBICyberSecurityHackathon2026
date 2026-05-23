import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import pool from "../config/db.js";
// User registration
export const registerUser = async(userData)=>{
    const{
        acc_holder_name,
        acc_holder_phone_number,
        acc_holder_dob,
        email,
        password
    } = userData;

const saltRounds = 10;
const hashedPassword = await bcrypt.hash(password,saltRounds);

const query =`
INSERT INTO users (
acc_holder_name,
acc_holder_phone_number, 
acc_holder_dob, 
email, 
pass_hash
)
VALUES ($1, $2, $3, $4, $5) 
RETURNING user_id,email
`;

const values = [
    acc_holder_name,
    acc_holder_phone_number,
    acc_holder_dob,
    email,
    hashedPassword
];
const result = await pool.query(query,values);
return result.rows[0];
};
// User login
export const loginUser = async(email,password)=>{
    const query = `
SELECT * FROM users
WHERE email = $1
`;

const result = await pool.query(query, [email]);
if (result.rows.length === 0) {
    throw new Error("Invalid email or password");
}
const user = result.rows[0];
const isPasswordCorrect = await bcrypt.compare(
    password,
    user.pass_hash
);
if (!isPasswordCorrect) {
    throw new Error("Invalid email or password");
}

// Generate JWT token
const token = jwt.sign(
    {
        user_id: user.user_id,
        email:user.email
    },
    process.env.JWT_SECRET,
    {
        expiresIn:"1d"
    }
);
return {
    token,
    user
};
};
