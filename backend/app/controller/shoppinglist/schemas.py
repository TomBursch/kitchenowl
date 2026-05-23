from typing import Annotated

from pydantic import BaseModel, StringConstraints, Field


class GetShoppingLists(BaseModel):
    orderby: int | None = None
    recent_limit: Annotated[int, Field(gt=0, le=120)] = 9


class AddItemByName(BaseModel):
    name: str
    description: str | None = None


class AddRecipeItems(BaseModel):
    class RecipeItem(BaseModel):
        id: int
        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        description: str = ""
        optional: bool = True

    items: list[RecipeItem]


class CreateList(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class UpdateList(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class GetItems(BaseModel):
    orderby: int | None = None


class GetRecentItems(BaseModel):
    # Align deprecated endpoint limit with list endpoint (<=120)
    limit: Annotated[int, Field(gt=0, le=120)] = 9


class UpdateDescription(BaseModel):
    description: str


class RemoveItem(BaseModel):
    item_id: int
    removed_at: int | None = None


class RemoveItems(BaseModel):
    class RecipeItem(BaseModel):
        item_id: int
        removed_at: int | None = None

    items: list[RecipeItem]
