from typing import Annotated

from pydantic import BaseModel, StringConstraints


class AddReport(BaseModel):
    description: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
    recipe_id: int | None = None
    user_id: int | None = None
