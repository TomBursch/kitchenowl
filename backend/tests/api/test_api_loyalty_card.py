"""Tests for Loyalty Card API endpoints."""
import pytest


@pytest.fixture
def loyalty_card_data():
    """Sample loyalty card data for testing."""
    return {
        "name": "Test Store Card",
        "barcode_type": "CODE128",
        "barcode_data": "1234567890",
        "description": "My test loyalty card",
        "color": 4280391411,  # Blue color as int
    }


@pytest.fixture
def updated_loyalty_card_data():
    """Updated loyalty card data for testing updates."""
    return {
        "name": "Updated Store Card",
        "barcode_type": "QR",
        "barcode_data": "9876543210",
        "description": "Updated description",
    }


class TestLoyaltyCardAPI:
    """Test suite for Loyalty Card API endpoints."""

    def test_get_all_loyalty_cards_empty(
        self, user_client_with_household, household_id
    ):
        """Test getting loyalty cards for a household with no cards."""
        response = user_client_with_household.get(
            f"/api/household/{household_id}/loyalty-card"
        )
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, list)
        assert len(data) == 0

    def test_create_loyalty_card(
        self, user_client_with_household, household_id, loyalty_card_data
    ):
        """Test creating a new loyalty card."""
        response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=loyalty_card_data,
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["name"] == loyalty_card_data["name"]
        assert data["barcode_type"] == loyalty_card_data["barcode_type"]
        assert data["barcode_data"] == loyalty_card_data["barcode_data"]
        assert data["description"] == loyalty_card_data["description"]
        assert data["color"] == loyalty_card_data["color"]
        assert "id" in data

    def test_create_loyalty_card_minimal(
        self, user_client_with_household, household_id
    ):
        """Test creating a loyalty card with minimal required fields."""
        minimal_data = {
            "name": "Minimal Card",
            "barcode_type": "EAN13",
            "barcode_data": "5901234123457",
        }
        response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=minimal_data,
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["name"] == minimal_data["name"]
        assert data["barcode_type"] == minimal_data["barcode_type"]
        assert data["barcode_data"] == minimal_data["barcode_data"]

    def test_get_all_loyalty_cards_after_create(
        self, user_client_with_household, household_id, loyalty_card_data
    ):
        """Test getting all loyalty cards after creating one."""
        # Create a card first
        user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=loyalty_card_data,
        )
        
        # Get all cards
        response = user_client_with_household.get(
            f"/api/household/{household_id}/loyalty-card"
        )
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 1
        assert data[0]["name"] == loyalty_card_data["name"]

    def test_get_loyalty_card_by_id(
        self, user_client_with_household, household_id, loyalty_card_data
    ):
        """Test getting a single loyalty card by ID."""
        # Create a card first
        create_response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=loyalty_card_data,
        )
        card_id = create_response.get_json()["id"]
        
        # Get the card by ID
        response = user_client_with_household.get(
            f"/api/loyalty-card/{card_id}"
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["id"] == card_id
        assert data["name"] == loyalty_card_data["name"]

    def test_get_loyalty_card_not_found(self, user_client_with_household):
        """Test getting a non-existent loyalty card returns 404."""
        response = user_client_with_household.get("/api/loyalty-card/99999")
        assert response.status_code == 404

    def test_update_loyalty_card(
        self,
        user_client_with_household,
        household_id,
        loyalty_card_data,
        updated_loyalty_card_data,
    ):
        """Test updating a loyalty card."""
        # Create a card first
        create_response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=loyalty_card_data,
        )
        card_id = create_response.get_json()["id"]
        
        # Update the card
        response = user_client_with_household.post(
            f"/api/loyalty-card/{card_id}",
            json=updated_loyalty_card_data,
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["name"] == updated_loyalty_card_data["name"]
        assert data["barcode_type"] == updated_loyalty_card_data["barcode_type"]
        assert data["barcode_data"] == updated_loyalty_card_data["barcode_data"]

    def test_update_loyalty_card_partial(
        self, user_client_with_household, household_id, loyalty_card_data
    ):
        """Test partial update of a loyalty card."""
        # Create a card first
        create_response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=loyalty_card_data,
        )
        card_id = create_response.get_json()["id"]
        
        # Partial update - only change name
        partial_update = {"name": "Partially Updated Card"}
        response = user_client_with_household.post(
            f"/api/loyalty-card/{card_id}",
            json=partial_update,
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["name"] == partial_update["name"]
        # Original values should be preserved
        assert data["barcode_type"] == loyalty_card_data["barcode_type"]
        assert data["barcode_data"] == loyalty_card_data["barcode_data"]

    def test_delete_loyalty_card(
        self, user_client_with_household, household_id, loyalty_card_data
    ):
        """Test deleting a loyalty card."""
        # Create a card first
        create_response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=loyalty_card_data,
        )
        card_id = create_response.get_json()["id"]
        
        # Delete the card
        response = user_client_with_household.delete(
            f"/api/loyalty-card/{card_id}"
        )
        assert response.status_code == 200
        
        # Verify it's deleted
        get_response = user_client_with_household.get(
            f"/api/loyalty-card/{card_id}"
        )
        assert get_response.status_code == 404

    def test_delete_loyalty_card_not_found(self, user_client_with_household):
        """Test deleting a non-existent loyalty card returns 404."""
        response = user_client_with_household.delete("/api/loyalty-card/99999")
        assert response.status_code == 404

    def test_create_loyalty_card_missing_required_field(
        self, user_client_with_household, household_id
    ):
        """Test creating a loyalty card with missing required fields fails."""
        # Missing barcode_data
        incomplete_data = {
            "name": "Incomplete Card",
            "barcode_type": "CODE128",
        }
        response = user_client_with_household.post(
            f"/api/household/{household_id}/loyalty-card",
            json=incomplete_data,
        )
        assert response.status_code == 400

    def test_multiple_loyalty_cards_ordered_by_name(
        self, user_client_with_household, household_id
    ):
        """Test that multiple loyalty cards are returned ordered by name."""
        cards = [
            {"name": "Zebra Store", "barcode_type": "CODE128", "barcode_data": "111"},
            {"name": "Alpha Market", "barcode_type": "CODE128", "barcode_data": "222"},
            {"name": "Beta Shop", "barcode_type": "CODE128", "barcode_data": "333"},
        ]
        
        for card in cards:
            user_client_with_household.post(
                f"/api/household/{household_id}/loyalty-card",
                json=card,
            )
        
        response = user_client_with_household.get(
            f"/api/household/{household_id}/loyalty-card"
        )
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 3
        # Should be ordered alphabetically by name
        assert data[0]["name"] == "Alpha Market"
        assert data[1]["name"] == "Beta Shop"
        assert data[2]["name"] == "Zebra Store"


class TestLoyaltyCardAuthorization:
    """Test authorization for Loyalty Card API endpoints."""

    def test_get_loyalty_cards_requires_auth(self, client):
        """Test that getting loyalty cards requires authentication."""
        response = client.get("/api/household/1/loyalty-card")
        assert response.status_code == 401

    def test_create_loyalty_card_requires_auth(self, client):
        """Test that creating loyalty cards requires authentication."""
        response = client.post(
            "/api/household/1/loyalty-card",
            json={"name": "Test", "barcode_type": "QR", "barcode_data": "123"},
        )
        assert response.status_code == 401

    def test_get_loyalty_card_requires_auth(self, client):
        """Test that getting a single loyalty card requires authentication."""
        response = client.get("/api/loyalty-card/1")
        assert response.status_code == 401

    def test_update_loyalty_card_requires_auth(self, client):
        """Test that updating a loyalty card requires authentication."""
        response = client.post(
            "/api/loyalty-card/1",
            json={"name": "Updated"},
        )
        assert response.status_code == 401

    def test_delete_loyalty_card_requires_auth(self, client):
        """Test that deleting a loyalty card requires authentication."""
        response = client.delete("/api/loyalty-card/1")
        assert response.status_code == 401
