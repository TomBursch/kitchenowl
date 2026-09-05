from typing import Annotated

from pydantic import BaseModel, StringConstraints


class AddHousehold(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    photo: str | None = None
    link: str | None = None
    description: str | None = None
    language: str | None = None
    planner_feature: bool | None = None
    expenses_feature: bool | None = None
    view_ordering: list[str] = []
    member: list[int] = []


class UpdateHousehold(BaseModel):
    name: Annotated[
        str | None, StringConstraints(min_length=1, strip_whitespace=True)
    ] = None
    photo: str | None = None
    link: str | None = None
    description: str | None = None
    language: str | None = None
    planner_feature: bool | None = None
    expenses_feature: bool | None = None
    view_ordering: list[str] | None = None


class UpdateHouseholdMember(BaseModel):
    admin: bool
