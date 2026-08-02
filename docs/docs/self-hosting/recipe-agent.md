# Recipe Agent

KitchenOwl can connect to a Large Language Model (LLM) so users can chat about
ideas and let the agent create complete recipes (name, description, yields,
prep/cook time, ingredients, tags) directly in their household.

The feature is **opt-in per household**: an admin configures the provider and
API key, then any chat the user starts can call KitchenOwl's existing
recipe / item / tag tools.

## Supported providers

The agent talks to any **OpenAI-compatible chat completions** endpoint, so it
supports out of the box:

| Provider | Base URL | Notes |
|----------|----------|-------|
| OpenAI | `https://api.openai.com/v1` | Default. Use models like `gpt-4o-mini`. |
| Google Gemini | _(empty — uses the native `gemini/` route)_ | Pick `Gemini` as provider and a model name like `gemini-1.5-flash`. |
| Ollama (self-hosted) | `http://localhost:11434/v1` | Pick `Custom`, set the URL, model = your pulled model (e.g. `llama3.1`), and explicitly allow `localhost` with `LLM_ALLOWED_HOSTS`. |
| OpenRouter / vLLM / LM Studio | as documented by the service | Pick `Custom`. |

## Configuration

Open **More → Recipe Agent → Settings** (admin only) and enter:

- **Provider**: `OpenAI`, `Google Gemini` or `Custom`.
- **Base URL**: optional; leave blank to use the provider default.
- **Model**: required. Examples: `gpt-4o-mini`, `gemini-1.5-flash`, `llama3.1`.
- **API key**: stored encrypted at rest.
- **System prompt**: optional. Use this to tell the agent about diets,
  allergies, preferred cuisines, etc.
- **Enable agent**: turns the menu entry on.

Use **Test connection** to verify the credentials before going live.

## Server-side environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_ENCRYPTION_KEY` | _(required outside debug mode)_ | Current Fernet key (url-safe base64, 32 bytes) used for new and existing API keys. |
| `LLM_ENCRYPTION_KEY_PREVIOUS` | _(unset)_ | Optional comma-separated previous Fernet keys. Keep the old key here during rotation so existing ciphertext remains readable. |
| `LLM_ALLOWED_HOSTS` | _(unset)_ | Comma-separated allowlist for every custom endpoint hostname. Built-in OpenAI and Gemini hosts work without it. |

Generate a Fernet key with:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

To rotate keys, move the old `LLM_ENCRYPTION_KEY` value to
`LLM_ENCRYPTION_KEY_PREVIOUS` and install the new value as
`LLM_ENCRYPTION_KEY`. New secrets use the current key while old secrets remain
readable. Remove the previous key only after all stored credentials have been
entered again under the current key.

## Security notes

- API keys are encrypted at rest with `cryptography.fernet` and **never**
  returned to the client. The settings page shows only whether a key is set.
- Only household **admins** can read or change the configuration. Members
  can use the agent.
- Each agent chat is private to the user that started it.
- Every tool call runs as the calling user; it cannot reach data outside the
  household, because all KitchenOwl tools enforce household membership.
- Custom endpoints must use HTTP(S), cannot include URL credentials, and must
  have their hostname explicitly listed in `LLM_ALLOWED_HOSTS`.
