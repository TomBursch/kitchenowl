def safe_error_message(
    exc: BaseException,
    fallback: str = "Internal error",
    max_length: int = 200,
) -> str:
    """Return a single-line, length-capped exception message for clients."""
    raw = exc.args[0] if exc.args else ""
    text = str(raw) if raw else ""
    first_line = text.splitlines()[0] if text.splitlines() else ""
    return first_line[:max_length] or fallback
