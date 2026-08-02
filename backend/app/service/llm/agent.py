"""Recipe-agent loop: turns a user message into assistant + tool messages."""

from __future__ import annotations

import base64
import io
import json
import logging
import mimetypes
import os
import re
from datetime import UTC, datetime
from typing import Any

from app import db
from app.config import AGENT_MAX_FILE_SIZE, AGENT_MAX_FILES_PER_MESSAGE, UPLOAD_FOLDER
from app.errors import InvalidUsage
from app.models import (
    CARD_SOURCE_CREATED,
    AgentChat,
    AgentMessage,
    AgentMessageRole,
    AgentRecipeCard,
    File,
    LLMConfig,
)
from app.models.agent_persona import AgentPersona
from app.service.agent_tools import get_agent_tools
from app.service.agent_undo import (
    build_ops_from_result,
    capture_before,
    is_mutating,
    serialise_ops,
)
from app.service.llm.provider import LLMError, LLMProvider, get_provider

_logger = logging.getLogger(__name__)

# Safety net: number of model<->tool round-trips per user turn.
MAX_TOOL_ITERATIONS = 6

# Regex used to detect whether the model already appended the mandatory
# `[suggestions: ...]` marker. We accept any non-empty bracket content with
# the right header so the server-side fallback only kicks in when the model
# truly forgot.
_SUGGESTIONS_RE = re.compile(r"\[suggestions:\s*[^\]\n]+\]\s*$", re.IGNORECASE)

# Fallback marker appended when the model omits suggestions on a final
# user-facing reply. The frontend strips the marker before rendering, so
# users only ever see the chips themselves.
_FALLBACK_SUGGESTIONS = "[suggestions: Ja | Nein | Anderes Rezept]"
_PDF_TEXT_CHAR_LIMIT = 12000


def _ensure_suggestions(text: str | None) -> str:
    """Guarantee that user-facing assistant text ends with a suggestions
    marker. Empty content stays empty (those are pure tool-call turns).
    """
    if not text:
        return text or ""
    stripped = text.rstrip()
    if _SUGGESTIONS_RE.search(stripped):
        return text
    sep = "\n\n" if stripped else ""
    return f"{stripped}{sep}{_FALLBACK_SUGGESTIONS}"


