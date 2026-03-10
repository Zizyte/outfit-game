const crypto = require("crypto");
const Stripe = require("stripe");

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

function base64url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function sign(value, secret) {
  return crypto.createHmac("sha256", secret).update(value).digest("base64url");
}

exports.handler = async (event) => {
  try {
    const sessionId = event.queryStringParameters?.session_id;

    if (!sessionId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing session_id" }),
      };
    }

    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (!session || session.payment_status !== "paid") {
      return {
        statusCode: 403,
        body: JSON.stringify({ error: "Session is not paid" }),
      };
    }

    const now = Date.now();
    const expiresAtMs = now + 3 * 24 * 60 * 60 * 1000;

    const payload = {
      sid: session.id,
      paid: true,
      iat: now,
      exp: expiresAtMs,
    };

    const payloadEncoded = base64url(JSON.stringify(payload));
    const signature = sign(payloadEncoded, process.env.ACCESS_SIGNING_SECRET);
    const token = `${payloadEncoded}.${signature}`;

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
      },
      body: JSON.stringify({
        token,
        expiresAt: new Date(expiresAtMs).toISOString(),
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Could not redeem session",
        details: error.message,
      }),
    };
  }
};