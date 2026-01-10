import enum
from flask.json.provider import DefaultJSONProvider
from datetime import date, datetime, timezone


class KitchenOwlJSONProvider(DefaultJSONProvider):
    def default(self, o):  # type: ignore[assignment]
        if isinstance(o, (datetime, date)):
            return int(round(o.replace(tzinfo=timezone.utc).timestamp() * 1000))
        if isinstance(o, enum.Enum):
            return int(o.value)

        return super().default(o)
