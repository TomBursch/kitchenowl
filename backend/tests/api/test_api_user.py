import pytest


def test_current_user_admin(admin_client, admin_username, admin_name):
    response = admin_client.get(
        "/api/user",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["username"] == admin_username
    assert data["name"] == admin_name


def test_current_user(user_client, username, name):
    response = user_client.get(
        "/api/user",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["username"] == username
    assert data["name"] == name


def test_current_user_unauthenticated(onboarded_client):
    response = onboarded_client.get(
        "/api/user",
    )
    assert response.status_code == 401


def test_create_user(admin_client, username, name, password):
    data = {"username": username, "name": name, "password": password}
    response = admin_client.post("/api/user/new", json=data)
    assert response.status_code == 200


def test_list_users_user(user_client):
    response = user_client.get(
        "/api/user/all",
    )
    assert response.status_code == 403


def test_list_users_admin(
    admin_client, admin_username, admin_name, username, name, password
):
    response = admin_client.get(
        "/api/user/all",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 1
    assert "admin" in data[0]
    assert data[0]["admin"] == True
    assert "name" in data[0]
    assert data[0]["name"] == admin_name
    assert "username" in data[0]
    assert data[0]["username"] == admin_username
    assert "id" in data[0]
    data = {"username": username, "name": name, "password": password}
    response = admin_client.post("/api/user/new", json=data)
    response = admin_client.get(
        "/api/user/all",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert len(data) == 2
    assert "admin" in data[0]
    assert data[0]["admin"] == True
    assert "name" in data[0]
    assert data[0]["name"] == admin_name
    assert "username" in data[0]
    assert data[0]["username"] == admin_username
    assert "admin" in data[1]
    assert data[1]["admin"] == False
    assert "name" in data[1]
    assert data[1]["name"] == name
    assert "username" in data[1]
    assert data[1]["username"] == username
    assert "id" in data[1]
