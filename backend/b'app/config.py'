from datetime import timedelta
from flask_socketio import SocketIO
from sqlalchemy import MetaData
from sqlalchemy.engine import URL
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
from flask import Flask, request
from flask_basicauth import BasicAuth
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
from flask_apscheduler import APScheduler
import os


MIN_FRONTEND_VERSION = 71
BACKEND_VERSION = 82

APP_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(APP_DIR)

STORAGE_PATH = os.getenv("STORAGE_PATH", PROJECT_DIR)
UPLOAD_FOLDER = STORAGE_PATH + "/upload"
ALLOWED_FILE_EXTENSIONS = {"txt", "pdf", "png", "jpg", "jpeg", "gif"}

PRIVACY_POLICY_URL = os.getenv("PRIVACY_POLICY_URL")
OPEN_REGISTRATION = os.getenv("OPEN_REGISTRATION", "False").lower() == "true"
EMAIL_MANDATORY = os.getenv("EMAIL_MANDATORY", "False").lower() == "true"

COLLECT_METRICS = os.getenv("COLLECT_METRICS", "False").lower() == "true"

DB_URL = URL.create(
    os.getenv("DB_DRIVER", "sqlite"),
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    database=os.getenv("DB_NAME", STORAGE_PATH + "/database.db"),
)

JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=15)
JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

SUPPORTED_LANGUAGES = {
    "en": "English",
    "cs": "čeština",
    "da": "Dansk",
    "de": "Deutsch",
    "el": "Ελληνικά",
    "es": "Español",
    "fi": "Suomi",
    "fr": "Français",
    "hu": "Magyar nyelv",
    "id": "Bahasa Indonesia",
    "it": "Italiano",
    "nb_NO": "Bokmål",
    "nl": "Nederlands",
    "pl": "Polski",
    "pt": "Português",
    "pt_BR": "Português Brasileiro",
    "ru": "русский язык",
    "sv": "Svenska",
    "tr": "Türkçe",
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
    app, json=app.json, logger=app.logger, cors_allowed_origins=os.getenv("FRONT_URL")
)
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

scheduler = APScheduler()
# enable for debugging jobs: ../scheduler/jobs to see scheduled jobs
scheduler.api_enabled = False
scheduler.init_app(app)
scheduler.start()


@app.after_request
def add_cors_headers(response):
    if not request.referrer:
        return response
    r = request.referrer[:-1]
    url = os.getenv("FRONT_URL")
    if app.debug or url and r == url:
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
    app.logger.error(e)
    return "Something went wrong", 500


@app.errorhandler(404)
def not_found(error):
    return "Requested resource not found", 404


@socketio.on_error_default
def default_socket_error_handler(e):
    app.logger.error(e)
