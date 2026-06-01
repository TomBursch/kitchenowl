from typing import Annotated
from pydantic import BaseModel, StringConstraints, PositiveInt


class AddCategory(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class UpdateCategory(BaseModel):
    name: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
    ordering: PositiveInt | None = None

    # if set this merges the specified category into this category thus combining them to one
    merge_category_id: PositiveInt | None = None


class DeleteCategory(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
