const crypto = require("crypto");

function sign(value, secret) {
  return crypto.createHmac("sha256", secret).update(value).digest("base64url");
}

exports.handler = async (event) => {
  try {
    const token = event.queryStringParameters?.token;

    if (!token) {
      return {
        statusCode: 400,
        body: JSON.stringify({ active: false, error: "Missing token" }),
      };
    }

    const parts = token.split(".");
    if (parts.length !== 2) {
      return {
        statusCode: 401,
        body: JSON.stringify({ active: false, error: "Malformed token" }),
      };
    }

    const [payloadEncoded, signature] = parts;
    const expected = sign(payloadEncoded, process.env.ACCESS_SIGNING_SECRET);

    if (signature !== expected) {
      return {
        statusCode: 401,
        body: JSON.stringify({ active: false, error: "Invalid signature" }),
      };
    }

    const payloadJson = Buffer.from(payloadEncoded, "base64url").toString("utf8");
    const payload = JSON.parse(payloadJson);

    if (!payload.exp || Date.now() > payload.exp) {
      return {
        statusCode: 401,
        body: JSON.stringify({ active: false, error: "Token expired" }),
      };
    }

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
      body: JSON.stringify({
        active: true,
        expiresAt: new Date(payload.exp).toISOString(),
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        active: false,
        error: "Validation failed",
        details: error.message,
      }),
    };
  }
};