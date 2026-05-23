from typing import Annotated
from pydantic import AfterValidator, BaseModel, EmailStr, StringConstraints

from app.config import EMAIL_MANDATORY
from app.helpers.validators import validate_non_emty_no_at


class Login(BaseModel):
    username: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    password: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    device: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None


class Signup(BaseModel):
    username: Annotated[str, AfterValidator(validate_non_emty_no_at)]
    email: Annotated[
        EmailStr | None, AfterValidator(lambda x: EMAIL_MANDATORY or x is not None)
    ] = None
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    password: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    device: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None


class CreateLongLivedToken(BaseModel):
    device: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class GetOIDCLoginUrl(BaseModel):
    provider: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    kitchenowl_scheme: bool = False


class LoginOIDC(BaseModel):
    state: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    code: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    device: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
