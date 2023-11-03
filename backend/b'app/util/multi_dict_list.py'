import marshmallow


class MultiDictList(marshmallow.fields.List):
    def _deserialize(self, value, attr, data, **kwargs):
        if isinstance(data, dict) and hasattr(data, "getlist"):
            value = data.getlist(attr)
        return super()._deserialize(value, attr, data, **kwargs)
