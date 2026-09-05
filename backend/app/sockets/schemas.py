from pydantic import BaseModel


class shoppinglist_item_add(BaseModel):
    shoppinglist_id: int
    name: str
    description: str | None


class shoppinglist_item_remove(BaseModel):
    shoppinglist_id: int
    item_id: int
