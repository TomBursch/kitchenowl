import smtplib, ssl, os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import FRONT_URL
from app.models import User

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", 465))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASS = os.getenv("SMTP_PASS")
SMTP_FROM = os.getenv("SMTP_FROM")
SMTP_REPLY_TO = os.getenv("SMTP_REPLY_TO")

context = ssl.create_default_context()

mail_configured: bool = None


def mailConfigured():
    global mail_configured
    if mail_configured != None:
        return mail_configured
    if (
        not SMTP_HOST
        or not SMTP_PORT
        or not SMTP_USER
        or not SMTP_PASS
        or not SMTP_FROM
    ):
        mail_configured = False
        return mail_configured
    try:
        with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context) as server:
            server.login(SMTP_USER, SMTP_PASS)
        mail_configured = True
    except Exception:
        mail_configured = False
    return mail_configured


def sendMail(to: str, message: MIMEMultipart):
    with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context) as server:
        server.login(SMTP_USER, SMTP_PASS)
        message["From"] = SMTP_FROM
        message["To"] = to
        if SMTP_REPLY_TO:
            message["Reply-To"] = SMTP_REPLY_TO
        server.sendmail(SMTP_FROM, to, message.as_string())


def sendVerificationMail(user: User, token: str):
    if not user.email or not token:
        return

    verifyLink = FRONT_URL + "/#/confirm-email?t=" + token

    message = MIMEMultipart("alternative")
    message["Subject"] = "Verify Email"
    text = """\
Hi {name} (@{username}),

Verify your email so we know it's really you and you don't loose access to your account.
Verify email address: {link}

Have any questions? Check out https://kitchenowl.org/privacy/""".format(
        name=user.name, username=user.username, link=verifyLink
    )
    html = """\
<html>
<body>
    <p>Hi {name} (@{username}),<br>
    Verify your email so we know it's really you and you don't loose access to your account.<br>
    <a href="{link}">Verify email address</a><br>
    Have any questions? Check out our <a href="https://kitchenowl.org/privacy/">Privacy Policy</a>
    </p>
</body>
</html>
    """.format(
        name=user.name, username=user.username, link=verifyLink
    )
    # The email client will try to render the last part first
    message.attach(MIMEText(text, "plain"))
    message.attach(MIMEText(html, "html"))
    sendMail(user.email, message)


def sendPasswordResetMail(user: User, token: str):
    if not user.email or not token:
        return

    resetLink = FRONT_URL + "/#/reset-password?t=" + token

    message = MIMEMultipart("alternative")
    message["Subject"] = "Reset password"
    text = """\
Hi {name} (@{username}),

We received a request to change your password. This link is valid for three hours.
Reset password: {link}

If you didn't request a password reset, you can ignore this message and continue to use your current password.

Have any questions? Check out https://kitchenowl.org/privacy/""".format(
        name=user.name, username=user.username, link=resetLink
    )
    html = """\
<html>
<body>
    <p>Hi {name} (@{username}),<br>
    We received a request to change your password. This link is valid for three hours.<br>
    <a href="{link}">Reset password</a><br>
    If you didn't request a password reset, you can ignore this message and continue to use your current password.<br>

    Have any questions? Check out our <a href="https://kitchenowl.org/privacy/">Privacy Policy</a>
    </p>
</body>
</html>
    """.format(
        name=user.name, username=user.username, link=resetLink
    )
    # The email client will try to render the last part first
    message.attach(MIMEText(text, "plain"))
    message.attach(MIMEText(html, "html"))
    sendMail(user.email, message)
