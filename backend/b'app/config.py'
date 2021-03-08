from app.errors import NotFoundRequest
from flask import Flask, jsonify
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
import os

MIN_FRONTEND_VERSION = 1
BACKEND_VERSION = 1

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.getenv('STORAGE_PATH','..') + '/database.db'
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY','super-secret')


db = SQLAlchemy(app)
migrate = Migrate(app, db)
bcrypt = Bcrypt(app)
jwt = JWTManager(app)


@app.errorhandler(Exception)
def unhandled_exception(e):
    if e is NotFoundRequest:
        return "Requested resource not found", 404
    app.logger.error(e)
    return jsonify(message="Something went wrong"), 500


@app.errorhandler(404)
def not_found(error):
    return "Requested resource not found", 404
