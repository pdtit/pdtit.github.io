---
title: "Automating blog promotion with VS Code agents and MCP servers"
date: 2026-06-20
publishdate: 2026-06-20
tags: ["GitHub Copilot", "DevOps", "AI"]
draft: true
---

If you've been following me for a while, you know I write a fair bit about Microsoft DevOps, Azure, and lately GitHub Copilot. What you probably don't know is that I've been leaning on VS Code's agent mode to help me stay on top of what's trending. It scans GitHub changelog feeds, filters for the DevOps-relevant bits, and hands me a shortlist of topics worth exploring. That part's been working well for months. (And yes, I do miss the good old RSS-feeds, although I know some sites still have them...)

But the part that was still manual (and honestly, a bit of a drag) was what happened *after* I hit publish on the blog (and my GitHub Actions workflow updates GitHub Pages...). Every single post meant:

1. Open LinkedIn in a browser
2. Write a 150–200 word teaser from scratch
3. Hunt for a relevant image (or make one using a prompt in M365 Copilot, which... yeah)
4. Copy-paste, format, add hashtags, post
5. Hope I didn't typo the URL

It wasn't *hard*, but it was friction. And friction means I'd sometimes skip it, which defeats the whole point of writing the post in the first place. And even more so, it goes against my believe of DevOps-ing everything.

So over the last couple of weeks, I built a small automation workflow using **VS Code agents** and **MCP servers** that takes a "ready for publish"-ed blog post, generates a custom LinkedIn image via Microsoft Foundry (although OpenAI would work the same...), drafts the announcement text in my voice, shows me both for approval, and posts it with one confirmation. The whole thing takes about 30 seconds now instead of 10 minutes before.

Let me show you how it works, and how you can set up something similar if you're publishing content regularly.

## What Are MCP Servers?

MCP stands for **Model Context Protocol** — it's a standard way for AI agents (like GitHub Copilot in VS Code) to call external tools and services. Think of it like a plugin system, but instead of installing a VS Code extension, you configure a small Node.js script that exposes a set of tools the agent can invoke.

In my case, I needed two MCP servers:

1. **`linkedin`** — handles OAuth authentication and posting to my LinkedIn personal feed
2. **`microsoft-designer`** — calls Microsoft Foundry's MAI-Image API to generate custom images from text prompts

Both are just JavaScript files that implement the MCP protocol. VS Code detects them via a config file (`.vscode/mcp.json`) and makes their tools available to any agent running in that workspace.

The nice part? Once they're configured, I don't have to think about them. The agent just calls `generate_linkedin_image` or `post_to_linkedin` like it would any other function.

## Step 1: Configure the MCP servers

