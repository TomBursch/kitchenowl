from sqlalchemy.types import String, TypeDecorator
import json


# Represents a Set in the DataBase (i.e. {e1, e2, e3, ...})
class DbSetType(TypeDecorator):
    impl = String

    def process_bind_param(self, value, dialect):
        if type(value) is set:
            return json.dumps(list(value))
        else:
            return "[]"

    def process_result_value(self, value, dialect) -> set:
        if type(value) is str:
            return set(json.loads(value))
        return set()
