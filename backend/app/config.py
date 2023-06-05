from datetime import timedelta
from sqlalchemy import MetaData
from sqlalchemy.engine import URL
from werkzeug.exceptions import MethodNotAllowed
from app.errors import NotFoundRequest, UnauthorizedRequest, ForbiddenRequest, InvalidUsage
from app.util import KitchenOwlJSONProvider
from flask import Flask, request
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
from flask_apscheduler import APScheduler
import os


MIN_FRONTEND_VERSION = 71
BACKEND_VERSION = 66

APP_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(APP_DIR)

UPLOAD_FOLDER = os.getenv('STORAGE_PATH', PROJECT_DIR) + '/upload'
ALLOWED_FILE_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}

PRIVACY_POLICY_URL = os.getenv('PRIVACY_POLICY_URL')
OPEN_REGISTRATION = os.getenv('OPEN_REGISTRATION', "False").lower() == "true"
EMAIL_MANDATORY = os.getenv('EMAIL_MANDATORY', "False").lower() == "true"

DB_URL = URL.create(
    os.getenv('DB_DRIVER', "sqlite"),
    username=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    host=os.getenv('DB_HOST'),
    database=os.getenv('DB_NAME', os.getenv(
        'STORAGE_PATH', PROJECT_DIR) + "/database.db"),
)

JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=15)
JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

SUPPORTED_LANGUAGES = {
    'en': 'English',
    'da': 'Dansk',
    'de': 'Deutsch',
    'es': 'Español',
    'fr': 'Français',
    'id': 'Bahasa Indonesia',
    'nb_NO': 'Bokmål',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'pt': 'Português',
    'pt_BR': 'Português Brasileiro',
    'ru': 'русский язык',
}

Flask.json_provider_class = KitchenOwlJSONProvider

app = Flask(__name__)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 32 * 1000 * 1000  # 32MB max upload
# SQLAlchemy
app.config['SQLALCHEMY_DATABASE_URI'] = DB_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
# JWT
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'super-secret')
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = JWT_ACCESS_TOKEN_EXPIRES
app.config["JWT_REFRESH_TOKEN_EXPIRES"] = JWT_REFRESH_TOKEN_EXPIRES


convention = {
    "ix": 'ix_%(column_0_label)s',
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s"
}

metadata = MetaData(naming_convention=convention)

db = SQLAlchemy(app, metadata=metadata)
migrate = Migrate(app, db, render_as_batch=True)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)

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
    url = os.environ['FRONT_URL'] if 'FRONT_URL' in os.environ else None
    if app.debug or url and r == url:
        response.headers.add('Access-Control-Allow-Origin', r)
        response.headers.add('Access-Control-Allow-Credentials', 'true')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
        response.headers.add('Access-Control-Allow-Headers', 'Cache-Control')
        response.headers.add(
            'Access-Control-Allow-Headers', 'X-Requested-With')
        response.headers.add('Access-Control-Allow-Headers', 'Authorization')
        response.headers.add('Access-Control-Allow-Methods',
                             'GET, POST, OPTIONS, PUT, DELETE')
    return response


@app.errorhandler(Exception)
def unhandled_exception(e):
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
