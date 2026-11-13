# REST API

KitchenOwl provides a REST API to interact with recipes, shopping lists, households, planner, and items.

The complete OpenAPI specification is available at [https://app.kitchenowl.org/api/openapi](https://app.kitchenowl.org/api/openapi).

## Authentication

Most endpoints require a JWT bearer access token obtained via `POST /api/auth`:

```bash
curl -s -X POST https://your-kitchenowl.example.org/api/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "password": "secret"}' | jq -r .access_token
```

Include this token in the `Authorization` header of subsequent requests:

```
Authorization: Bearer <access_token>
