from typing import Annotated

from pydantic import BaseModel, AfterValidator, EmailStr, StringConstraints

from app.helpers.validators import validate_non_emty_no_at


class CreateUser(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    username: Annotated[str, AfterValidator(validate_non_emty_no_at)]
    email: EmailStr | None = None
    password: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class UpdateUser(BaseModel):
    name: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
    photo: str | None = None
    username: Annotated[str | None, AfterValidator(validate_non_emty_no_at)] = None
    email: EmailStr | None = None
    password: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
    admin: bool | None = None


class SearchByNameRequest(BaseModel):
    query: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class ConfirmMail(BaseModel):
    token: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class ResetPassword(BaseModel):
    token: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    password: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]


class ForgotPassword(BaseModel):
    email: EmailStr
