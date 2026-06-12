from __future__ import annotations

import io
import json
import gzip
import os
import shutil
import time
import uuid
import zipfile
from typing import Any

import blurhash
import gevent
from sqlalchemy import func
from PIL import Image
from werkzeug.utils import secure_filename

from app.config import UPLOAD_FOLDER, app
from app.models import File
from app.models import Recipe
from app.models.user import User
from app.service.file_has_access_or_download import file_has_access_or_download
from app.service.importServices import importRecipe
from app.service.importRecipes.mealie import parse_mealie_zip
from app.service.importRecipes.tandoor import parse_tandoor_zip
from app.service.importRecipes.json import json_extract_recipes
from app.util.filename_validator import allowed_file
from flask_jwt_extended import current_user


IMPORT_TMP_FOLDER = os.path.join(UPLOAD_FOLDER, "import_tmp")
IMPORT_JOB_STATE: dict[str, dict[str, Any]] = {}


def _store_image_bytes(file_bytes: bytes, filename: str, user=None) -> str | None:
    if not user:
        user = current_user
        if not user:
            return None

    if not filename or not allowed_file(filename):
        return None

    stored_filename = secure_filename(
        str(uuid.uuid4()) + "." + filename.rsplit(".", 1)[1].lower()
    )
    file_path = os.path.join(UPLOAD_FOLDER, stored_filename)
    with open(file_path, "wb") as handle:
        handle.write(file_bytes)
    blur = None
    try:
        with Image.open(file_path) as image:
            image.thumbnail((100, 100))
            blur = blurhash.encode(image, x_components=4, y_components=3)
    except FileNotFoundError:
        return None
    except Exception:
        pass
    File(filename=stored_filename, blur_hash=blur, created_by=user.id).save()
    return stored_filename


def _extract_recipes(payload: Any) -> list[dict[str, Any]]:
    try:
        return json_extract_recipes(payload)
    except Exception:
        return []


def _parse_mealie_zip(
    zf: zipfile.ZipFile, zip_entries: dict[str, str]
) -> list[dict[str, Any]]:
    try:
        return parse_mealie_zip(zf, zip_entries)
    except Exception:
        return []


def _parse_tandoor_zip(
    zf: zipfile.ZipFile,
    entry_names: list[str],
    zip_entries: dict[str, str],
    images_dir: str,
) -> list[dict[str, Any]]:
    try:
        return parse_tandoor_zip(zf, entry_names, zip_entries, images_dir)
    except Exception:
        return []


def _is_gzip_bytes(data: bytes) -> bool:
    return len(data) >= 2 and data[0] == 0x1F and data[1] == 0x8B


def _maybe_decode_json_payload(data: bytes) -> Any | None:
    if _is_gzip_bytes(data):
        try:
            data = gzip.decompress(data)
        except Exception:
            return None
    try:
        return _load_json_bytes(data)
    except Exception:
        return None


def _normalize_zip_path(path: str) -> str:
    return path.replace("\\", "/").strip("/").lower()


def _resolve_photo_from_zip(
    photo_value: str,
    zip_entries: dict[str, str],
    recipe_dir: str,
    recipe_images: dict[str, list[str]],
    zip_file: zipfile.ZipFile,
    images_dir: str,
) -> str | None:
    if not photo_value:
        return None

    photo_key = _normalize_zip_path(photo_value)
    recipe_dir_key = _normalize_zip_path(recipe_dir)
    base_name = os.path.basename(photo_key)
    search_keys = []
    if recipe_dir_key:
        search_keys.append(_normalize_zip_path(f"{recipe_dir}/{photo_key}"))
    search_keys.append(photo_key)
    if recipe_dir_key:
        search_keys.extend(
            _normalize_zip_path(candidate)
            for candidate in recipe_images.get(recipe_dir_key, [])
            if os.path.basename(candidate).lower() == base_name
        )
    search_keys.append(base_name)

    entry_name = None
    for key in search_keys:
        entry_name = zip_entries.get(key)
        if entry_name:
            break

    if not entry_name:
        return None

    try:
        data = zip_file.read(entry_name)
    except Exception:
        return None
    if not allowed_file(entry_name):
        return None
    filename = f"{uuid.uuid4()}_{os.path.basename(entry_name)}"
    path = os.path.join(images_dir, filename)
    with open(path, "wb") as handle:
        handle.write(data)
    return filename


def _collect_zip_images(entries: list[str]) -> dict[str, list[str]]:
    images: dict[str, list[str]] = {}
    for name in entries:
        if allowed_file(name):
            images.setdefault(_normalize_zip_path(os.path.dirname(name)), []).append(
                name
            )
    return images


def _set_import_job(token: str, **state: Any) -> None:
    IMPORT_JOB_STATE[token] = state


def get_recipe_import_job(token: str) -> dict[str, Any] | None:
    job = IMPORT_JOB_STATE.get(token)
    if not job:
        return None
    return dict(job)


