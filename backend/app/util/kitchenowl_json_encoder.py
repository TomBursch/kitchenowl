from flask.json import JSONEncoder
from datetime import date


class KitchenOwlJSONEncoder(JSONEncoder):
    def default(self, o):
        if isinstance(o, date):
            return int(round(o.timestamp() * 1000))

        return super().default(o)