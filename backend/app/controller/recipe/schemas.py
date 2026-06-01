from typing import Annotated
from pydantic import BaseModel, PositiveInt, StringConstraints


class AddRecipe(BaseModel):
    class RecipeItem(BaseModel):
        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        description: str = ""
        optional: bool = True

    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    description: str
    time: PositiveInt | None = None
    cook_time: PositiveInt | None = None
    prep_time: PositiveInt | None = None
    yields: PositiveInt | None = None
    source: str | None = None
    server_curated: bool | None = None
    photo: str | None = None
    visibility: PositiveInt | None = None
    items: list[RecipeItem] = []
    tags: list[str] = []


class UpdateRecipe(BaseModel):
    class RecipeItem(BaseModel):
        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        description: str
        optional: bool = True

    name: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
    description: str | None = None
    time: PositiveInt | None = None
    cook_time: PositiveInt | None = None
    prep_time: PositiveInt | None = None
    yields: PositiveInt | None = None
    source: str | None = None
    server_curated: bool | None = None
    photo: str | None = None
    visibility: PositiveInt | None = None
    items: list[RecipeItem] | None = None
    tags: list[str] | None = None


class SearchByNameRequest(BaseModel):
    query: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    page: PositiveInt = 0
    language: str | None = None
    only_ids: bool = False


class SearchByTagRequest(BaseModel):
    tag: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    page: PositiveInt = 0
    language: str | None


class GetAllFilterRequest(BaseModel):
    filter: list[str]


class AddItemByName(BaseModel):
    name: str
    description: str | None


class RemoveItem(BaseModel):
    item_id: int


class ScrapeRecipe(BaseModel):
    url: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class SuggestionsRecipe(BaseModel):
    language: str | None
