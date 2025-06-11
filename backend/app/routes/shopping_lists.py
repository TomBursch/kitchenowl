@shopping_lists_bp.route('/api/households/<int:household_id>/shoppinglists/reorder', methods=['PATCH'])
@jwt_required()
@require_household_access
def reorder_shopping_lists(household_id):
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    # Validate input
    if not data or 'ordered_ids' not in data:
        return jsonify({'error': 'Missing ordered_ids'}), 400
        
    ordered_ids = data['ordered_ids']
    if not isinstance(ordered_ids, list) or not ordered_ids:
        return jsonify({'error': 'Invalid ordered_ids format'}), 400

    # Get household and standard list
    household = Household.query.get_or_404(household_id)
    standard_id = household.standard_shoppinglist_id
    
    # Validate standard list position
    if standard_id and standard_id != ordered_ids[0]:
        return jsonify({'error': 'Standard list must remain first'}), 400

    # Verify all lists belong to household
    household_lists = {sl.id: sl for sl in ShoppingList.query.filter_by(household_id=household_id)}
    if len(ordered_ids) != len(household_lists) or any(id not in household_lists for id in ordered_ids):
        return jsonify({'error': 'Invalid list IDs'}), 400

    # Update orders
    for index, list_id in enumerate(ordered_ids):
        if list_id == standard_id:
            continue  # Standard list remains at 0
        household_lists[list_id].order = index
    
    db.session.commit()
    
    logger.info(f"User {current_user_id} reordered lists in household {household_id}")
    return jsonify({
        'success': True,
        'shopping_lists': [sl.to_dict() for sl in household_lists.values()]
    }), 200
