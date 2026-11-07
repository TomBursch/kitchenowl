import os
import tempfile

_tmp_dir = tempfile.TemporaryDirectory()

os.environ["DB_DRIVER"] = "sqlite"
os.environ["DB_NAME"] = os.path.join(_tmp_dir.name, "database.db")
os.environ["KITCHENOWL_MCP_ENABLED"] = "true"

import app
