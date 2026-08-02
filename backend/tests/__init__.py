import importlib
import os
import tempfile

_test_storage = tempfile.TemporaryDirectory(prefix="kitchenowl-tests-")
os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_NAME"] = os.path.join(_test_storage.name, "database.db")
os.environ["JWT_SECRET_KEY"] = "kitchenowl-test-secret-at-least-32-bytes"
os.environ["LLM_ENCRYPTION_KEY"] = "kVkJTed7cYlTUoQaVHi65tRIViE88hhM1PliNE5-BdM="
os.environ["KITCHENOWL_MCP_ENABLED"] = "true"

app = importlib.import_module("app")
