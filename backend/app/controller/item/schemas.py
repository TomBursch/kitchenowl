from typing import Annotated
from pydantic import BaseModel, PositiveInt, StringConstraints


class SearchByNameRequest(BaseModel):
    query: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None


class UpdateItem(BaseModel):
    class Category(BaseModel):
        id: PositiveInt
        name: Annotated[
            str | None, StringConstraints(min_length=1, strip_whitespace=True)
        ] = None

    category: Category | None = None
    icon: str | None = None
    name: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None

    # if set this merges the specified item into this item thus combining them to one
    merge_item_id: PositiveInt | None = None


class AddItem(BaseModel):
    class Category(BaseModel):
        id: PositiveInt
        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]

    category: Category | None = None
    icon: Annotated[str | None, StringConstraints(min_length=1, strip_whitespace=True)]
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
