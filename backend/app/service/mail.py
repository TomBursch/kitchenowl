import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formatdate, make_msgid, parseaddr
from functools import cache
from html import escape as html_escape

from app.config import (
    APP_DIR,
    FRONT_URL,
    PRIVACY_POLICY_URL,
    TERMS_URL,
    app,
    get_secret,
)
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
    if not SMTP_HOST or not SMTP_PORT or not SMTP_FROM:
        mail_configured = False
        return mail_configured
    try:
        with _getMailServer() as server:
            if SMTP_USER and SMTP_PASS:
                server.login(SMTP_USER, SMTP_PASS)
        mail_configured = True
    except Exception as e:
        app.logger.warning(f"Mail configuration check failed: {e}")
        mail_configured = False
    return mail_configured


def sendMail(to: str, message: MIMEMultipart):
    with _getMailServer() as server:
        if SMTP_USER and SMTP_PASS:
            server.login(SMTP_USER, SMTP_PASS)
        from_addr = parseaddr(SMTP_FROM or "")[1]
        domain = from_addr.split("@", 1)[1] if "@" in from_addr else None
        message["Message-ID"] = make_msgid(domain=domain)
        message["Date"] = formatdate(localtime=True)
        message["From"] = SMTP_FROM
        message["To"] = to
        if SMTP_REPLY_TO:
            message["Reply-To"] = SMTP_REPLY_TO
        server.sendmail(SMTP_FROM, to, message.as_string())


def _getMailServer():
    if SMTP_USE_TLS:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10)
        server.starttls(context=context)
        return server
    else:
        return smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context, timeout=10)


@cache
def _readMailTemplate(template_name: str) -> tuple[str, str]:
    base_path = f"{APP_DIR}/../templates/mail/{template_name}"
    with open(f"{base_path}.txt", "r", encoding="utf-8") as f:
        text = f.read()
    with open(f"{base_path}.html", "r", encoding="utf-8") as f:
        html = f.read()
    return text, html


def _loadMailTemplate(template_name: str, **kwargs: str) -> tuple[str, str]:
    kwargs.setdefault(
        "privacy_link", PRIVACY_POLICY_URL or "https://kitchenowl.org/privacy/"
    )
    kwargs.setdefault("terms_link", TERMS_URL or "https://kitchenowl.org/terms/")
    text, html = _readMailTemplate(template_name)
    escaped_kwargs = {k: html_escape(str(v)) for k, v in kwargs.items()}
    return text.format(**kwargs), html.format(**escaped_kwargs)


def _sendTemplateMail(
    to: str,
    subject: str,
    template_name: str,
    **kwargs: str,
):
    message = MIMEMultipart("alternative")
    message["Subject"] = subject
    text, html = _loadMailTemplate(template_name, **kwargs)
    message.attach(MIMEText(text, "plain", "utf-8"))
    message.attach(MIMEText(html, "html", "utf-8"))
    sendMail(to, message)


def _resolveUser(user: User | int) -> User | None:
    if isinstance(user, int):
        return User.find_by_id(user)
    return user


def sendVerificationMail(user: User | int, token: str):
    if not token:
        return
    with app.app_context():
        resolved_user = _resolveUser(user)
        if not resolved_user or not resolved_user.email:
            return

        verifyLink = (FRONT_URL or "") + "/confirm-email?t=" + token
        _sendTemplateMail(
            resolved_user.email,
            "Verify Email",
            "verify_email",
            name=resolved_user.name,
            username=resolved_user.username,
            link=verifyLink,
        )


def sendPasswordResetMail(user: User | int, token: str):
    if not token:
        return
    with app.app_context():
        resolved_user = _resolveUser(user)
        if not resolved_user or not resolved_user.email:
            return

        resetLink = (FRONT_URL or "") + "/reset-password?t=" + token
        _sendTemplateMail(
            resolved_user.email,
            "Reset password",
            "reset_password",
            name=resolved_user.name,
            username=resolved_user.username,
            link=resetLink,
        )


def sendTermsUpdateMail(user: User | int):
    with app.app_context():
        resolved_user = _resolveUser(user)
        if not resolved_user or not resolved_user.email:
            return

        _sendTemplateMail(
            resolved_user.email,
            "Updated Terms of Service and Privacy Policy",
            "terms_update",
            name=resolved_user.name,
            username=resolved_user.username,
        )


def sendAccountDeletionMail(user: User | int):
    with app.app_context():
        resolved_user = _resolveUser(user)
        if not resolved_user or not resolved_user.email:
            return

        loginLink = FRONT_URL or "https://app.kitchenowl.org"
        _sendTemplateMail(
            resolved_user.email,
            "Your account will be deleted soon",
            "account_deletion",
            name=resolved_user.name,
            username=resolved_user.username,
            link=loginLink,
        )
