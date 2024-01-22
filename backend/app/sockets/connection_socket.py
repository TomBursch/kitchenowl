from flask_jwt_extended import current_user
from flask_socketio import join_room

from app.helpers import socket_jwt_required
from app import socketio


@socketio.on("connect")
@socket_jwt_required()
def on_connect():
    for household in current_user.households:
        join_room(household.household_id)


@socketio.on("reconnect")
@socket_jwt_required()
def on_reconnect():
    pass
