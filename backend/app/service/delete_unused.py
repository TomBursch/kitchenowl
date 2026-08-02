import json

from tqdm import tqdm
from app.models import Household, File
from app.models.agent_chat import AgentMessage
from app import app


def _agent_attached_filenames() -> set[str]:
    """Return the set of file filenames referenced in agent message attachments.

    Files that appear inside ``attachments_json`` must be excluded from the
    unused-file cleanup so that they remain accessible for regenerate/rewind
    flows and don't cause "missing on disk" errors for existing chats.
    """
    rows = (
        AgentMessage.query.filter(AgentMessage.attachments_json.isnot(None))
        .with_entities(AgentMessage.attachments_json)
        .all()
    )
    referenced: set[str] = set()
    for (attachments_json,) in rows:
        try:
            data = json.loads(attachments_json)
        except (json.JSONDecodeError, ValueError):
            continue
        for file_entry in data.get("files", []):
            if isinstance(file_entry, dict):
                filename = file_entry.get("filename")
                if filename:
                    referenced.add(str(filename))
    return referenced


def deleteUnusedFiles() -> int:
    agent_attached = _agent_attached_filenames()
    filesToDelete = [
        f for f in File.query.all() if f.isUnused() and f.filename not in agent_attached
    ]
    for f in tqdm(
        filesToDelete,
        desc="Deleting unused files",
    ):
        f.delete()
    app.logger.info(f"Deleted {len(filesToDelete)} unused files")
    return len(filesToDelete)


def deleteEmptyHouseholds() -> int:
    householdsToDelete = [h for h in Household.all() if len(h.member) == 0]
    for h in tqdm(
        householdsToDelete,
        desc="Deleting empty households",
    ):
        h.delete()
    app.logger.info(f"Deleted {len(householdsToDelete)} empty households")
    return len(householdsToDelete)
