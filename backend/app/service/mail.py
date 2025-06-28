import smtplib
import ssl
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formatdate
from app.config import app, get_secret, FRONT_URL
from app.models import User

SMTP_HOST = os.getenv("SMTP_HOST") 
SMTP_PORT = int(os.getenv("SMTP_PORT", 465))
SMTP_USE_TLS = (
    os.getenv("SMTP_USE_TLS", "true" if SMTP_PORT == 587 else "false").lower() == "true"
)
SMTP_USER = get_secret("SMTP_USER")
SMTP_PASS = get_secret("SMTP_PASS")
SMTP_FROM = os.getenv("SMTP_FROM")
SMTP_REPLY_TO = os.getenv("SMTP_REPLY_TO")

context = ssl.create_default_context()

mail_configured: bool | None = None


def mailConfigured():
    global mail_configured
    if mail_configured is not None:
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
        with _getMailServer() as server:
            server.login(SMTP_USER, SMTP_PASS)
        mail_configured = True
    except Exception:
        mail_configured = False
    return mail_configured


def sendMail(to: str, message: MIMEMultipart):
    with _getMailServer() as server:
        server.login(SMTP_USER, SMTP_PASS)
        message["Date"] = formatdate(localtime=True)
        message["From"] = SMTP_FROM
        message["To"] = to
        if SMTP_REPLY_TO:
            message["Reply-To"] = SMTP_REPLY_TO
        server.sendmail(SMTP_FROM, to, message.as_string())


def sendVerificationMail(userId: int, token: str):
    with app.app_context():
        user = User.find_by_id(userId)
        if not user or not user.email or not token:
            return

        verifyLink = FRONT_URL + "/confirm-email?t=" + token

        message = MIMEMultipart("alternative")
        message["Subject"] = "Verify Email"
        text = """\
Hi {name} (@{username}),

Verify your email so we know it's really you, and you don't lose access to your account.
Verify email address: {link}

Have any questions? Check out https://kitchenowl.org/privacy/""".format(
            name=user.name, username=user.username, link=verifyLink
        )
        html = """\
<html>
<body>
    <p>Hi {name} (@{username}),<br><br>

    Verify your email so we know it's really you, and you don't lose access to your account.<br>
    <a href="{link}">Verify email address</a><br><br>

    Have any questions? Check out our <a href="https://kitchenowl.org/privacy/">Privacy Policy</a>
    </p>
</body>
</html>
        """.format(name=user.name, username=user.username, link=verifyLink)
        # The email client will try to render the last part first
        message.attach(MIMEText(text, "plain"))
        message.attach(MIMEText(html, "html"))
        sendMail(user.email, message)


def sendPasswordResetMail(user: User, token: str):
    if not user.email or not token:
        return

    resetLink = FRONT_URL + "/reset-password?t=" + token

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
    <p>Hi {name} (@{username}),<br><br>

    We received a request to change your password. This link is valid for three hours:<br>
    <a href="{link}">Reset password</a><br><br>

    If you didn't request a password reset, you can ignore this message and continue to use your current password.<br><br>

    Have any questions? Check out our <a href="https://kitchenowl.org/privacy/">Privacy Policy</a>
    </p>
</body>
</html>
    """.format(name=user.name, username=user.username, link=resetLink)
    # The email client will try to render the last part first
    message.attach(MIMEText(text, "plain"))
    message.attach(MIMEText(html, "html"))
    sendMail(user.email, message)


def _getMailServer():
    if SMTP_USE_TLS:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.starttls(context=context)
        return server
    else:
        return smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context)