def _resolve_photo_candidates_from_zip(
    recipe: dict[str, Any],
    zip_entries: dict[str, str],
    recipe_images: dict[str, list[str]],
    zip_file: zipfile.ZipFile,
    images_dir: str,
) -> tuple[str | None, list[str]]:
    recipe_dir = _normalize_zip_path(recipe.get("import_source_dir", ""))
    folder_images = recipe_images.get(recipe_dir, [])
    main_source = recipe.get("photo", "")
    extra_sources = list(recipe.get("photos", []))

    if not main_source and extra_sources:
        main_source = extra_sources.pop(0)
    if not main_source and folder_images:
        main_source = folder_images[0]

    resolved_main = None
    if main_source:
        resolved_main = _resolve_photo_from_zip(
            main_source,
            zip_entries,
            recipe_dir,
            recipe_images,
            zip_file,
            images_dir,
        )

    resolved_extras: list[str] = []
    candidate_sources = extra_sources + [
        candidate for candidate in folder_images if candidate != main_source
    ]
    for candidate in candidate_sources:
        resolved = _resolve_photo_from_zip(
            candidate,
            zip_entries,
            recipe_dir,
            recipe_images,
            zip_file,
            images_dir,
        )
        if resolved and resolved != resolved_main and resolved not in resolved_extras:
            resolved_extras.append(resolved)

    return resolved_main, resolved_extras


def _load_json_bytes(data: bytes) -> Any:
    return json.loads(data.decode("utf-8"))


def _ensure_tmp_dir(token: str) -> str:
    base = os.path.join(IMPORT_TMP_FOLDER, token)
    os.makedirs(os.path.join(base, "images"), exist_ok=True)
    return base


def _cleanup_old_tmp(max_age_seconds: int = 60 * 60 * 24) -> None:
    if not os.path.isdir(IMPORT_TMP_FOLDER):
        return
    now = time.time()
    for entry in os.scandir(IMPORT_TMP_FOLDER):
        if not entry.is_dir():
            continue
        meta_path = os.path.join(entry.path, "meta.json")
        try:
            with open(meta_path, "r", encoding="utf-8") as handle:
                meta = json.load(handle)
        except Exception:
            meta = {}
        created = float(meta.get("created", 0))
        if created and now - created > max_age_seconds:
            try:
                shutil.rmtree(entry.path)
            except Exception:
                continue


def preview_recipe_import(
    household_id: int,
    data: bytes,
    filename: str,
) -> dict[str, Any]:
    _cleanup_old_tmp()
    token = uuid.uuid4().hex
    base_dir = _ensure_tmp_dir(token)
    images_dir = os.path.join(base_dir, "images")

    recipes: list[dict[str, Any]] = []
    if filename.lower().endswith(".zip") or filename.lower().endswith(
        ".paprikarecipes"
    ):
        with zipfile.ZipFile(io.BytesIO(data)) as zf:
            entries = [
                name
                for name in zf.namelist()
                if not name.endswith("/") and not name.lower().startswith("__macosx/")
            ]
            zip_entries = {name.lower().replace("\\", "/"): name for name in entries}
            zip_entries.update(
                {
                    os.path.basename(name).lower(): name
                    for name in entries
                    if os.path.basename(name)
                }
            )
            recipe_images = _collect_zip_images(entries)
            # Detect Mealie export (database.json at root)
            if "database.json" in zip_entries:
                mrecipes = _parse_mealie_zip(zf, zip_entries)
                for recipe in mrecipes:
                    recipe["import_source_dir"] = ""
                    recipes.append(recipe)
            else:
                # Detect Tandoor export: root-level entries are ZIP files
                root_entries = [name for name in entries if os.path.dirname(name) == ""]
                if root_entries and all(
                    name.lower().endswith(".zip") for name in root_entries
                ):
                    trecipes = _parse_tandoor_zip(zf, entries, zip_entries, images_dir)
                    for recipe in trecipes:
                        recipe["import_source_dir"] = ""
                        recipes.append(recipe)
                else:
                    json_entries = [
                        name for name in entries if name.lower().endswith(".json")
                    ]
                    for json_name in json_entries:
                        payload = _maybe_decode_json_payload(zf.read(json_name))
                        if payload is None:
                            continue
                        recipe_dir = _normalize_zip_path(os.path.dirname(json_name))
                        for recipe in _extract_recipes(payload):
                            recipe["import_source_dir"] = recipe_dir
                            recipes.append(recipe)

                    for entry_name in entries:
                        if entry_name.lower().endswith(".json"):
                            continue
                        payload = _maybe_decode_json_payload(zf.read(entry_name))
                        if payload is None:
                            continue
                        recipe_dir = _normalize_zip_path(os.path.dirname(entry_name))
                        for recipe in _extract_recipes(payload):
                            recipe["import_source_dir"] = recipe_dir
                            recipes.append(recipe)

            for recipe in recipes:
                photo_value = recipe.get("photo", "")
                if photo_value.startswith("http"):
                    continue
                resolved_main, resolved_extras = _resolve_photo_candidates_from_zip(
                    recipe,
                    zip_entries,
                    recipe_images,
                    zf,
                    images_dir,
                )
                if resolved_main:
                    recipe["photo_temp"] = resolved_main
                    recipe.pop("photo", None)
                if resolved_extras:
                    recipe["photo_temps"] = resolved_extras
                    recipe.pop("photos", None)
    else:
        payload = _load_json_bytes(data)
        recipes = _extract_recipes(payload)
        for recipe in recipes:
            photo_value = recipe.get("photo", "")
            if photo_value and not photo_value.startswith("http"):
                recipe.pop("photo", None)

    for recipe in recipes:
        recipe["import_id"] = uuid.uuid4().hex
        recipe.pop("import_source_dir", None)

    duplicates: list[dict[str, Any]] = []
    for recipe in recipes:
        name = recipe.get("name", "")
        if not name:
            continue
        existing = Recipe.query.filter(
            Recipe.household_id == household_id,
            func.lower(Recipe.name) == name.lower(),
        ).first()
        if existing:
            duplicates.append(
                {
                    "import_id": recipe["import_id"],
                    "recipe_id": existing.id,
                    "recipe_name": existing.name,
                }
            )

    with open(os.path.join(base_dir, "recipes.json"), "w", encoding="utf-8") as f:
        json.dump(recipes, f, ensure_ascii=False)
    with open(os.path.join(base_dir, "meta.json"), "w", encoding="utf-8") as f:
        json.dump({"created": time.time()}, f)

    return {
        "token": token,
        "recipes": [
            {
                "import_id": r["import_id"],
                "name": r.get("name", ""),
                "source": r.get("source", ""),
            }
            for r in recipes
        ],
        "duplicates": duplicates,
    }


