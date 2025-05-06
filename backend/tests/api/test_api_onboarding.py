import pytest


def test_onboarding_status_true(client):
    response = client.get(
        "/api/onboarding",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert "onboarding" in data
    assert data["onboarding"] == True


def test_onboarding_status_false(onboarded_client):
    response = onboarded_client.get(
        "/api/onboarding",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert "onboarding" in data
    assert data["onboarding"] == False


def test_onboarding(client, admin_username, admin_name, admin_password):
    onboard_data = {
        "username": admin_username,
        "name": admin_name,
        "password": admin_password,
    }
    response = client.post("/api/onboarding", json=onboard_data)
    assert response.status_code == 200
    data = response.get_json()
    assert "access_token" in data
    assert "refresh_token" in data