DEFAULT_SYSTEM_PROMPT = (
    "You are KitchenOwl's recipe agent. You help the user decide what to "
    "cook, find matching recipes in their KitchenOwl household, and create "
    "new ones when nothing suitable exists yet.\n\n"
    "Context you already have:\n"
    "- The household is fixed by the chat context and resolved by the "
    "system automatically. NEVER ask the user for a household, household "
    "ID or household name, and never mention IDs in user-facing messages. "
    "Tools do not expose a household_id parameter — just call them with "
    "the other arguments and the correct household is used.\n\n"
    "Conversation guidelines:\n"
    "- Reply in the language the user is using.\n"
    "- If the user is vague (e.g. 'what should I eat tonight', 'give me "
    "suggestions'), ask ONE short clarifying question about their mood / "
    "cravings / constraints (e.g. quick vs. elaborate, vegetarian, "
    "ingredients on hand, cuisine). Do not ask several questions at once.\n"
    "- ALWAYS search the household's existing recipes FIRST before "
    "proposing or creating anything new. Call search_recipes with relevant "
    "keywords (ingredients, cuisine, dish name, dietary needs). If "
    "search_recipes returns nothing useful, fall back to list_recipes.\n"
    "- If one or more existing recipes match, present them by NAME (with a "
    "short summary) and ask which one fits. Do NOT call create_recipe in "
    "this case and do not show internal IDs to the user. When the user "
    "picks an existing recipe, ask whether you should add it to the right-"
    "side recipe ideas panel; if they confirm, call attach_recipe_card for "
    "that recipe.\n"
    "- If NO existing recipe matches, do NOT stop there and do NOT ask the "
    "user whether they want something new — proactively propose 1-3 new "
    "concrete recipe options yourself, each with a short description, "
    "approximate time and key ingredients, and ask which one sounds good. "
    "This brief inspiration list is NOT a recipe proposal and you MUST "
    "NOT call create_recipe based on it. As soon as the user picks one of "
    "the suggestions (or has from the start asked for a recipe for a "
    "specific dish), continue with the propose-then-confirm flow below: "
    "first compose and show the FULL structured recipe in chat, then ask "
    "for explicit confirmation, and only THEN call create_recipe.\n"
    "- You may call web_search_recipes to look up real recipes on the "
    "internet (returns title/url/snippet hits). Use it when the user asks "
    "for inspiration from the web, mentions a specific dish you don't "
    "know well, or wants an authentic source. Briefly mention the source "
    "(site or chef) when proposing a web-found recipe. To import one, "
    "call scrape_recipe with its url; if scraping succeeds, present the "
    "result and confirm before calling create_recipe with the scraped "
    "data (set source to the original url).\n"
    "- As soon as the basics are clear (which dish + any explicit "
    "constraints like servings or dietary needs the user already gave), "
    "compose the COMPLETE recipe yourself and present it in chat FIRST. "
    "Do NOT call create_recipe yet. ALWAYS estimate yields (servings), "
    "prep_time and cook_time yourself based on the dish — never ask the "
    "user for these values. Use sensible defaults (e.g. yields=2-4 for "
    "a main course) if unsure. The proposal you show in chat must "
    "include ALL of: name, yields, prep_time, cook_time, the full "
    "structured ingredient list with amounts/units, the tags, and the "
    "full step-by-step description (newlines between steps) using the "
    "ingredient-pill syntax described below. Format the proposal so the "
    "user can review every detail before saving.\n"
    "- After showing the proposal, EXPLICITLY ask the user to confirm "
    "creation (in the reply language, e.g. 'Soll ich das Rezept so "
    "anlegen?' / 'Shall I save this recipe?'). Only call create_recipe "
    "once the user clearly confirms ('ja', 'erstelle', 'passt', 'yes', "
    "'save it', 'go ahead', etc.). When you do call create_recipe, the "
    "single call must contain EXACTLY the proposal you just showed — "
    "same name, items, description, tags, yields and times. Never split "
    "the recipe across multiple create_recipe calls and never create a "
    "stub. If the user requests changes, show an updated FULL proposal "
    "and ask for confirmation again — never save a half-revised recipe. "
    "Only AFTER create_recipe succeeds, briefly tell the user the "
    "recipe has been saved and offer further tweaks if they want. The "
    "same propose-then-confirm rule applies to scrape_recipe imports: "
    "show the scraped result in full, confirm, then call create_recipe "
    "with source set to the original url.\n"
    "- Never invent KitchenOwl IDs. Use list_items / list_tags first if "
    "you need them, but do not surface those IDs to the user.\n"
    "- Ingredient names MUST be spelled correctly and follow the "
    "capitalisation rules of the reply language. In German, ALL nouns "
    "(including ingredient names) are always capitalised "
    "(e.g. 'Limettensaft', not 'limettensaft'; 'Knoblauch', not "
    "'knoblauch'). In English, use standard title-case for ingredient "
    "names (e.g. 'Lemon Juice', 'Garlic'). Never produce ingredient "
    "names in all-lowercase. Use the singular form for the item name "
    "and put quantity/unit information only in the description field.\n"
    "- Consolidate ingredients: if the same base ingredient appears in "
    "several states or preparations (e.g. coriander used both ground "
    "and fresh, butter used both melted and cold), produce ONE items "
    "entry whose name is the base ingredient (e.g. 'Koriander', "
    "'Butter') and whose description lists every variant comma-"
    "separated with its amount and state (e.g. description='0,5 TL "
    "gemahlen, 0,5 Bund frisch' or '50 g geschmolzen, 30 g kalt'). Do "
    "NOT emit two separate items like 'Koriander frisch' and "
    "'Koriander gemahlen'.\n"
    "- In the recipe description, ALWAYS reference ingredients with "
    "KitchenOwl's ingredient-pill markdown so each step shows the "
    "correct amount inline. Syntax: '@Ingredient_Name' for the default "
    "amount, or '@Ingredient_Name{amount for this step}' to override "
    "the amount for that occurrence. Use underscores for spaces in the "
    "name (e.g. '@Olivenöl', '@Koriander', '@Frischer_Spinat').\n"
    "- The @-pill name MUST be EXACTLY the ingredient's base name as "
    "declared in the items list — character for character, including "
    "capitalisation. NEVER add grammatical suffixes (German plural/case "
    "endings like -s, -e, -en, -er, -n, -es, English plural -s, etc.) "
    "and never inflect, abbreviate or translate the name. Always write "
    "the bare singular base form, even when the surrounding sentence "
    "would grammatically require an inflected form. Examples — correct: "
    "'Den @Lachsfilet trocken tupfen', 'Die @Zwiebel anbraten', 'Add "
    "the @Tomato to the pan'. WRONG: '@Lachsfilets', '@Zwiebeln', "
    "'@Tomatoes'. If the sentence reads awkwardly, rephrase the "
    "surrounding words — never the @-pill itself.\n"
    "- For any ingredient that was consolidated into multiple variants, "
    "you MUST use the override form in EVERY step so the user sees the "
    "exact sub-amount needed at that point — e.g. when toasting use "
    "'@Koriander{0,5 TL gemahlen}', and when garnishing later use "
    "'@Koriander{0,5 Bund frisch}'. More generally, whenever a step "
    "uses only part of an ingredient's total amount, reference it with "
    "the explicit per-step amount in curly braces (e.g. "
    "'@Olivenöl{1 EL}' in a 3 EL recipe). Never write a step that "
    "mentions an ingredient by plain text without the @-pill.\n"
    "- Be concise and friendly. Avoid filler words.\n"
    "\n"
    "OUTPUT CONTRACT (mandatory, no exceptions):\n"
    "- EVERY assistant reply that is shown to the user MUST end with a "
    "suggestions marker on its own at the very end of the message in the "
    "exact form: `[suggestions: option one | option two | option three]`. "
    "This applies to clarifying questions, recipe proposals, confirmations, "
    "error notes — every single user-facing reply.\n"
    "- Provide 2-4 short (max ~4 words each), context-appropriate options "
    "in the user's language. They must be plausible next replies the user "
    "could send verbatim, NOT meta-commands.\n"
    "  * After a clarifying question: offer concrete answers (e.g. "
    "`[suggestions: Schnell, unter 30 Min | Vegetarisch | Mit Resten]`).\n"
    "  * After listing existing recipes: offer the recipe NAMES plus an "
    "alternative (e.g. `[suggestions: Spaghetti Carbonara | Linsensuppe | "
    "Etwas anderes]`).\n"
    "  * After proposing 1-3 new ideas: offer each idea's short name plus "
    "`Andere Idee` (e.g. `[suggestions: Kürbissuppe | Gnocchi-Pfanne | "
    "Andere Idee]`).\n"
    "  * After showing the FULL recipe proposal awaiting confirmation: "
    "`[suggestions: Ja, so anlegen | Mehr Portionen | Anders würzen]` "
    "(or the English equivalents).\n"
    "  * After successfully creating/updating/deleting a recipe: offer "
    "natural follow-ups (e.g. `[suggestions: Beilage vorschlagen | "
    "Weiteres Rezept | Danke, das war's]`).\n"
    "- The marker must appear on the SAME message, after any normal text, "
    "in plain text (no code fence, no quotes around the brackets). Do NOT "
    "emit the marker in messages that only contain tool calls and no user-"
    "visible content.\n"
)


