from typing import Annotated
from pydantic import BaseModel, PositiveInt, StringConstraints


class ImportSchema(BaseModel):
    class Item(BaseModel):
        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        category: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        icon: str | None

    class Recipe(BaseModel):
        class RecipeItem(BaseModel):
            name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
            optional: bool = False
            description: str = ""

        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        description: str = ""
        time: PositiveInt | None = None
        cook_time: PositiveInt | None = None
        prep_time: PositiveInt | None = None
        yields: PositiveInt | None = None
        source: str | None = None
        photo: str | None = None
        items: list[RecipeItem]
        tags: list[str]

    class Expense(BaseModel):
        class PaidFor(BaseModel):
            username: Annotated[
                str, StringConstraints(min_length=1, strip_whitespace=True)
            ]
            factor: int = 1

        class Category(BaseModel):
            name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
            color: int | None = None

        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        amount: float
        date: int | None
        paid_by: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        paid_for: list[PaidFor]
        photo: str | None = None
        category: Category | None = None

    items: list[Item]
    recipes: list[Recipe]
    recipe_overwrite: bool
    expenses: list[Expense]
    member: list[str]
    shoppinglists: list[str]
