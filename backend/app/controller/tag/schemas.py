from typing import Annotated
from pydantic import BaseModel, StringConstraints, PositiveInt


class AddTag(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class UpdateTag(BaseModel):
    name: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None

    # if set this merges the specified tag into this tag thus combining them to one
    merge_tag_id: PositiveInt | None = None
