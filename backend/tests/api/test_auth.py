import jwt


def get_jti(token):
    decoded = jwt.decode(token, options={"verify_signature": False})
    return decoded.get("jti")


def test_normal_token_refresh(user_client, username, password):
    """Test normal token refresh flow."""
    # Login
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # Use access token
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {access_token}"}
    )
    assert response.status_code == 200

    # Refresh token
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    new_access_token = data["access_token"]
    new_refresh_token = data["refresh_token"]

    # Use new access token
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {new_access_token}"}
    )
    assert response.status_code == 200


def test_shaky_network_token_refresh(user_client, username, password):
    """Test token refresh with network issues (client ignores new tokens)."""
    # Login
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # Use access token
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {access_token}"}
    )
    assert response.status_code == 200

    # Refresh token but "lose" the response
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    # Intentionally ignore new tokens

    # Use old access token, should not work since refresh invalidates them
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {access_token}"}
    )
    assert response.status_code == 401

    # Original refresh token should still work since we didn't use the new one
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    new_access_token = data["access_token"]

    # New access token should work
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {new_access_token}"}
    )
    assert response.status_code == 200


def test_token_hijack_attempt(user_client, username, password):
    """Test attempted token hijacking scenario."""
    # Login
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # Create new refresh token but don't use its access token (simulating leak)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    leaked_access_token = data["access_token"]
    leaked_refresh_token = data["refresh_token"]

    # User cannot continue normal use with original access token
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {access_token}"}
    )
    assert response.status_code == 401

    # Create another refresh token (normal use)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    new_access_token = data["access_token"]
    new_refresh_token = data["refresh_token"]

    # Use new access token to make it the active chain
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {new_access_token}"}
    )
    assert response.status_code == 200

    # Attacker tries to use leaked access token
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {leaked_access_token}"}
    )
    assert response.status_code == 401  # Should be rejected

    # Attacker tries to use leaked refresh token
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {leaked_refresh_token}"}
    )
    assert response.status_code == 401  # Should be rejected

    # Original user's new tokens should also be rejected, as there was a breach
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {new_refresh_token}"}
    )
    assert response.status_code == 401


def test_token_hijack_attacker_first(user_client, username, password):
    """Test attempted token hijacking scenario where attacker acts first."""
    # Login
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # Attacker uses refresh token first
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    attacker_access_token = data["access_token"]
    attacker_refresh_token = data["refresh_token"]

    # Attacker uses their access token
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {attacker_access_token}"}
    )
    assert response.status_code == 200

    # Original user tries to use original refresh token - should be rejected
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 401  # Should be rejected

    # Attacker uses their access token - should be rejected after compromise detected
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {attacker_access_token}"}
    )
    assert response.status_code == 401

    # Attacker tries to refresh - should be rejected after compromise detected
    response = user_client.get(
        "/api/auth/refresh",
        headers={"Authorization": f"Bearer {attacker_refresh_token}"},
    )
    assert response.status_code == 401  # Should be rejected


def test_token_refresh_race_condition(user_client, username, password):
    """Test race condition where two refresh requests happen before either access token is used."""
    # Login
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # First client requests refresh
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    first_access_token = data["access_token"]
    first_refresh_token = data["refresh_token"]

    # Second client requests refresh before first access token is used
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    second_access_token = data["access_token"]
    second_refresh_token = data["refresh_token"]

    # Second client uses their access token first
    response = user_client.get(
        "/api/user", headers={"Authorization": f"Bearer {second_access_token}"}
    )
    assert response.status_code == 200

    # First client tries to use their refresh token - should be rejected
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {first_refresh_token}"}
    )
    assert response.status_code == 401  # Should be rejected

    # Original refresh token should be rejected
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {refresh_token}"}
    )
    assert response.status_code == 401  # Should be rejected


def test_complex_token_chain(user_client, username, password):
    """Test complex token chain with multiple parallel unused refresh tokens.

    Chain state:
    RT1 (Used) -> AT1 (Unused)
                  RT2 (Used) -> AT2 (Used)
                               RT3 (Unused) -> AT3 (Unused)
                               RT4 (Unused) -> AT4 (Unused)
                               RT5 (Unused) -> AT5 (Unused)
    """
    # Initial login to get RT1
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at1 = data["access_token"]
    rt1 = data["refresh_token"]

    # Use RT1 to get RT2 (don't use AT1)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt1}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at2 = data["access_token"]
    rt2 = data["refresh_token"]

    # Use RT2 to create three parallel chains (RT3, RT4, RT5)
    # First chain (RT3)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at3 = data["access_token"]
    rt3 = data["refresh_token"]

    # Second chain (RT4)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at4 = data["access_token"]
    rt4 = data["refresh_token"]

    # Third chain (RT5)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at5 = data["access_token"]
    rt5 = data["refresh_token"]

    # AT2 should be rejected (refresh invalidates AT but not RT)
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at2}"})
    assert response.status_code == 401

    # RT5/AT5 chain should work (last created refresh token)
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at5}"})
    assert response.status_code == 200
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt5}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at6 = data["access_token"]
    rt6 = data["refresh_token"]

    # Verify unused tokens from parallel chains are rejected triggering breach detection
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt4}"}
    )
    assert response.status_code == 401

    # Check that no token works anymore
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at1}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt1}"}
    )
    assert response.status_code == 401
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at2}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 401
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at3}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt3}"}
    )
    assert response.status_code == 401
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at4}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt4}"}
    )
    assert response.status_code == 401
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at5}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt5}"}
    )
    assert response.status_code == 401
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at6}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt6}"}
    )
    assert response.status_code == 401


