from tqdm import tqdm
from app.models import Household, File
from app import app


def deleteUnusedFiles() -> int:
    filesToDelete = [f for f in File.query.all() if f.isUnused()]
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
