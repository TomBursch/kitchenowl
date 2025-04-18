from flask.json.provider import DefaultJSONProvider
from datetime import date, timezone


class KitchenOwlJSONProvider(DefaultJSONProvider):
    def default(self, o):  # type: ignore[assignment]
        if isinstance(o, date):
            return int(round(o.replace(tzinfo=timezone.utc).timestamp() * 1000))

        return super().default(o)