def _serialise_tool_calls(tool_calls: list[dict[str, Any]]) -> str | None:
    if not tool_calls:
        return None
    return json.dumps(tool_calls, ensure_ascii=False)


def _deserialise_tool_calls(value: str | None) -> list[dict[str, Any]]:
    if not value:
        return []
    try:
        data = json.loads(value)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def _normalise_attached_files(
    attached_file_ids: list[str] | None,
) -> list[dict[str, Any]]:
    ids = [str(fid).strip() for fid in (attached_file_ids or []) if str(fid).strip()]

    # De-duplicate while preserving order before enforcing the per-message limit
    # so that duplicate IDs in the request don't incorrectly trigger the cap.
    deduped_ids = list(dict.fromkeys(ids))
    if len(deduped_ids) > AGENT_MAX_FILES_PER_MESSAGE:
        raise InvalidUsage(
            f"A maximum of {AGENT_MAX_FILES_PER_MESSAGE} files can be attached per message"
        )
    files: list[dict[str, Any]] = []
    errors: list[str] = []
    for file_id in deduped_ids:
        f = File.find(file_id)
        if not f:
            errors.append(f"{file_id}: not found")
            continue
        f.checkAuthorized()

        path = os.path.join(UPLOAD_FOLDER, f.filename)
        if not os.path.exists(path):
            errors.append(f"{file_id}: missing on disk")
            continue

        size = os.path.getsize(path)
        if size > AGENT_MAX_FILE_SIZE:
            errors.append(
                f"{file_id}: exceeds maximum size ({size} > {AGENT_MAX_FILE_SIZE} bytes)"
            )
            continue

        mime_type = (
            mimetypes.guess_type(f.filename)[0] or "application/octet-stream"
        ).lower()
        if not (mime_type.startswith("image/") or mime_type == "application/pdf"):
            errors.append(
                f"{file_id}: unsupported type '{mime_type}' (only image/* and application/pdf)"
            )
            continue

        created_at = getattr(f, "created_at", None)
        # Match the rest of the API: serialize as UTC milliseconds since
        # epoch so the Flutter client (and ``KitchenOwlJSONProvider``)
        # treat the value consistently as a tz-aware instant.
        if created_at is not None and created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=UTC)
        files.append(
            {
                "id": f.filename,
                "filename": f.filename,
                "mime_type": mime_type,
                "size": size,
                "uploaded_at": int(round(created_at.timestamp() * 1000))
                if created_at
                else None,
            }
        )

    if errors:
        raise InvalidUsage("Invalid attached files: " + "; ".join(errors))

    return files


