from pydantic import BaseModel, Field, PositiveInt


class AddPlannedRecipe(BaseModel):
    recipe_id: int
    cooking_date: int
    day: int | None = Field(ge=0, le=6, default=None)
    yields: PositiveInt | None = None


class RemovePlannedRecipe(BaseModel):
    cooking_date: int
    day: int | None = Field(ge=0, le=6, default=None)
