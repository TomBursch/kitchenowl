from __future__ import annotations

import gzip
import io
import json
import zipfile
from pathlib import Path
from unittest.mock import patch

from app import db
from app.config import UPLOAD_FOLDER
from app.models import Household, Recipe, RecipeTags, Tag
from app.service.recipe_import_service import (
    commit_recipe_import,
    preview_recipe_import,
)


PNG_ONE = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010802000000907753de"
    "0000000a49444154789c6360000002000154a2f6450000000049454e44ae426082"
)
PNG_TWO = bytes.fromhex(
    "89504e470d0a1a0a0000000d4948445200000001000000010802000000907753de"
    "0000000a49444154789c63f8cf0000020301ff7f0f9c0000000049454e44ae426082"
)


def _make_zip(entries: dict[str, bytes]) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path, data in entries.items():
            archive.writestr(path, data)
    return buffer.getvalue()


def _make_gzip_json(payload: dict) -> bytes:
    return gzip.compress(json.dumps(payload).encode("utf-8"))


def _get_recipe(household_id: int, name: str) -> Recipe:
    return Recipe.query.filter_by(household_id=household_id, name=name).one()


def _read_uploaded_photo(filename: str) -> bytes:
    return Path(UPLOAD_FOLDER, filename).read_bytes()


def _create_household(name: str) -> Household:
    household = Household(name=name)
    db.session.add(household)
    db.session.commit()
    return household


def _create_recipe_with_tag(household: Household, name: str, tag_name: str) -> None:
    recipe = Recipe(
        household_id=household.id,
        name=name,
        description="Existing recipe",
    )
    tag = Tag(name=tag_name, household_id=household.id)
    db.session.add_all([recipe, tag])
    db.session.commit()

    db.session.add(
        RecipeTags(
            recipe_id=recipe.id,
            tag_id=tag.id,
        )
    )
    db.session.commit()


def test_recipe_import_nextcloud_and_tandoor_folder_images(client):
    household = _create_household("Nextcloud import")
    payload_one = {
        "name": "Folder One Pasta",
        "description": "First recipe",
        "ingredients": [{"name": "Tomato", "quantity": "1"}],
        "image": "preview.jpg",
    }
    payload_two = {
        "name": "Folder Two Salad",
        "description": "Second recipe",
        "ingredients": [{"name": "Lettuce", "quantity": "2"}],
        "image": "preview.jpg",
    }
    archive = _make_zip(
        {
            "Recipes/Folder One/recipe.json": json.dumps(payload_one).encode("utf-8"),
            "Recipes/Folder One/preview.jpg": PNG_ONE,
            "Recipes/Folder Two/recipe.json": json.dumps(payload_two).encode("utf-8"),
            "Recipes/Folder Two/preview.jpg": PNG_TWO,
        }
    )

    preview = preview_recipe_import(household.id, archive, "Recipes.zip")
    assert len(preview["recipes"]) == 2

    def _save_image_bytes(file_bytes, filename, _user_id):
        saved_name = f"test_{filename}"
        Path(UPLOAD_FOLDER, saved_name).write_bytes(file_bytes)
        return saved_name

    with patch(
        "app.service.recipe_import_service._store_image_bytes",
        side_effect=_save_image_bytes,
    ), patch(
        "app.service.importServices.import_recipe.file_has_access_or_download",
        side_effect=lambda value, **kwargs: value,
    ):
        result = commit_recipe_import(
            household.id,
            preview["token"],
            {recipe["import_id"]: "copy" for recipe in preview["recipes"]},
        )
    assert result["imported"] == 2

    first = _get_recipe(household.id, "Folder One Pasta")
    second = _get_recipe(household.id, "Folder Two Salad")
    assert first.photo
    assert second.photo
    assert first.photo != second.photo
    assert _read_uploaded_photo(first.photo) == PNG_ONE
    assert _read_uploaded_photo(second.photo) == PNG_TWO


def test_recipe_import_mealie_backup_zip(client):
    household = _create_household("Mealie import")
    archive = _make_zip(
        {
            "backup/recipes/mealie-breakfast.json": json.dumps(
                {
                    "name": "Mealie Breakfast",
                    "description": "Mealie-style backup export",
                    "ingredients": [
                        {"name": "Egg", "quantity": "2"},
                    ],
                }
            ).encode("utf-8"),
        }
    )

    preview = preview_recipe_import(household.id, archive, "mealie-backup.zip")
    assert [recipe["name"] for recipe in preview["recipes"]] == ["Mealie Breakfast"]

    result = commit_recipe_import(
        household.id,
        preview["token"],
        {preview["recipes"][0]["import_id"]: "copy"},
    )
    assert result["imported"] == 1
    assert _get_recipe(household.id, "Mealie Breakfast").description.startswith(
        "Mealie-style backup export"
    )


def test_recipe_import_paprika_gzipped_zip_entries(client):
    household = _create_household("Paprika import")
    archive = _make_zip(
        {
            "Paprika Recipe One.json.gz": _make_gzip_json(
                {
                    "name": "Paprika Recipe One",
                    "description": "First paprika recipe",
                    "ingredients": [
                        {"name": "Butter", "quantity": "50g"},
                    ],
                }
            ),
            "Paprika Recipe Two.json.gz": _make_gzip_json(
                {
                    "name": "Paprika Recipe Two",
                    "description": "Second paprika recipe",
                    "ingredients": [
                        {"name": "Salt", "quantity": "1 tsp"},
                    ],
                }
            ),
        }
    )

    preview = preview_recipe_import(household.id, archive, "recipes.paprikarecipes")
    assert {recipe["name"] for recipe in preview["recipes"]} == {
        "Paprika Recipe One",
        "Paprika Recipe Two",
    }

    result = commit_recipe_import(
        household.id,
        preview["token"],
        {recipe["import_id"]: "copy" for recipe in preview["recipes"]},
    )
    assert result["imported"] == 2
    assert _get_recipe(household.id, "Paprika Recipe One").description.startswith(
        "First paprika recipe"
    )
    assert _get_recipe(household.id, "Paprika Recipe Two").description.startswith(
        "Second paprika recipe"
    )


def test_recipe_import_overwrite_keeps_existing_tags_without_error(client):
    household = _create_household("Overwrite import")
    _create_recipe_with_tag(household, "Overwrite Me", "Dinner")

    archive = _make_zip(
        {
            "recipe.json": json.dumps(
                {
                    "name": "Overwrite Me",
                    "description": "Updated recipe",
                    "tags": ["Dinner"],
                }
            ).encode("utf-8")
        }
    )

    preview = preview_recipe_import(household.id, archive, "overwrite.zip")
    assert len(preview["duplicates"]) == 1

    result = commit_recipe_import(
        household.id,
        preview["token"],
        {preview["recipes"][0]["import_id"]: "overwrite"},
    )

    assert result["imported"] == 1
    assert result["failed"] == 0

    recipe = _get_recipe(household.id, "Overwrite Me")
    assert recipe.description == "Updated recipe"
    assert [tag.tag.name for tag in recipe.tags] == ["Dinner"]