def test_complex_token_chain2(user_client, username, password):
    """Test complex token chain with multiple parallel unused refresh tokens.

    Chain state:
    RT1 (Used) -> AT1 (Unused)
                  RT2 (Used) -> AT2 (Unused)
                               RT3 (Unused) -> AT3 (Unused)
                               RT4 (Unused) -> AT4 (Unused)
                               RT5 (Unused) -> AT5 (Used)
    """
    # Initial login to get RT1
    response = user_client.post(
        "/api/auth", json={"username": username, "password": password, "device": "test"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at1 = data["access_token"]
    rt1 = data["refresh_token"]

    # Use RT1 to get RT2 (don't use AT1)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt1}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at2 = data["access_token"]
    rt2 = data["refresh_token"]

    # Use RT2 to create three parallel chains (RT3, RT4, RT5)
    # First chain (RT3)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at3 = data["access_token"]
    rt3 = data["refresh_token"]

    # Second chain (RT4)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at4 = data["access_token"]
    rt4 = data["refresh_token"]

    # Third chain (RT5)
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt2}"}
    )
    assert response.status_code == 200
    data = response.get_json()
    at5 = data["access_token"]
    rt5 = data["refresh_token"]

    # Use AT5 to make it the active chain
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at5}"})
    assert response.status_code == 200

    # Verify AT5 is still working
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at5}"})
    assert response.status_code == 200

    # Try to use RT4, this should be rejected as a breach
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt4}"}
    )
    assert response.status_code == 401

    # Verify that now also AT5 and RT5 are invalid
    response = user_client.get("/api/user", headers={"Authorization": f"Bearer {at5}"})
    assert response.status_code == 401
    response = user_client.get(
        "/api/auth/refresh", headers={"Authorization": f"Bearer {rt5}"}
    )
    assert response.status_code == 401


def _add_oidc_link(username, provider, sub):
    from app.models import User, OIDCLink

    user = User.find_by_username(username)
    OIDCLink(sub=sub, provider=provider, user_id=user.id).save()
    return user


def _oidc_links(user_client):
    response = user_client.get("/api/user")
    assert response.status_code == 200
    return response.get_json()["oidc_links"]


def test_unlink_oidc(user_client, username):
    """User with a password can unlink an OIDC provider."""
    _add_oidc_link(username, "custom", "keycloak-sub")
    assert _oidc_links(user_client) == ["custom"]

    response = user_client.delete("/api/auth/oidc/custom")
    assert response.status_code == 200
    assert _oidc_links(user_client) == []

    # Unlinking again: not linked anymore
    response = user_client.delete("/api/auth/oidc/custom")
    assert response.status_code == 404


def test_unlink_oidc_not_linked(user_client):
    response = user_client.delete("/api/auth/oidc/google")
    assert response.status_code == 404


def test_unlink_oidc_last_login_method(user_client, username):
    """Without a password the only OIDC link must not be removed."""
    from app import db

    user = _add_oidc_link(username, "custom", "keycloak-sub")
    user.password = None
    db.session.commit()

    response = user_client.delete("/api/auth/oidc/custom")
    assert response.status_code == 400
    assert _oidc_links(user_client) == ["custom"]

    # With another provider linked it is allowed
    _add_oidc_link(username, "google", "google-sub")
    response = user_client.delete("/api/auth/oidc/custom")
    assert response.status_code == 200
    assert _oidc_links(user_client) == ["google"]


def test_unlink_oidc_only_own_links(user_client, username, admin_username):
    """Unlinking only affects the current user's links."""
    _add_oidc_link(admin_username, "custom", "admin-sub")
    _add_oidc_link(username, "custom", "user-sub")

    response = user_client.delete("/api/auth/oidc/custom")
    assert response.status_code == 200

    from app.models import OIDCLink

    assert OIDCLink.find_by_ids("admin-sub", "custom") is not None
    assert OIDCLink.find_by_ids("user-sub", "custom") is None


def test_unlink_oidc_requires_auth(client):
    response = client.delete("/api/auth/oidc/custom")
    assert response.status_code == 401
