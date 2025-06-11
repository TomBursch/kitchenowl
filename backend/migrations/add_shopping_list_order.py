def upgrade():
    op.add_column('shopping_lists', sa.Column('order', sa.Integer(), nullable=False, server_default='0'))
    
    # Set standard list order to 0 and others incrementally
    connection = op.get_bind()
    connection.execute(sa.text("""
        UPDATE shopping_lists 
        SET "order" = subquery.row_num
        FROM (
            SELECT 
                id,
                ROW_NUMBER() OVER (
                    PARTITION BY household_id 
                    ORDER BY 
                        CASE WHEN id = (SELECT standard_shoppinglist_id FROM households WHERE id = household_id) THEN 0 ELSE 1 END,
                        created_at
                ) - 1 AS row_num
            FROM shopping_lists
        ) AS subquery
        WHERE shopping_lists.id = subquery.id
    """))
