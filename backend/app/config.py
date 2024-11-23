from datetime import timedelta
from http import client
from celery import Celery, Task
from flask_socketio import SocketIO
from sqlalchemy import MetaData
from sqlalchemy.engine import URL
from sqlalchemy.event import listen
from apispec import APISpec
from apispec.ext.marshmallow import MarshmallowPlugin
from prometheus_client import multiprocess
from prometheus_client.core import CollectorRegistry
from prometheus_flask_exporter import PrometheusMetrics
from werkzeug.exceptions import MethodNotAllowed
from app.errors import (
    NotFoundRequest,
    UnauthorizedRequest,
    ForbiddenRequest,
    InvalidUsage,
)
from app.util import KitchenOwlJSONProvider
from oic.oic import Client
from oic.oic.message import RegistrationResponse
from oic.utils.authn.client import CLIENT_AUTHN_METHOD
from flask import Flask, jsonify, request
from flask_basicauth import BasicAuth
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
from flask_apscheduler import APScheduler
import sqlite_icu
import os


MIN_FRONTEND_VERSION = 71
BACKEND_VERSION = 99

APP_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(APP_DIR)

STORAGE_PATH = os.getenv("STORAGE_PATH", PROJECT_DIR)
UPLOAD_FOLDER = STORAGE_PATH + "/upload"
ALLOWED_FILE_EXTENSIONS = {"txt", "pdf", "png", "jpg", "jpeg", "gif", "webp", "jxl"}

FRONT_URL = os.getenv("FRONT_URL")

PRIVACY_POLICY_URL = os.getenv("PRIVACY_POLICY_URL")
OPEN_REGISTRATION = os.getenv("OPEN_REGISTRATION", "False").lower() == "true"
DISABLE_USERNAME_PASSWORD_LOGIN = os.getenv("DISABLE_USERNAME_PASSWORD_LOGIN", "False").lower() == "true"
EMAIL_MANDATORY = os.getenv("EMAIL_MANDATORY", "False").lower() == "true"
DISABLE_ONBOARDING = os.getenv("DISABLE_ONBOARDING", "False").lower() == "true"

COLLECT_METRICS = os.getenv("COLLECT_METRICS", "False").lower() == "true"

DB_URL = URL.create(
    os.getenv("DB_DRIVER", "sqlite"),
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    database=os.getenv("DB_NAME", STORAGE_PATH + "/database.db"),
)
MESSAGE_BROKER = os.getenv("MESSAGE_BROKER")

JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=15)
JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=int(os.getenv("JWT_REFRESH_TOKEN_EXPIRES", "30")))

OIDC_CLIENT_ID = os.getenv("OIDC_CLIENT_ID")
OIDC_CLIENT_SECRET = os.getenv("OIDC_CLIENT_SECRET")
OIDC_ISSUER = os.getenv("OIDC_ISSUER")

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")

APPLE_CLIENT_ID = os.getenv("APPLE_CLIENT_ID")
APPLE_CLIENT_SECRET = os.getenv("APPLE_CLIENT_SECRET")

SUPPORTED_LANGUAGES = {
    "en": "English",
    "en_AU": "Australian English",
    "ar": "اَلْعَرَبِيَّةُ",
    "bg": "български език",
    "bn": "বাংলা",
    "ca": "Catalan",
    "cs": "čeština",
    "da": "Dansk",
    "de": "Deutsch",
    "de_CH": "Deutsch (Schweiz)",
    "el": "Ελληνικά",
    "es": "Español",
    "fi": "Suomi",
    "fr": "Français",
    "he": "עִבְרִית‎",
    "hu": "Magyar nyelv",
    "id": "Bahasa Indonesia",
    "it": "Italiano",
    "ko": "한국어",
    "lt": "Lietuvių kalba",
    "nb_NO": "Bokmål",
    "nl": "Nederlands",
    "pl": "Polski",
    "pt": "Português",
    "pt_BR": "Português Brasileiro",
    "ru": "Русский язык",
    "sv": "Svenska",
    "tr": "Türkçe",
    "uk": "Українська",
    "zh_Hans": "简化字",
}

Flask.json_provider_class = KitchenOwlJSONProvider

app = Flask(__name__)

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
app.config["MAX_CONTENT_LENGTH"] = 32 * 1000 * 1000  # 32MB max upload
app.config["SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "super-secret")
# SQLAlchemy
app.config["SQLALCHEMY_DATABASE_URI"] = DB_URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
# JWT
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "super-secret")
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = JWT_ACCESS_TOKEN_EXPIRES
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = JWT_REFRESH_TOKEN_EXPIRES
if COLLECT_METRICS:
    # BASIC_AUTH
    app.config["BASIC_AUTH_USERNAME"] = os.getenv("METRICS_USER", "kitchenowl")
    app.config["BASIC_AUTH_PASSWORD"] = os.getenv("METRICS_PASSWORD", "ZqQtidgC5n3YXb")

convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}

metadata = MetaData(naming_convention=convention)

