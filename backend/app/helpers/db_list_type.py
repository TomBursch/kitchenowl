from sqlalchemy.types import String, TypeDecorator
import json


# Represents a List in the DataBase (i.e. [e1, e2, e3, ...])
class DbListType(TypeDecorator):
    impl = String

    def process_bind_param(self, value, dialect):
        if type(value) is list:
            return json.dumps(value)
        else:
            return "[]"

    def process_result_value(self, value, dialect) -> list:
        if type(value) is str:
            return json.loads(value)
        return list()
