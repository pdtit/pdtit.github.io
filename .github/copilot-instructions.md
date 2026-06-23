# Copilot Instructions — 007FFFLearning Blog (Hugo)

These conventions apply to all blog content under `content/post/`. Follow them when editing existing posts or creating new ones.

## Repo overview

- **Static site generator**: Hugo (extended, pinned to 0.157.0+; see local `tools/hugo/hugo.exe`)
- **Theme**: Stack
- **Live site**: https://www.pdtit.be
- **Permalink pattern**: `https://www.pdtit.be/post/<slug>/` (Hugo default; slug = filename lowercased, spaces → hyphens, special chars stripped)
- **Publish dir**: `docs/` (committed; GitHub Pages serves from `main` branch via `.github/workflows/hugo.yml`)

## File layout

- Blog posts: `content/post/<Title With Spaces>.md` — filenames use spaces and mixed case; match nearby posts rather than slugifying
- **Drafts folder**: `drafts/` — work-in-progress posts that aren't ready to publish yet. Use this for exploratory posts, off-topic ideas, or anything you want to develop before committing to the blog timeline
- Post template: `content/post/____Template___.md`
- Images: `content/images/<filename>.png` — referenced from posts as `../images/<filename>.png`
- Static assets: `static/`
- Custom SCSS: `assets/scss/custom.scss`

**Publishing workflow**:
1. New drafts start in `drafts/<Title>.md` with `draft: true`
2. When ready to publish, move the file to `content/post/<Title>.md`
3. Flip `draft: true` → `draft: false` to trigger the LinkedIn Poster agent
4. Hugo builds only publish `draft: false` files from `content/post/`

## Frontmatter (required on every post)

```yaml
---
title: "<Title in Title Case>"
date: <YYYY-MM-DD>
publishdate: <YYYY-MM-DD>
tags: ["<tag1>", "<tag2>", "<tag3>"]
draft: true
---
```

- `draft: true` while writing. Flip to `draft: false` when ready — that's the trigger for the LinkedIn Poster agent.
- `date` and `publishdate` are both required and should match.
- `tags` casing must match existing posts. Common tags in this repo:
  `"Azure"`, `"DevOps"`, `"GitHub Copilot"`, `"Infrastructure as Code"`, `"AI"`, `".NET Development"`, `"Bicep"`

## Voice and style

Peter's posts are **low-key, personal, hands-on, technically accurate**. Don't write like a marketing page.

- First-person, conversational. Common openers: *"If you've been following me for a while..."*, *"Over the last weeks I've been..."*, *"Hey awesome people,"*
- Short parenthetical asides — small jokes, self-deprecation, side-thoughts. Sprinkle 2–4 per post, not more. Example: *"(does that exist as a word?)"*, *"(I'm pretty sure just saying 'yes' would have worked too...)"*
- Hands-on first, theory second. Lead with what was done, then explain why.
- Numbered step lists for walkthroughs, with one screenshot per meaningful step.
- Honest about gotchas, what didn't work, what's a "TODO for another post".
- Cross-link to MS Learn / official docs, prior Peter posts, and his GitHub repos (`github.com/petender/...`).

### Forbidden phrases (AI-tells)

Do not use:
- "delve into", "harness the power of", "unlock the potential"
- "in today's fast-paced world", "in the ever-evolving landscape"
- "revolutionary", "game-changer", "paradigm shift"
- emojis in headings (light use in prose is fine)

### Sign-off (always last block, exact format)

```
[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
```

## Screenshots

- Filename pattern in existing posts: `screenshot-<YYYY-MM-DD>-<8-char-hash>.png`
- For new drafts, use placeholder: `![<caption>](../images/TODO-<short-slug>.png)` with a `<!-- TODO screenshot: <what to capture> -->` comment next to it. Peter swaps these in during review.

## Length

- Standard post: ~800–1500 words.
- Don't pad. If the topic is short, the post is short.

## Local build / preview

```powershell
# from repo root
& "$PWD\tools\hugo\hugo.exe" server -D
# full build (matches production)
& "$PWD\tools\hugo\hugo.exe" --gc --minify -D --baseURL "https://www.pdtit.be/"
```

## Multi-agent workflow

This repo has four custom agents under `.github/agents/`:

1. **DevOps Researcher** — scans for trending Microsoft DevOps topics, returns a ranked shortlist of 5
2. **Blog Composer** — drafts the post in Peter's voice (always `draft: true`)
3. **Blog Publisher** — validates and publishes posts from `drafts/` to `content/post/`, commits to git, and hands off to LinkedIn Poster
4. **LinkedIn Poster** — generates image, drafts LinkedIn post text, posts to Peter's personal profile after approval

The default agent (you) should respect the same voice rules above when making small in-place edits, and should **not** flip `draft: true` → `false` without an explicit instruction from Peter.

## MCP server requirements

The LinkedIn publishing workflow requires two MCP servers configured in `.vscode/mcp.json`:

- **`linkedin`** — OAuth-based LinkedIn posting (personal profile via `w_member_social` scope)
- **`microsoft-designer`** — Azure AI Foundry MAI-Image-2.5 for generating LinkedIn images

**Auto-start enabled**: MCP servers are configured to auto-start via `chat.mcp.autostart: "newAndOutdated"` in `.vscode/settings.json` (requires VS Code 1.103+).

**When LinkedIn posting is requested**, agents should:
1. Verify `linkedin` token status via `linkedin_token_status` before attempting to post (if expired, prompt to run `linkedin_authorize`)
2. **Always show the generated image and post text for explicit approval before posting** — never auto-post without confirmation
3. **After successful posting, delete the temporary files** (`image.png`, `post.md`, `image-prompt.md`) from `social/linkedin/<slug>/`

**If MCP servers fail to start automatically**: Open MCP panel (`Ctrl+Shift+P` → `MCP: List Servers`) and click the start icon, or run `Developer: Reload Window`.