def _read_attached_file_bytes(file_id: str) -> bytes:
    path = os.path.join(UPLOAD_FOLDER, file_id)
    try:
        with open(path, "rb") as fh:
            return fh.read()
    except OSError as exc:
        raise InvalidUsage(f"Failed to read attached file '{file_id}'") from exc


def _extract_pdf_text(file_bytes: bytes) -> str:
    try:
        from pypdf import PdfReader
    except Exception:
        return ""

    try:
        reader = PdfReader(io.BytesIO(file_bytes), strict=False)
    except Exception:
        return ""

    chunks: list[str] = []
    chars = 0
    for page in reader.pages[:20]:
        try:
            text = (page.extract_text() or "").strip()
        except Exception:
            continue
        if not text:
            continue
        remaining = _PDF_TEXT_CHAR_LIMIT - chars
        if remaining <= 0:
            break
        clipped = text[:remaining]
        chunks.append(clipped)
        chars += len(clipped)

    return "\n\n".join(chunks)


def _decode_attachments(msg: AgentMessage) -> dict[str, Any]:
    if not msg.attachments_json:
        return {}
    try:
        data = json.loads(msg.attachments_json)
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}


def _build_attachment_hints(data: dict[str, Any]) -> list[str]:
    recipe_ids = data.get("recipe_ids") or []
    item_ids = data.get("item_ids") or []
    hints: list[str] = []
    if recipe_ids:
        hints.append(
            "Attached recipes (look them up via get_recipe if you need details): "
            + ", ".join(str(i) for i in recipe_ids)
        )
    if item_ids:
        hints.append(
            "Attached pantry/shopping items (item ids): "
            + ", ".join(str(i) for i in item_ids)
        )
    return hints


def _build_user_content(msg: AgentMessage) -> str | list[dict[str, Any]]:
    content = msg.content or ""
    data = _decode_attachments(msg)
    hints = _build_attachment_hints(data)

    files = data.get("files") or []
    if not isinstance(files, list) or not files:
        if hints:
            return content + "\n\n[Attached context]\n" + "\n".join(hints)
        return content

    parts: list[dict[str, Any]] = []
    if content:
        parts.append({"type": "text", "text": content})

    for file_meta in files:
        if not isinstance(file_meta, dict):
            continue
        file_id = str(file_meta.get("id") or "").strip()
        mime_type = str(file_meta.get("mime_type") or "").strip().lower()
        display_name = str(file_meta.get("filename") or file_id or "attachment")
        if not file_id:
            continue

        file_bytes = _read_attached_file_bytes(file_id)
        if mime_type.startswith("image/"):
            encoded = base64.b64encode(file_bytes).decode("ascii")
            parts.append(
                {
                    "type": "image_url",
                    "image_url": {"url": f"data:{mime_type};base64,{encoded}"},
                }
            )
            continue

        if mime_type == "application/pdf":
            text = _extract_pdf_text(file_bytes)
            if text:
                parts.append(
                    {
                        "type": "text",
                        "text": f"[PDF attachment: {display_name}]\n{text}",
                    }
                )
            else:
                parts.append(
                    {
                        "type": "text",
                        "text": (
                            f"[PDF attachment: {display_name}]\n"
                            "Could not extract text from this PDF."
                        ),
                    }
                )

    if hints:
        parts.append(
            {"type": "text", "text": "[Attached context]\n" + "\n".join(hints)}
        )

    return parts if parts else content


def _message_to_openai(msg: AgentMessage) -> dict[str, Any]:
    """Convert a stored :class:`AgentMessage` to the OpenAI message format."""
    role = msg.role.value
    out: dict[str, Any] = {"role": role}

    if role == "tool":
        out["content"] = msg.content or ""
        if msg.tool_call_id:
            out["tool_call_id"] = msg.tool_call_id
        if msg.tool_name:
            out["name"] = msg.tool_name
        return out

    if role == "assistant":
        # Assistant content may be empty when only tool calls are returned.
        out["content"] = msg.content or ""
        tool_calls = _deserialise_tool_calls(msg.tool_calls)
        if tool_calls:
            out["tool_calls"] = tool_calls
        return out

    out["content"] = _build_user_content(msg)
    return out


