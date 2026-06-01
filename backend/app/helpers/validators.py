from pydantic import ValidationError


def validate_non_emty_no_at(value: str) -> str:
    if not value or value.isspace() or "@" in value:
        raise ValidationError(
            "Value must be non-empty, not just whitespace, and must not contain '@'"
        )
    return value
