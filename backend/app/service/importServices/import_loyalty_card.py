from app.models import LoyaltyCard


def importLoyaltyCard(household, card_data):
    card = LoyaltyCard.query.filter_by(
        household_id=household.id, name=card_data["name"]
    ).first()

    if not card:
        card = LoyaltyCard()
        card.household_id = household.id
        card.name = card_data["name"]

    if "barcode_data" in card_data:
        card.barcode_data = card_data["barcode_data"]

    if "barcode_type" in card_data:
        card.barcode_type = card_data["barcode_type"]

    if "description" in card_data:
        card.description = card_data["description"]

    if "color" in card_data:
        card.color = card_data["color"]

    card.save()