def _build_message_history(chat: AgentChat, system_prompt: str) -> list[dict[str, Any]]:
    history: list[dict[str, Any]] = [{"role": "system", "content": system_prompt}]
    for msg in chat.messages:
        # Skip any persisted system messages -- the live system prompt wins.
        if msg.role == AgentMessageRole.SYSTEM:
            continue
        history.append(_message_to_openai(msg))
    return history


def _truncate_for_title(text: str, limit: int) -> str:
    """Return a single-line, length-capped version of ``text`` for use as a
    fallback chat title.
    """
    cleaned = " ".join((text or "").split())
    if len(cleaned) <= limit:
        return cleaned
    # Reserve one slot for the ellipsis so the result honours ``limit``.
    return cleaned[: max(limit - 1, 0)].rstrip() + "…"


def _strip_household_id(input_schema: dict[str, Any]) -> dict[str, Any]:
    """Return a copy of ``input_schema`` with ``household_id`` removed.

    The agent is bound to a single household and the runtime auto-injects
    the correct ``household_id`` into every tool call (see
    :meth:`RecipeAgent._execute_tool_calls`). Exposing the parameter to the
    LLM only causes confusion: models routinely ask the user for a
    household ID instead of just calling the tool.
    """
    if not isinstance(input_schema, dict):
        return input_schema
    cleaned = dict(input_schema)
    props = cleaned.get("properties")
    if isinstance(props, dict) and "household_id" in props:
        new_props = {k: v for k, v in props.items() if k != "household_id"}
        cleaned["properties"] = new_props
    required = cleaned.get("required")
    if isinstance(required, list) and "household_id" in required:
        cleaned["required"] = [r for r in required if r != "household_id"]
    return cleaned


def _build_tools_schema() -> list[dict[str, Any]]:
    schema: list[dict[str, Any]] = []
    for name, (input_schema, _) in get_agent_tools().items():
        schema.append(
            {
                "type": "function",
                "function": {
                    "name": name,
                    "description": f"KitchenOwl tool: {name}",
                    "parameters": _strip_household_id(input_schema),
                },
            }
        )
    return schema


def _parse_arguments(raw: Any) -> dict[str, Any]:
    if raw is None or raw == "":
        return {}
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise InvalidUsage(f"LLM returned invalid JSON arguments: {exc}")
        if not isinstance(data, dict):
            raise InvalidUsage("LLM tool arguments must be a JSON object")
        return data
    raise InvalidUsage("Unsupported tool arguments type")


