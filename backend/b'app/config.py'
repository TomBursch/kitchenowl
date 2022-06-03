from sqlalchemy import MetaData
from app.errors import NotFoundRequest
from flask import Flask, jsonify, request
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
from flask_apscheduler import APScheduler
import os

MIN_FRONTEND_VERSION = 34
BACKEND_VERSION = 27

APP_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(APP_DIR)

UPLOAD_FOLDER = os.getenv('STORAGE_PATH', PROJECT_DIR) + '/upload'
ALLOWED_FILE_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif'}

SUPPORTED_LANGUAGES = {
    'en': 'English',
    'de': 'Deutsch'
}

app = Flask(__name__)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 32 * 1000 * 1000  # 32MB max upload
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + \
    os.getenv('STORAGE_PATH', PROJECT_DIR) + '/database.db'
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'super-secret')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

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
    if url and r == url:
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
    if e is NotFoundRequest:
        return "Requested resource not found", 404
    app.logger.error(e)
    return jsonify(message="Something went wrong"), 500


@app.errorhandler(404)
def not_found(error):
    return "Requested resource not found", 404