def commit_recipe_import(
    household_id: int,
    token: str,
    decisions: dict[str, str],
) -> dict[str, Any]:
    if token in IMPORT_JOB_STATE and not IMPORT_JOB_STATE[token].get("complete"):
        return get_recipe_import_job(token) or {
            "imported": 0,
            "skipped": 0,
            "failed": 0,
            "complete": False,
        }

    user = User.find_by_id(current_user.id) if current_user else None
    _set_import_job(
        token,
        detected=0,
        imported=0,
        skipped=0,
        failed=0,
        complete=False,
        running=True,
    )

    if app.testing:
        _run_recipe_import_job(household_id, token, decisions, user)
    else:
        gevent.spawn(_run_recipe_import_job, household_id, token, decisions, user)

    return get_recipe_import_job(token) or {
        "detected": 0,
        "imported": 0,
        "skipped": 0,
        "failed": 0,
        "complete": False,
    }


def _run_recipe_import_job(
    household_id: int,
    token: str,
    decisions: dict[str, str],
    user,
) -> None:
    with app.app_context():
        base_dir = os.path.join(IMPORT_TMP_FOLDER, token)
        recipes_path = os.path.join(base_dir, "recipes.json")
        images_dir = os.path.join(base_dir, "images")
        if not os.path.exists(recipes_path):
            _set_import_job(token, imported=0, skipped=0, failed=0, complete=True)
            return

        with open(recipes_path, "r", encoding="utf-8") as f:
            recipes = json.load(f)

        _set_import_job(
            token,
            detected=len(recipes),
            imported=0,
            skipped=0,
            failed=0,
            complete=False,
            running=True,
        )

        imported = 0
        skipped = 0
        failed = 0
        for recipe in recipes:
            import_id = recipe.get("import_id")
            action = decisions.get(import_id, "copy")
            if action == "skip":
                skipped += 1
                continue

            try:
                if recipe.get("photo_temp"):
                    image_path = os.path.join(images_dir, recipe["photo_temp"])
                    with open(image_path, "rb") as handle:
                        file_bytes = handle.read()
                    filename = _store_image_bytes(
                        file_bytes, recipe["photo_temp"], user
                    )
                    if filename:
                        recipe["photo"] = filename
                if recipe.get("photo_temps"):
                    resolved_photos = []
                    for photo_temp in recipe["photo_temps"]:
                        image_path = os.path.join(images_dir, photo_temp)
                        with open(image_path, "rb") as handle:
                            file_bytes = handle.read()
                        filename = _store_image_bytes(file_bytes, photo_temp, user)
                        if filename:
                            resolved_photos.append(filename)
                    if resolved_photos:
                        recipe["photos"] = resolved_photos
                elif recipe.get("photo"):
                    recipe["photo"] = file_has_access_or_download(
                        recipe["photo"], user=user
                    )
                elif recipe.get("photo") is None:
                    recipe.pop("photo", None)

                importRecipe(
                    household_id,
                    recipe,
                    overwrite=action == "overwrite",
                    user=user,
                )
                imported += 1
            except Exception:
                app.logger.exception("Failed to import recipe")
                failed += 1
            _set_import_job(
                token,
                detected=len(recipes),
                imported=imported,
                skipped=skipped,
                failed=failed,
                complete=False,
                running=True,
            )

        try:
            shutil.rmtree(base_dir)
        except Exception:
            app.logger.warning("Failed to cleanup recipe import temp dir")

        _set_import_job(
            token,
            detected=len(recipes),
            imported=imported,
            skipped=skipped,
            failed=failed,
            complete=True,
            running=False,
        )
