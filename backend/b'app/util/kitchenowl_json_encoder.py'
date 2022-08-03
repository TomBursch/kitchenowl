from flask.json import JSONEncoder
from datetime import date, timezone


class KitchenOwlJSONEncoder(JSONEncoder):
    def default(self, o):
        if isinstance(o, date):
            return int(round(o.replace(tzinfo=timezone.utc).timestamp() * 1000))

        return super().default(o)