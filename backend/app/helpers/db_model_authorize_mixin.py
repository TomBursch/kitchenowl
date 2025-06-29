from flask_jwt_extended import current_user
from app.errors import UnauthorizedRequest, ForbiddenRequest
import app


class DbModelAuthorizeMixin(object):
    def isAuthorized(
        self, requires_admin=False, household_id: int | None = None
    ) -> bool:
        """
        Returns true if current user ist authorized to access this model.
        IMPORTANT: requires household_id
        """
        if not household_id and not hasattr(self, "household_id"):
            raise Exception("Wrong usage of authorize_household")
        if not current_user:
            return False
        member = app.models.household.HouseholdMember.find_by_ids(
            household_id or self.household_id, current_user.id
        )
        if not current_user.admin:
            if not member or requires_admin and not (member.admin or member.owner):
                return False

        return True

    def checkAuthorized(self, requires_admin=False, household_id: int | None = None):
        """
        Checks if current user ist authorized to access this model. Throws and unauthorized exception if not
        IMPORTANT: requires household_id
        """
        if not current_user:
            raise UnauthorizedRequest()
        if not self.isAuthorized(requires_admin, household_id):
            raise ForbiddenRequest()
