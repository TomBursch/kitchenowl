from typing import Annotated

from pydantic import BaseModel, Field, PositiveInt, StringConstraints


class GetExpenses(BaseModel):
    view: int
    startAfterId: PositiveInt | None = None
    startAfterDate: PositiveInt | None = None
    endBeforeDate: PositiveInt | None = None
    filter: list[int | None] = []
    search: str | None = None


class AddExpense(BaseModel):
    class User(BaseModel):
        id: PositiveInt
        name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
        factor: int = 1

    name: str
    amount: float
    description: str | None = None
    date: int | None = None
    photo: str | None = None
    category: int | None = None
    paid_by: User
    paid_for: list[User] = Field(min_length=1)
    exclude_from_statistics: bool = False


class UpdateExpense(BaseModel):
    class User(BaseModel):
        id: PositiveInt
        name: Annotated[
            str | None, StringConstraints(min_length=1, strip_whitespace=True)
        ] = None
        factor: int = 1

    name: str | None = None
    amount: float | None = None
    description: str | None = None
    date: int | None = None
    photo: str | None = None
    category: int | None = None
    paid_by: User | None = None
    paid_for: list[User] | None = None
    exclude_from_statistics: bool | None = None


class AddExpenseCategory(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    color: int | None = Field(ge=0)
    budget: float | None = None


class UpdateExpenseCategory(BaseModel):
    name: Annotated[str, StringConstraints(min_length=1, strip_whitespace=True)]
    color: int | None = Field(ge=0, default=None)
    budget: float | None = None

    # if set this merges the specified category into this category thus combining them to one
    merge_category_id: int | None = Field(gt=0, default=None)


class GetExpenseOverview(BaseModel):
    # household = 0, personal = 1
    view: int
    # daily = 0, weekly = 1, montly = 2, yearly = 3
    frame: int = Field(ge=0, le=3)
    # how many frames are looked at
    steps: int = Field(gt=0)
    # used for pagination (i.e. start of steps, now=0)
    page: int | None = Field(ge=0, default=None)