class RecipeAgent:
    """Stateful agent runner bound to a single chat."""

    def __init__(
        self,
        config: LLMConfig,
        chat: AgentChat,
        provider: LLMProvider | None = None,
        persona: AgentPersona | None = None,
    ):
        if not config.is_ready():
            raise InvalidUsage(
                "LLM agent is not configured. Set provider, model and API key first."
            )
        if chat.household_id != config.household_id:
            raise InvalidUsage("Chat does not belong to this household")
        self.config = config
        self.chat = chat
        # Resolve persona: prefer the explicit argument, then the chat's
        # stored persona. ``None`` means "use household defaults".
        self.persona = persona if persona is not None else chat.persona
        self.provider = provider or get_provider(config)
        # The DEFAULT_SYSTEM_PROMPT contains the recipe-formatting protocol
        # (ingredient @-pills, propose-then-confirm flow, capitalisation,
        # consolidation rules, ...). Persona and household-level prompts may
        # only ADD flavour on top — they must never override the formatting
        # rules, otherwise the recipes that get saved to KitchenOwl break.
        persona_prompt = (
            (self.persona.system_prompt if self.persona else None) or ""
        ).strip()
        config_prompt = (config.system_prompt or "").strip()
        extras: list[str] = []
        if persona_prompt:
            persona_name = (self.persona.name or "").strip() if self.persona else ""
            label = f"Persona ({persona_name})" if persona_name else "Persona"
            extras.append(f"{label} guidance:\n{persona_prompt}")
        if config_prompt:
            extras.append(f"Household preferences:\n{config_prompt}")
        if extras:
            self.system_prompt = (
                DEFAULT_SYSTEM_PROMPT
                + "\nAdditional guidance (must NOT override the formatting "
                "and recipe-creation rules above):\n" + "\n\n".join(extras)
            )
        else:
            self.system_prompt = DEFAULT_SYSTEM_PROMPT
        # Persona temperature wins over the household default when set.
        if self.persona is not None and self.persona.temperature is not None:
            self.temperature_override: float | None = self.persona.temperature
        else:
            self.temperature_override = None

    # ------------------------------------------------------------------ public

    def send_user_message(
        self,
        content: str,
        attached_recipe_ids: list[int] | None = None,
        attached_item_ids: list[int] | None = None,
        attached_file_ids: list[str] | None = None,
    ) -> list[AgentMessage]:
        """Append the user message, run the loop, return the new messages."""
        if any(message.requires_confirmation for message in self.chat.messages):
            raise InvalidUsage("Confirm or rewind the pending tool call first")
        content = (content or "").strip()
        attachments_payload: dict[str, Any] | None = None
        recipe_ids = [int(i) for i in (attached_recipe_ids or []) if isinstance(i, int)]
        item_ids = [int(i) for i in (attached_item_ids or []) if isinstance(i, int)]
        file_attachments = _normalise_attached_files(attached_file_ids)
        if not content and not recipe_ids and not item_ids and not file_attachments:
            raise InvalidUsage("Message must not be empty")

        prior_user_count = sum(
            1 for m in self.chat.messages if m.role == AgentMessageRole.USER
        )

        if recipe_ids or item_ids or file_attachments:
            attachments_payload = {
                "recipe_ids": recipe_ids,
                "item_ids": item_ids,
                "files": file_attachments,
            }

        user_msg = AgentMessage(
            chat=self.chat,
            role=AgentMessageRole.USER,
            content=content,
            attachments_json=(
                json.dumps(attachments_payload, ensure_ascii=False)
                if attachments_payload
                else None
            ),
        )
        db.session.add(user_msg)
        # Persist the user message before kicking off potentially long-running
        # provider/tool work. This way, if a tool handler later raises and we
        # ``rollback()`` to clear its half-applied state, the user message
        # (and any in-progress assistant/tool messages we already committed)
        # are not lost.
        db.session.commit()

        new_messages: list[AgentMessage] = [user_msg]
        new_messages.extend(self._run_loop())

        if not any(message.requires_confirmation for message in new_messages):
            self._maybe_auto_title(content, prior_user_count)

        self.chat.updated_at = datetime.now(UTC)
        db.session.commit()
        return new_messages

    def replay_loop(self) -> list[AgentMessage]:
        """Re-run the agent loop on the existing chat history.

        Used by the ``regenerate`` and edited-message flows: the caller has
        already truncated the chat (and undone any tool side effects) so
        the last persisted message is the user turn we want to answer
        again. No new user message is appended.
        """
        new_messages = self._run_loop()
        self.chat.updated_at = datetime.now(UTC)
        db.session.commit()
        return new_messages

    def confirm_tool_batch(self, pending_message: AgentMessage) -> list[AgentMessage]:
        """Execute the exact tool-call batch associated with a pending message."""
        assistant = next(
            (
                message
                for message in reversed(self.chat.messages)
                if message.id < pending_message.id
                and message.role == AgentMessageRole.ASSISTANT
                and message.tool_calls
            ),
            None,
        )
        if assistant is None:
            raise InvalidUsage("Pending tool call has no assistant request")
        tool_calls = _deserialise_tool_calls(assistant.tool_calls)
        pending = [
            message
            for message in self.chat.messages
            if message.role == AgentMessageRole.TOOL
            and message.requires_confirmation
            and any(call.get("id") == message.tool_call_id for call in tool_calls)
        ]
        if not pending:
            raise InvalidUsage("Tool call is no longer pending confirmation")
        for message in pending:
            db.session.delete(message)
        db.session.commit()

        produced = self._execute_tool_calls(tool_calls, confirmed=True)
        db.session.commit()
        produced.extend(self._run_loop())
        self.chat.updated_at = datetime.now(UTC)
        db.session.commit()
        return produced

    # --------------------------------------------------------------- titling

    def _maybe_auto_title(
        self, latest_user_content: str, prior_user_count: int
    ) -> None:
        """Hybrid auto-rename.

        * 1st user message: set ``title`` to a truncated version of the
          message immediately so the chat list stops showing the placeholder.
        * 2nd+ user message: ask the LLM for a short, descriptive title
          and replace the truncate-fallback. Skipped if the user has
          already locked the title via a manual rename.
        """
        if self.chat.title_locked:
            return

        if prior_user_count == 0 and not self.chat.title:
            # Fast path: instant truncate so the UI updates without an
            # extra round-trip. Marked ``title_auto`` so the LLM rename
            # below is allowed to overwrite it later.
            self.chat.title = _truncate_for_title(latest_user_content, 50)
            self.chat.title_auto = True
            return

        # Refine via LLM as soon as we have at least 2 user turns and the
        # title still looks auto-generated. Errors are swallowed by
        # ``generate_chat_title`` so a flaky provider never fails the
        # user's actual chat call.
        if prior_user_count >= 1 and self.chat.title_auto:
            from app.service.llm.title import generate_chat_title

            new_title = generate_chat_title(self.config, self.chat, self.persona)
            if new_title:
                self.chat.title = new_title
                self.chat.title_auto = False

    # ------------------------------------------------------------------ loop

    def _build_runtime_addendum(self) -> str:
        """Build a system-prompt addendum reflecting current chat state
        (open recipe cards). Recomputed each turn so closing a card removes
        it from the model's context.
        """
        parts: list[str] = []
        cards = AgentRecipeCard.find_open_for_chat(self.chat.id)
        if cards:
            lines = []
            for c in cards:
                desc = (c.description or "").strip().replace("\n", " ")
                if len(desc) > 200:
                    desc = desc[:197] + "\u2026"
                ref = f"recipe_id={c.recipe_id}" if c.recipe_id else "draft"
                lines.append(
                    f"- [{c.source}] {c.title} ({ref})"
                    + (f" \u2014 {desc}" if desc else "")
                )
            parts.append(
                "Recipe cards currently visible to the user on the right "
                "side of the chat. Treat these as the active short-list: "
                "prefer building on them, do NOT re-propose the same recipes, "
                "and do not refer back to recipes the user has already closed "
                "(they are not in this list).\n" + "\n".join(lines)
            )
        return "\n\n".join(parts)

    def _run_loop(self) -> list[AgentMessage]:
        produced: list[AgentMessage] = []
        tools = _build_tools_schema()

        for iteration in range(MAX_TOOL_ITERATIONS):
            addendum = self._build_runtime_addendum()
            sys_prompt = (
                self.system_prompt + "\n\n" + addendum
                if addendum
                else self.system_prompt
            )
            messages = _build_message_history(self.chat, sys_prompt)
            # Building the message history above issues SELECTs which open
            # an implicit transaction on the session's DB connection. The
            # provider call below can block for tens of seconds waiting on
            # the LLM; on SQLite that open read-transaction blocks every
            # other writer (e.g. JWT ``last_seen`` updates) and cascades
            # into "database is locked" errors across the whole app.
            # Commit here to release the transaction before waiting on
            # network I/O. The next ORM access transparently begins a new
            # one.
            db.session.commit()
            try:
                response = self.provider.chat(
                    messages, tools=tools, temperature=self.temperature_override
                )
            except LLMError:
                # Surface a friendly assistant message rather than raising
                # so the user sees what went wrong in the chat itself.
                err_msg = AgentMessage(
                    chat=self.chat,
                    role=AgentMessageRole.ASSISTANT,
                    content="⚠️ The LLM provider request failed. Please try again.",
                )
                db.session.add(err_msg)
                db.session.flush()
                produced.append(err_msg)
                return produced

            assistant_msg = AgentMessage(
                chat=self.chat,
                role=AgentMessageRole.ASSISTANT,
                content=(
                    response.content
                    if response.tool_calls
                    else _ensure_suggestions(response.content)
                ),
                tool_calls=_serialise_tool_calls(response.tool_calls),
            )
            db.session.add(assistant_msg)
            db.session.flush()
            produced.append(assistant_msg)

            if not response.tool_calls:
                return produced

            # Persist the assistant turn before running tools so a tool
            # failure (which forces a session rollback to undo half-applied
            # ORM state) cannot also discard prior chat history.
            db.session.commit()

            tool_messages = self._execute_tool_calls(response.tool_calls)
            produced.extend(tool_messages)
            if any(message.requires_confirmation for message in tool_messages):
                return produced

        # Iteration cap reached -- tell the user and stop.
        timeout_msg = AgentMessage(
            chat=self.chat,
            role=AgentMessageRole.ASSISTANT,
            content=(
                "⚠️ I made too many tool calls in a row without finishing my "
                "answer. Please rephrase your request."
            ),
        )
        db.session.add(timeout_msg)
        db.session.flush()
        produced.append(timeout_msg)
        return produced

    # --------------------------------------------------------------- tool exec

    def _execute_tool_calls(
        self, tool_calls: list[dict[str, Any]], confirmed: bool = False
    ) -> list[AgentMessage]:
        results: list[AgentMessage] = []
        tool_registry = get_agent_tools()

        if not confirmed:
            names = [
                ((call.get("function") or {}).get("name") or "") for call in tool_calls
            ]
            if any(is_mutating(name) for name in names):
                for tool_call, name in zip(tool_calls, names, strict=True):
                    results.append(
                        self._record_tool_message(
                            tool_call.get("id") or "",
                            name,
                            {"pending_confirmation": True},
                            created_recipe_id=None,
                            requires_confirmation=True,
                        )
                    )
                return results

        for tc in tool_calls:
            tool_call_id = tc.get("id") or ""
            function = tc.get("function") or {}
            name = function.get("name") or ""
            try:
                args = _parse_arguments(function.get("arguments"))
            except InvalidUsage as exc:
                results.append(
                    self._record_tool_message(
                        tool_call_id, name, {"error": str(exc)}, created_recipe_id=None
                    )
                )
                continue

            entry = tool_registry.get(name)
            if not entry:
                results.append(
                    self._record_tool_message(
                        tool_call_id,
                        name,
                        {"error": f"Tool '{name}' is not available to the agent"},
                        created_recipe_id=None,
                    )
                )
                continue

            schema, handler = entry
            # Lock down ``household_id``: the agent is bound to a single
            # household, so it must not be able to read from or mutate any
            # other household the user happens to belong to. We override
            # whatever the LLM produced.
            properties = (
                (schema.get("properties") or {}) if isinstance(schema, dict) else {}
            )
            if "household_id" in properties:
                args["household_id"] = self.chat.household_id
            if "chat_id" in properties:
                args["chat_id"] = self.chat.id

            # Snapshot pre-state for undo BEFORE the tool runs (irrelevant
            # for non-mutating tools). On error we discard ``before``
            # because the rollback restores the world to that state anyway.
            undo_before: dict[str, Any] | None = None
            if is_mutating(name):
                try:
                    undo_before = capture_before(name, args)
                except Exception as exc:  # pragma: no cover - defensive
                    _logger.info(
                        "Failed to capture undo snapshot for '%s': %s", name, exc
                    )
                    undo_before = None

            try:
                payload = handler(args)
            except Exception as exc:
                _logger.info("Agent tool '%s' failed: %s", name, exc)
                # Roll back any half-applied ORM state from the failing tool
                # before recording the error. Prior chat messages were
                # already committed in ``_run_loop`` so they survive this.
                db.session.rollback()
                results.append(
                    self._record_tool_message(
                        tool_call_id,
                        name,
                        {"error": "Tool execution failed"},
                        created_recipe_id=None,
                    )
                )
                continue

            created_recipe_id = None
            if name == "create_recipe" and isinstance(payload, dict):
                rid = payload.get("id")
                if isinstance(rid, int):
                    created_recipe_id = rid
                    # Surface the freshly created recipe as a right-side card
                    # so the user can open or close it.
                    try:
                        title = (
                            (payload.get("name") if isinstance(payload, dict) else None)
                            or args.get("name")
                            or "Rezept"
                        )
                        desc = (
                            args.get("description")
                            or (
                                payload.get("description")
                                if isinstance(payload, dict)
                                else None
                            )
                            or ""
                        )
                        if desc and len(desc) > 400:
                            desc = desc[:397] + "\u2026"
                        card = AgentRecipeCard(
                            chat_id=self.chat.id,
                            recipe_id=rid,
                            source=CARD_SOURCE_CREATED,
                            title=str(title)[:255],
                            description=desc,
                        )
                        db.session.add(card)
                        db.session.flush()
                    except Exception as exc:  # pragma: no cover - defensive
                        _logger.info(
                            "Failed to create recipe card for tool call: %s", exc
                        )

            # Build the inverse-op snapshot from the successful payload so
            # ``rewind`` / ``edit`` can later undo the mutation.
            undo_snapshot: str | None = None
            if is_mutating(name):
                try:
                    ops = build_ops_from_result(name, args, payload, undo_before)
                    undo_snapshot = serialise_ops(ops)
                except Exception as exc:  # pragma: no cover - defensive
                    _logger.info("Failed to build undo ops for '%s': %s", name, exc)
                    undo_snapshot = None

            results.append(
                self._record_tool_message(
                    tool_call_id,
                    name,
                    payload,
                    created_recipe_id=created_recipe_id,
                    undo_snapshot=undo_snapshot,
                )
            )

        return results

    def _record_tool_message(
        self,
        tool_call_id: str,
        name: str,
        payload: Any,
        created_recipe_id: int | None,
        undo_snapshot: str | None = None,
        requires_confirmation: bool = False,
    ) -> AgentMessage:
        try:
            content = json.dumps(payload, ensure_ascii=False, default=str)
        except (TypeError, ValueError):
            content = json.dumps({"error": "tool result not serialisable"})
        msg = AgentMessage(
            chat=self.chat,
            role=AgentMessageRole.TOOL,
            content=content,
            tool_call_id=tool_call_id,
            tool_name=name,
            created_recipe_id=created_recipe_id,
            undo_snapshot=undo_snapshot,
            requires_confirmation=requires_confirmation,
        )
        db.session.add(msg)
        db.session.flush()
        return msg
