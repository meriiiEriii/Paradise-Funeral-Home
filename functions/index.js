/**
 * Sends an email for every notification created in Firestore.
 *
 * Recipients:
 *  - notifications with `recipientUid`  -> the email stored in users/{uid}
 *  - notifications with `audienceRole`  -> every admin (or approved staff)
 *
 * SMTP credentials are provided through Secret Manager. Set them once with:
 *   firebase functions:secrets:set SMTP_HOST
 *   firebase functions:secrets:set SMTP_PORT
 *   firebase functions:secrets:set SMTP_USER
 *   firebase functions:secrets:set SMTP_PASS
 *   firebase functions:secrets:set MAIL_FROM
 */
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const SMTP_HOST = defineSecret("SMTP_HOST");
const SMTP_PORT = defineSecret("SMTP_PORT");
const SMTP_USER = defineSecret("SMTP_USER");
const SMTP_PASS = defineSecret("SMTP_PASS");
const MAIL_FROM = defineSecret("MAIL_FROM");

exports.sendNotificationEmail = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    secrets: [SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    if (data.emailSent) return;

    let recipients = [];
    try {
      recipients = await resolveRecipients(data);
    } catch (err) {
      console.error("Failed to resolve recipients:", err);
      return;
    }
    if (recipients.length === 0) {
      await snap.ref.update({ emailSent: false, emailedTo: [] });
      return;
    }

    const transport = nodemailer.createTransport({
      host: SMTP_HOST.value(),
      port: Number(SMTP_PORT.value() || 587),
      secure: Number(SMTP_PORT.value() || 587) === 465,
      auth: {
        user: SMTP_USER.value(),
        pass: SMTP_PASS.value(),
      },
    });

    const subject = `[Paradise Funeral Home] ${data.title || "Notification"}`;
    const html = buildHtml(data.title || "", data.message || "");

    try {
      await transport.sendMail({
        from: MAIL_FROM.value(),
        to: recipients.join(", "),
        subject,
        html,
      });
      await snap.ref.update({ emailSent: true, emailedTo: recipients });
    } catch (err) {
      console.error("Failed to send notification email:", err);
      await snap.ref.update({
        emailSent: false,
        emailError: String((err && err.message) || err),
      });
    }
  }
);

async function resolveRecipients(data) {
  const db = admin.firestore();

  if (data.recipientUid) {
    const doc = await db.collection("users").doc(data.recipientUid).get();
    const email = doc.exists ? doc.data().email : null;
    return email ? [email] : [];
  }

  if (data.audienceRole === "admin") {
    const snapshot = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();
    return snapshot.docs
      .map((doc) => doc.data().email)
      .filter((email) => typeof email === "string" && email.length > 0);
  }

  return [];
}

function buildHtml(title, message) {
  const safeTitle = escapeHtml(title);
  const safeMessage = escapeHtml(message);
  return `
<div style="font-family:Arial,Helvetica,sans-serif;max-width:560px;margin:auto;border:1px solid #eee;border-radius:12px;overflow:hidden;">
  <div style="background:linear-gradient(135deg,#5b3a8e,#7c5cbf);padding:18px 22px;">
    <h2 style="color:#ffffff;margin:0;font-size:18px;">Paradise Funeral Home</h2>
    <p style="color:#e6e0f5;margin:4px 0 0;font-size:12px;">Management System Notification</p>
  </div>
  <div style="padding:22px;">
    <h3 style="margin:0 0 10px;font-size:16px;color:#333;">${safeTitle}</h3>
    <p style="margin:0;font-size:14px;color:#555;line-height:1.6;">${safeMessage}</p>
  </div>
  <div style="padding:14px 22px;border-top:1px solid #eee;">
    <p style="margin:0;color:#999;font-size:11px;">
      You are receiving this email because you have an account in the
      Paradise Funeral Home Management System.
    </p>
  </div>
</div>`;
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
