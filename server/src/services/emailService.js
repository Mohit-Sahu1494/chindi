/**
 * Email Service using Brevo (formerly Sendinblue) Transactional API
 */

async function sendEmailViaBrevo({ to, subject, htmlContent }) {
  const apiKey = process.env.BREVO_API_KEY;
  const senderEmail = process.env.BREVO_SENDER_EMAIL || 'support@chindi.app';
  const senderName = process.env.BREVO_SENDER_NAME || 'Chindi';

  if (!apiKey || apiKey.trim().length === 0) {
    console.log(`[Brevo Email Simulated] To: "${to}" | Subject: "${subject}" (BREVO_API_KEY not set in .env)`);
    return { success: true, simulated: true };
  }

  const payload = {
    sender: { name: senderName, email: senderEmail },
    to: [{ email: to }],
    subject,
    htmlContent,
  };

  try {
    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': apiKey.trim(),
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const responseData = await response.json();

    if (!response.ok) {
      console.error('[Brevo Email] Brevo API Error response:', responseData);
      throw new Error(responseData.message || `Brevo API error: ${response.status}`);
    }

    console.log(`[Brevo Email] Email sent to ${to}. MessageId:`, responseData.messageId);
    return { success: true, messageId: responseData.messageId };
  } catch (err) {
    console.error(`[Brevo Email] Error delivering email to ${to}:`, err.message);
    throw err;
  }
}

/**
 * Sends Signup Email Verification OTP
 */
async function sendSignupOtpEmail(email, otp) {
  const subject = `Chindi: Verification Code - ${otp}`;
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; background-color: #0C0B09; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #F3EDE0;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #0C0B09; padding: 40px 15px;">
        <tr>
          <td align="center">
            <table width="100%" max-width="520" style="max-width: 520px; background-color: #1C1915; border: 1px solid rgba(201,164,92,0.3); border-radius: 14px; overflow: hidden; padding: 36px 30px;">
              <tr>
                <td align="center" style="padding-bottom: 20px;">
                  <h1 style="color: #DDBB74; margin: 0; font-size: 28px; letter-spacing: 3px; font-weight: 700;">CHINDI</h1>
                  <p style="color: #A39B8B; margin: 6px 0 0 0; font-size: 13px;">Doston Ke Beech Har Sikke Ka Saaf Hisaab</p>
                </td>
              </tr>
              <tr>
                <td style="padding: 20px 0; border-top: 1px solid rgba(201,164,92,0.18); border-bottom: 1px solid rgba(201,164,92,0.18);">
                  <p style="font-size: 16px; margin: 0 0 12px 0; color: #F3EDE0;">Namaste,</p>
                  <p style="font-size: 14px; line-height: 1.5; color: #A39B8B; margin: 0 0 24px 0;">
                    Chindi app par naya account banane ke liye aapka verification code neeche diya gaya hai:
                  </p>
                  <div style="background-color: #24201B; border: 1.5px dashed #C9A45C; border-radius: 8px; padding: 18px; text-align: center; margin: 20px 0;">
                    <span style="font-size: 34px; letter-spacing: 8px; font-weight: 700; color: #DDBB74; font-family: monospace;">${otp}</span>
                  </div>
                  <p style="font-size: 12px; color: #A39B8B; margin: 16px 0 0 0; text-align: center;">
                    Yeh code agle <strong>10 minute</strong> ke liye valid hai.
                  </p>
                </td>
              </tr>
              <tr>
                <td style="padding-top: 24px; text-align: center;">
                  <p style="font-size: 11px; color: #6B655A; margin: 0;">
                    Suraksha ke liye yeh OTP kisi ke sath share na karein. Agar aapne yeh request nahi ki thi, toh kripya is email ko ignore karein.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;

  return await sendEmailViaBrevo({ to: email, subject, htmlContent });
}

/**
 * Sends Forgot Password Reset OTP
 */
async function sendForgotPasswordOtpEmail(email, otp) {
  const subject = `Chindi: Password Reset Code - ${otp}`;
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; background-color: #0C0B09; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #F3EDE0;">
      <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #0C0B09; padding: 40px 15px;">
        <tr>
          <td align="center">
            <table width="100%" max-width="520" style="max-width: 520px; background-color: #1C1915; border: 1px solid rgba(201,164,92,0.3); border-radius: 14px; overflow: hidden; padding: 36px 30px;">
              <tr>
                <td align="center" style="padding-bottom: 20px;">
                  <h1 style="color: #DDBB74; margin: 0; font-size: 28px; letter-spacing: 3px; font-weight: 700;">CHINDI</h1>
                  <p style="color: #A39B8B; margin: 6px 0 0 0; font-size: 13px;">Doston Ke Beech Har Sikke Ka Saaf Hisaab</p>
                </td>
              </tr>
              <tr>
                <td style="padding: 20px 0; border-top: 1px solid rgba(201,164,92,0.18); border-bottom: 1px solid rgba(201,164,92,0.18);">
                  <p style="font-size: 16px; margin: 0 0 12px 0; color: #F3EDE0;">Namaste,</p>
                  <p style="font-size: 14px; line-height: 1.5; color: #A39B8B; margin: 0 0 24px 0;">
                    Aapke Chindi account ka password reset karne ke liye OTP neeche diya gaya hai:
                  </p>
                  <div style="background-color: #24201B; border: 1.5px dashed #C9A45C; border-radius: 8px; padding: 18px; text-align: center; margin: 20px 0;">
                    <span style="font-size: 34px; letter-spacing: 8px; font-weight: 700; color: #DDBB74; font-family: monospace;">${otp}</span>
                  </div>
                  <p style="font-size: 12px; color: #A39B8B; margin: 16px 0 0 0; text-align: center;">
                    Yeh OTP agle <strong>10 minute</strong> ke liye valid hai.
                  </p>
                </td>
              </tr>
              <tr>
                <td style="padding-top: 24px; text-align: center;">
                  <p style="font-size: 11px; color: #6B655A; margin: 0;">
                    Agar aapne password reset ki request nahi ki thi, toh kisi ke sath OTP share na karein aur turant support se sampark karein.
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;

  return await sendEmailViaBrevo({ to: email, subject, htmlContent });
}

module.exports = {
  sendEmailViaBrevo,
  sendSignupOtpEmail,
  sendForgotPasswordOtpEmail,
};
