from typing import Annotated

from pydantic import AfterValidator, BaseModel, StringConstraints

from app.helpers.validators import validate_non_emty_no_at


class OnboardSchema(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    # TODO: load only for username and password and device
    username: Annotated[str, AfterValidator(validate_non_emty_no_at)]
    password: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    device: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