db = SQLAlchemy(app, metadata=metadata)
migrate = Migrate(app, db, render_as_batch=True)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)
socketio = SocketIO(
    app,
    json=app.json,
    logger=app.logger,
    cors_allowed_origins=FRONT_URL,
    message_queue=MESSAGE_BROKER,
)
api_spec = APISpec(
    title="KitchenOwl",
    version="v" + str(BACKEND_VERSION),
    openapi_version="3.0.2",
    info={
        "description": "WIP KitchenOwl API documentation",
        "termsOfService": "https://kitchenowl.org/privacy/",
        "contact": {
            "name": "API Support",
            "url": "https://kitchenowl.org/imprint/",
            "email": "support@kitchenowl.org",
        },
        "license": {
            "name": "AGPL 3.0",
            "url": "https://github.com/TomBursch/kitchenowl/blob/main/LICENSE",
        },
    },
    servers=[
        {
            "url": "https://app.kitchenowl.org/api",
            "description": "Official KitchenOwl server instance",
        }
    ],
    externalDocs={
        "description": "Find more info at the official documentation",
        "url": "https://docs.kitchenowl.org",
    },
    plugins=[MarshmallowPlugin()],
)
oidc_clients = {}
if FRONT_URL:
    if OIDC_CLIENT_ID and OIDC_CLIENT_SECRET and OIDC_ISSUER:
        client = Client(client_authn_method=CLIENT_AUTHN_METHOD)
        client.provider_config(OIDC_ISSUER)
        client.store_registration_info(
            RegistrationResponse(
                client_id=OIDC_CLIENT_ID, client_secret=OIDC_CLIENT_SECRET
            )
        )
        oidc_clients["custom"] = client
    if GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET:
        client = Client(client_authn_method=CLIENT_AUTHN_METHOD)
        client.provider_config("https://accounts.google.com/")
        client.store_registration_info(
            RegistrationResponse(
                client_id=GOOGLE_CLIENT_ID,
                client_secret=GOOGLE_CLIENT_SECRET,
            )
        )
        oidc_clients["google"] = client
    if APPLE_CLIENT_ID and APPLE_CLIENT_SECRET:
        client = Client(client_authn_method=CLIENT_AUTHN_METHOD)
        client.provider_config("https://appleid.apple.com/")
        client.store_registration_info(
            RegistrationResponse(
                client_id=APPLE_CLIENT_ID,
                client_secret=APPLE_CLIENT_SECRET,
            )
        )
        oidc_clients["apple"] = client


if COLLECT_METRICS:
    basic_auth = BasicAuth(app)
    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry, path="/tmp")
    metrics = PrometheusMetrics(
        app,
        registry=registry,
        path="/metrics/",
        metrics_decorator=basic_auth.required,
        group_by="endpoint",
    )
    metrics.info("app_info", "Application info", version=BACKEND_VERSION)

scheduler = None
celery_app = None
if not MESSAGE_BROKER:
    scheduler = APScheduler()
    scheduler.api_enabled = False
    scheduler.init_app(app)
    scheduler.start()
else:

    class FlaskTask(Task):
        def __call__(self, *args: object, **kwargs: object) -> object:
            with app.app_context():
                return self.run(*args, **kwargs)

    celery_app = Celery(
        app.name + "_tasks",
        broker=MESSAGE_BROKER,
        task_cls=FlaskTask,
        task_ignore_result=True,
    )
    celery_app.set_default()
    app.extensions["celery"] = celery_app


# Load ICU extension for sqlite
if DB_URL.drivername == "sqlite":

    def load_extension(conn, unused):
        conn.enable_load_extension(True)
        conn.load_extension(sqlite_icu.extension_path().replace(".so", ""))
        conn.enable_load_extension(False)

    with app.app_context():
        listen(db.engine, "connect", load_extension)


@app.after_request
def add_cors_headers(response):
    if not request.referrer:
        return response
    r = request.referrer[:-1]
    if app.debug or FRONT_URL and r == FRONT_URL:
        response.headers.add("Access-Control-Allow-Origin", r)
        response.headers.add("Access-Control-Allow-Credentials", "true")
        response.headers.add("Access-Control-Allow-Headers", "Content-Type")
        response.headers.add("Access-Control-Allow-Headers", "Cache-Control")
        response.headers.add("Access-Control-Allow-Headers", "X-Requested-With")
        response.headers.add("Access-Control-Allow-Headers", "Authorization")
        response.headers.add(
            "Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE"
        )
    return response


@app.errorhandler(Exception)
def unhandled_exception(e: Exception):
    if type(e) is NotFoundRequest:
        app.logger.info(e)
        return "Requested resource not found", 404
    if type(e) is ForbiddenRequest:
        app.logger.warning(e)
        return "Request forbidden", 403
    if type(e) is InvalidUsage:
        app.logger.warning(e)
        return "Request invalid", 400
    if type(e) is UnauthorizedRequest:
        app.logger.warning(e)
        return "Request unauthorized", 401
    if type(e) is MethodNotAllowed:
        app.logger.warning(e)
        return "The method is not allowed for the requested URL", 405
    app.logger.error(e, exc_info=e)
    return "Something went wrong", 500


@app.errorhandler(404)
def not_found(error):
    return "Requested resource not found", 404


@socketio.on_error_default
def default_socket_error_handler(e):
    app.logger.error(e)


@app.route("/api/openapi", methods=["GET"])
def swagger():
    return jsonify(api_spec.to_dict())
