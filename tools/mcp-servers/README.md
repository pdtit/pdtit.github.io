# Blog automation MCP servers

Two stdio MCP servers used by the **LinkedIn Poster** agent to publish blog
announcements to Peter's personal LinkedIn feed.

| Server | File | Purpose |
|---|---|---|
| `microsoft-designer` | [`microsoft-designer.js`](./microsoft-designer.js) | Generate post images via Azure AI Foundry **MAI-Image-2.5** |
| `linkedin` | [`linkedin-oauth.js`](./linkedin-oauth.js) | Post text + image to personal LinkedIn feed (3-legged OAuth) |

Both are wired into VS Code via [`.vscode/mcp.json`](../../.vscode/mcp.json).

## Install

```powershell
cd tools/mcp-servers
npm install
```

## Environment variables

Set in [`.vscode/mcp.json`](../../.vscode/mcp.json) — kept out of git via
`.gitignore`.

| Var | Used by | Notes |
|---|---|---|
| `AZURE_AI_ENDPOINT` | `microsoft-designer` | `https://<resource>.services.ai.azure.com` |
| `AZURE_AI_MODEL` | `microsoft-designer` | Deployment name, e.g. `MAI-Image-2.5` |
| `LINKEDIN_CLIENT_ID` | `linkedin` | From your LinkedIn Developer app |
| `LINKEDIN_CLIENT_SECRET` | `linkedin` | From your LinkedIn Developer app |

Azure auth uses `DefaultAzureCredential`, so `az login` in a terminal is enough
(no API key needed). Token scope: `https://ai.azure.com/.default`.

## LinkedIn app setup (one-time)

At https://www.linkedin.com/developers/apps, on your app:

1. **Auth** → Authorized redirect URLs → add `http://localhost:3000/callback`
2. **Products** → enable:
   - *Sign In with LinkedIn using OpenID Connect*
   - *Share on LinkedIn*

That's all. **Community Management API is NOT required** for personal-feed posting.

## First-run authorization

After VS Code loads the MCP server (Command Palette → `MCP: List Servers` → start `linkedin`):

```
Copilot Chat → call tool: linkedin_authorize
```

A browser tab opens, you sign in to LinkedIn, the token is captured by the local
callback listener on port 3000, and saved to `.linkedin-token.json` (gitignored).
Token lifetime is ~60 days; re-run `linkedin_authorize` when it expires.

Check status anytime via the `linkedin_token_status` tool.

## Tools exposed

### `microsoft-designer`

- `generate_linkedin_image` — `{ prompt, outputPath }` → writes a PNG.
  Default dimensions 1024×1024 (max total pixels 1,048,576 per MAI limits).

### `linkedin`

- `linkedin_authorize` — runs the OAuth browser flow, saves token.
- `linkedin_token_status` — reports whether a valid token is on disk.
- `post_to_linkedin` — `{ text, imagePath? }` → publishes to your feed,
  returns the post ID and URL.

## End-to-end flow

```
Blog post (draft:false)
    │
    ├──► LinkedIn Poster agent drafts post.md + image-prompt.md
    │       under social/linkedin/<slug>/
    │
    ├──► microsoft-designer.generate_linkedin_image
    │       → social/linkedin/<slug>/image.png
    │
    ├──► Peter approves
    │
    └──► linkedin.post_to_linkedin (text + image)
            → live on https://www.linkedin.com/in/petender/
```

## VS Code MCP gotchas

- Editing an MCP server's `.js` file does **not** restart the server on
  `Developer: Reload Window`. Use `MCP: List Servers` → Restart.
- Tool definitions are fetched only at server start, so newly added tools also
  require a server restart before they appear in Copilot.