First, you need the two MCP server scripts. I won't paste the full code here (it's ~150 lines each - but feel free to check [this blog repo](https://github.com/pdtit/pdtit.github.io/tree/main/tools)), but the structure is:

**`tools/mcp-servers/linkedin-oauth.js`** — implements:
- `linkedin_authorize` — one-time OAuth flow to get a token
- `linkedin_token_status` — check if the token is still valid
- `post_to_linkedin` — POST to the LinkedIn Share API with text + image

**`tools/mcp-servers/microsoft-designer.js`** — implements:
- `generate_linkedin_image` — calls Microsoft Foundry MAI-Image API with a text prompt, saves PNG to disk

Both scripts use the standard `@modelcontextprotocol/sdk` npm package. If you want to build your own, the [MCP specification](https://modelcontextprotocol.io) has good examples.

Once the scripts are in place, you configure VS Code to recognize them by creating `.vscode/mcp.json`:

```json
{
  "servers": {
    "microsoft-designer": {
      "type": "stdio",
      "command": "node",
      "args": ["c:\\path\\to\\tools\\mcp-servers\\microsoft-designer.js"],
      "env": {
        "AZURE_AI_ENDPOINT": "https://your-foundry-resource.services.ai.azure.com",
        "AZURE_AI_MODEL": "MAI-Image-2.5"
      }
    },
    "linkedin": {
      "type": "stdio",
      "command": "node",
      "args": ["c:\\path\\to\\tools\\mcp-servers\\linkedin-oauth.js"],
      "env": {
        "LINKEDIN_CLIENT_ID": "your-app-id",
        "LINKEDIN_CLIENT_SECRET": "your-app-secret"
      }
    }
  }
}
```

<!-- TODO screenshot: VS Code MCP panel showing both servers configured -->
![MCP servers configured](../images/TODO-mcp-servers.png)

A couple of notes here:

- **For the LinkedIn server**: you need to create a LinkedIn app at [developers.linkedin.com](https://www.linkedin.com/developers/apps). Use the "Share on LinkedIn" product (it's auto-approved for personal profile posting). The OAuth redirect URI should be `http://localhost:3000/callback` — the MCP server spins up a temporary local web server to catch the callback.

(Honestly, this part confused me a lot, since I didn't want a company page, neither did I wanted to start posting on LinkedIn from a company page. But there is a solution for this... read on :))

- **For the Designer server**: you need an Microsoft Foundry project with the MAI-Image-2.5 model deployed. The endpoint URL is your Foundry resource endpoint, not the deployment-specific URL. The MCP server uses `DefaultAzureCredential` for auth (so `az login` or managed identity works).

## Step 2: Enable MCP auto-start

By default, MCP servers don't start automatically. You'd have to open the MCP panel (`Ctrl+Shift+P` → `MCP: List Servers`) and click the start icon every time you open VS Code.

But as of VS Code 1.103, there's a setting that makes them auto-start:

**`.vscode/settings.json`**:
```json
{
  "chat.mcp.autostart": "newAndOutdated"
}
```

<!-- TODO screenshot: VS Code settings.json with autostart enabled -->
![MCP autostart setting](../images/TODO-mcp-autostart.png)

This tells VS Code to automatically start any MCP servers that are newly configured or have been updated. No more manual start, no more "reload window" dance.

## Step 3: Define the LinkedIn Poster agent

Now for the fun part. I created a custom VS Code agent mode that knows how to take a published blog post and turn it into a LinkedIn announcement. The agent definition lives at `.github/agents/linkedin-poster.agent.md` and looks like this (abbreviated):

```markdown
---
name: "LinkedIn Poster"
description: "Use when a blog post has moved from draft to final (draft:false) and needs a LinkedIn announcement."
tools: [read, edit, search, web]
---

# LinkedIn Poster agent

Single-purpose agent: take a published blog post and publish a matching LinkedIn announcement (text + image) to Peter's personal LinkedIn profile via the `linkedin` and `microsoft-designer` MCP servers.

## Workflow

1. **Locate the post** — read the blog post markdown
2. **Derive the slug** — Hugo permalink is `https://www.pdtit.be/post/<slug>/`
3. **Draft the LinkedIn text** in Peter's voice (120–200 words, conversational, 1–2 parenthetical asides)
4. **Draft the image prompt** — flat-design technical diagram, Azure blues + LinkedIn blue
5. **Save artifacts** to `social/linkedin/<slug>/` (post.md, image-prompt.md)
6. **Generate the image** via `microsoft-designer` MCP → save as `image.png`
7. **Present for validation** — show the text + image path, wait for approval
8. **On approval** → call `linkedin` MCP to post
9. **Clean up** — delete temp files (image.png, post.md, image-prompt.md)

## Hard rules

- Never publish without explicit "go" from Peter.
- Never flip `draft: true` → `draft: false` — that's Peter's signal, not yours.
```

<!-- TODO screenshot: VS Code agent mode selector showing LinkedIn Poster -->
![LinkedIn Poster agent mode](../images/TODO-agent-mode.png)

The full file is about 70 lines and includes detailed voice guidelines (match my blog style, avoid AI-tell phrases like "delve into" or "unlock the potential", etc.). You can see the pattern — it's essentially a prompt that tells the agent what tools to call and in what order.

## Step 4: One-time LinkedIn OAuth

Before the agent can post, you need to authorize the LinkedIn MCP server once. This is a one-time setup:

1. Open the VS Code chat panel in agent mode
2. Type: "run linkedin_authorize"
3. The MCP server opens a browser to LinkedIn's OAuth page
4. Log in, approve the app
5. The MCP server saves the token to `~/.linkedin-mcp/token.json`

<!-- TODO screenshot: LinkedIn OAuth consent screen -->
![LinkedIn OAuth approval](../images/TODO-linkedin-oauth.png)

The token is good for 60 days. After that, you just run `linkedin_authorize` again (takes 10 seconds).

## Step 5: Post to LinkedIn (the easy part)

Now here's what it looks like in practice. I just finished writing [yesterday's post on GitHub Agentic Workflows](/post/github-agentic-workflows-hits-public-preview-and-the-end-of-the-pat/). I flipped `draft: true` to `draft: false`, saved the file, and then:

**Me (in VS Code chat):**  
> "Can you help with a LinkedIn post and image for the agentic workflows article?"

**Agent (LinkedIn Poster mode):**  
> [reads the blog post]  
> [drafts LinkedIn text in `social/linkedin/.../post.md`]  
> [generates image prompt in `social/linkedin/.../image-prompt.md`]  
> [calls `mcp_microsoft-des_generate_linkedin_image`]  
> ✅ Image generated and saved to `social/linkedin/.../image.png`  
>  
> Here's the LinkedIn post text:  
> *[shows the 196-word draft]*  
>  
> Image saved at: `social/linkedin/.../image.png`  
>  
> Please review both the image (open it in VS Code or a viewer) and the post text. Reply "post it" when ready, or let me know if you'd like changes.

<!-- TODO screenshot: VS Code chat showing the generated LinkedIn text -->
![Agent drafts LinkedIn post](../images/TODO-linkedin-draft.png)

I opened the image (it was a flat-design diagram showing the 6-stage agentic workflow pipeline, looked good), skimmed the text, and replied:

**Me:**  
> "post it"

**Agent:**  
> ✅ Posted to your LinkedIn feed  
> Post ID: urn:li:share:7474146818864513025  
> URL: https://www.linkedin.com/feed/update/urn:li:share:7474146818864513025/  
>  
> Temporary files deleted.

<!-- TODO screenshot: LinkedIn post live on feed with custom image -->
![LinkedIn post live](../images/TODO-linkedin-live.png)

Total time: about 30 seconds. The image generation took ~8 seconds (Microsoft Foundry is fast), the LinkedIn API call was ~2 seconds, and the rest was me reading.

## What the agent actually does under the hood

Let me break down the tool calls the agent makes, because this is where the MCP servers earn their keep:

1. **`read_file`** (built-in VS Code tool) → reads the blog post markdown
2. **`create_file`** (built-in) → writes `post.md` and `image-prompt.md` to `social/linkedin/<slug>/`
3. **`mcp_microsoft-des_generate_linkedin_image`** (MCP tool) → sends the image prompt to Microsoft Foundry MAI-Image API, receives base64-encoded PNG, decodes it, saves to disk
4. **Waits for my approval** → this is the key part; the agent doesn't auto-post, it pauses and shows me the artifacts
5. **`mcp_linkedin_post_to_linkedin`** (MCP tool) → uploads the image via LinkedIn's asset registration API, then creates a share with the text + image URN
6. **`run_in_terminal`** (built-in) → deletes the temp files via PowerShell `Remove-Item`

The MCP servers abstract away all the OAuth token management, API request signing, error handling, and retry logic. The agent just says "generate this image" and gets back a file path. That's the beauty of the MCP pattern — clean separation between the agent's reasoning ("what to do") and the tool's execution ("how to do it").

## Why This Works for Me

A few things I really like about this setup:

**1. It's workspace-scoped.**  
The MCP server config lives in `.vscode/mcp.json` in my blog repo. If I open a different workspace, those tools aren't available. No global pollution, no cross-project leakage.

**2. I control the approval.**  
The agent never posts without showing me the text and image first. I can edit the draft, regenerate the image, or bail entirely. The automation is in service of me, not replacing me.

**3. The image prompts are tailored to the post.**  
Because the agent reads the actual blog content, it can write a specific image prompt — not generic "AI and cloud" stock imagery, but something that ties to the topic. For the agentic workflows post, it generated a pipeline diagram showing the 6 stages (pre_activation → activation → agent → detection → safe_outputs → conclusion). That's way better than a random header image.

**4. It's fast enough that I actually use it.**  
When something takes 10 minutes, I'll skip it half the time. When it takes 30 seconds, I do it every time. That's the threshold that matters.

**5. It's yet another example and learning on VSCode Agents.**
When I trained customers on GitHub Copilot, the scenarios mainly involved developer tasks. But with shifting to the Microsoft content team, I started using the same agent.md concept for so much more. And now also for automating steps in my blog post publishing sequence.

## Gotchas and things to know

**LinkedIn OAuth tokens expire after 60 days.**  
You'll need to re-run `linkedin_authorize` periodically. The MCP server tells you when the token is about to expire, so it's not a surprise, but it's not fully "set and forget" either.

**The LinkedIn API rate limit is 100 posts per day.**  
For a personal blog, that's... not a problem. But if you're automating posts for a company page or multiple accounts, you'll hit the limit fast. The MCP server doesn't implement retry-after logic (yet).

**Microsoft Foundry image generation costs about $0.04 per image.**  
At one post every few days, that's ~$0.60/month. Totally fine for me, but if you're generating dozens of images a day, it adds up. The MCP server doesn't cache images or check for duplicates, so every call is a fresh generation.

**The agent sometimes gets creative with the image prompts.**  
I've had to edit a prompt or two when the agent went a bit too abstract. Most of the time it nails the "flat-design technical diagram" brief, but occasionally it tries to add "a subtle gradient representing innovation" or something equally silly. That's why the approval step exists.

**MCP auto-start only works in VS Code 1.103+.**  
If you're on an older version, you'll need to manually start the servers from the MCP panel every time you open the workspace. Not a dealbreaker, but definitely less smooth.

## What I use agents for (and what I don't)

Since I'm writing a post about automation, I figured I'd be transparent about where I draw the line.

**I do use VS Code agent mode for:**
- Scanning changelog feeds and filtering for DevOps-relevant topics
- Drafting LinkedIn announcement text (with approval)
- Generating custom images for social posts
- Summarizing long GitHub issues or discussions
- Spot-checking code samples for typos or broken links

**I don't use agents for:**
- Writing the blog posts themselves (that's still me, coffee in hand, staring at the dark mode empty markdown on one monitor, technical stuff getting validated on the other monitor)
- Making decisions about what to publish or when
- Editing for voice — I review every word before it goes live
- Anything that posts publicly without my explicit approval

The automation is there to remove friction, not to replace judgment. I still write, I still edit, I still decide what's worth publishing. The agent just handles the "copy this text to LinkedIn and format it nicely" part that I was doing manually anyway.

## Summary

If you're publishing content regularly — blog posts, technical articles, release notes, whatever — and you're manually copy-pasting to LinkedIn or Twitter every time, you're burning time you don't need to burn. MCP servers make it surprisingly straightforward to wire up custom automation that stays under your control.

The setup I walked through here (LinkedIn + image generation via Azure AI) took about two hours to build, including the OAuth debugging (LinkedIn's error messages are... not great). Since then, I've posted half a dozen times and saved probably 90 minutes total. Not a huge ROI yet, but it's already paid for itself, and the friction savings are real.

If you want to build something similar, start small:

1. Pick one repetitive task (LinkedIn posting, tweet formatting, whatever)
2. Find or write an MCP server that handles the API calls
3. Define a custom agent mode that knows when to call it
4. Add an approval step so you stay in control
5. Use it a few times and tweak the prompts until it feels natural

And if you build something cool with MCP servers, let me know — I'm always interested to see what people automate when they have the right tools.

Have you tried VS Code agent mode for your own workflows? What's the first thing you'd automate?

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
