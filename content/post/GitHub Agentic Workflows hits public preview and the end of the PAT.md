---
title: "GitHub Agentic Workflows hits public preview — and you can finally drop the PAT"
date: 2026-06-19
publishdate: 2026-06-19
tags: ["GitHub Copilot", "DevOps", "AI"]
draft: true
---

You know I'm always interested when something new ships that makes automation (DevOps, right!) easier, especially when it involves AI agents. So when two [GitHub changelog](https://github.blog/changelog/) entries landed on the same day last week, I knew they were made for each other. [GitHub Agentic Workflows is now in public preview](https://github.blog/changelog/2026-06-11-github-agentic-workflows-is-now-in-public-preview), and at the exact same time, [agentic workflows no longer need a personal access token](https://github.blog/changelog/2026-06-11-agentic-workflows-no-longer-need-a-personal-access-token).

Let me explain why this matters, what an agentic workflow actually looks like, and why ditching the PAT is a genuinely good security win.

## What Are GitHub Agentic Workflows?

GitHub Agentic Workflows is an automation framework where you define your workflows in **natural-language Markdown files**, and the `gh-aw` CLI compiles them into standard GitHub Actions YAML. That means you describe what you want to happen using plain language, and GitHub translates it into the automation steps you'd normally have to code yourself.

The big difference from traditional Actions? These workflows are designed for **reasoning-based tasks** — things that need some level of decision-making rather than just running a script. GitHub highlights use cases like:

- Issue triage
- CI failure analysis
- Documentation updates
- Dependency maintenance
- Security remediation

Because the output is still standard GitHub Actions YAML, everything runs on your existing runner groups and respects your existing policy constraints. No new infrastructure to worry about. (Which is always a nice bonus...)

## What Does an Agentic Workflow File Actually Look Like?

Most intros you'll find online start with "install this pre-baked workflow from the [agentics sample repo](https://github.com/githubnext/agentics) and watch it go." That's fine for a five-minute demo, but it doesn't really teach you anything — somebody else wrote the prompt and you just clicked install. The whole *point* of agentic workflows is that **you write the prompt yourself**, in plain Markdown.

So let's build one from scratch. A small one, with a job you can actually finish reading.

**Scenario**: a teammate comments `/summarize` on a long, sprawling GitHub issue. The agent reads the issue and any comments, then posts a 3-bullet TL;DR back as a single comment. That's the whole workflow.

Here's the entire file — one Markdown file, `summarize.md`, that I'll drop into `.github/workflows/`:

````yaml
---
name: Summarize Issue
description: Posts a 3-bullet TL;DR when someone comments /summarize on an issue.

on:
  slash_command:
    name: summarize
    events: [issue_comment]
  reaction: eyes

permissions:
  contents: read
  issues: read

tools:
  github:
    toolsets: [default]

safe-outputs:
  add-comment:
    max: 1

timeout-minutes: 5
---

# Summarize Issue

A user invoked `/summarize` on issue #${{ github.event.issue.number }}
in repository ${{ github.repository }}.

## What to do

1. Read the issue using `get_issue`.
2. Also read any comments using `get_issue_comments` (skip the `/summarize`
   comment itself).
3. Write a **3-bullet TL;DR** of the conversation. Cover:
   - What the issue is about (one bullet)
   - Where the discussion has landed so far (one bullet)
   - What action, if any, seems to be expected next (one bullet)
4. Keep each bullet under 25 words. No fluff, no preamble.
5. Post the summary as a single comment using the `add-comment` safe output,
   prefixed with `**TL;DR**` on its own line.

## Rules

- Do not summarize the `/summarize` comment itself.
- If the issue has fewer than 3 comments and the body is short (<200 words),
  reply with one comment saying "Nothing to summarize yet — the issue is
  already short!" and stop.
- Do not propose actions, fixes, or opinions. Just summarize.
````

Stop and look at that for a second, because it's doing a lot in very little space:

- **Frontmatter = the contract.** `permissions:` says the agent can only *read* issues and repo contents. `safe-outputs: add-comment: max: 1` declares the *one and only* write action it's allowed to take, capped at one comment per run. That's the entire write surface. The agent literally cannot do anything else even if it wanted to.
- **`on.slash_command`** — the trigger is the user typing `/summarize` in a comment. That's the prompt input, and it's right there in the contract. (No webhooks to configure, no separate trigger script.)
- **`reaction: eyes`** — when the workflow picks up the comment, GitHub adds a 👀 reaction so the user knows something's happening.
- **The body in Markdown** — this *is* the prompt. Plain English instructions, numbered steps, rules at the bottom. No DSL, no `if:` conditionals scattered through YAML. You can hand this file to a teammate and they'll know exactly what the agent will do.

That separation is what I keep coming back to: **frontmatter is the security contract, body is the prompt.** Read either one in isolation and you still understand half the workflow. Read both and you've got the whole picture.

## Building Your Own — From Blank File to First Run

Let's actually wire this up. I'll do it on a throwaway sandbox repo (which you should also do — please don't experiment on a repo you care about until you've seen how the agent behaves in practice).

**Prereqs** (5 min if you don't already have them):

- `gh` CLI v2.0.0+ — check with `gh --version`
- Logged in with the right scopes: `gh auth login --scopes repo,workflow`
- A repo where you have write access, with GitHub Actions enabled
- An AI account — Copilot, Claude, Codex, or Gemini. (For this demo I'm using Copilot.)

**Step 1 — Install the `gh-aw` extension:**

```bash
gh extension install github/gh-aw
```

If you hit auth weirdness, the docs ship a fallback installer:

```bash
curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
```

**Step 2 — Create a sandbox repo and initialize it:**

```bash
gh repo create gh-aw-sandbox --private --clone --add-readme
cd gh-aw-sandbox
gh aw init
```
//add screenshot placeholder here

`gh aw init` scaffolds the bits the CLI needs: a `.gitattributes` entry, a `.github/skills/agentic-workflows/` skill folder (so coding agents understand the format), a `.github/agents/agentic-workflows.md` custom-agent file, and an MCP config. Commit it before going further, otherwise the next step will complain about a dirty tree:

```bash
git add -A && git commit -m "chore: gh aw init scaffolding" && git push
```

//add screenshot placeholder here

**Step 3 — Create a blank workflow:**

```bash
gh aw new summarize
```
// add screenshot placeholder here

This creates `.github/workflows/summarize.md` from a template and opens it for editing. (If your editor doesn't pop up, just open the file manually.)

// add screenshot placeholder here

**Step 4 — Replace the template with your own prompt.**

Here's the catch that ate 20 minutes of my afternoon: the file `gh aw new` generates ships with `on: workflow_dispatch` as its trigger. That means it'll only run when you click "Run workflow" in the Actions tab — typing `/summarize` on an issue will do absolutely nothing.

So **wipe the file completely** — the entire frontmatter block and the entire body — and paste in the `summarize.md` from the previous section. Especially make sure the `on:` block is now `on.slash_command:` and *not* `workflow_dispatch`. (Editing only the prompt body and leaving the original `workflow_dispatch` trigger in place is the single biggest "why isn't this working?" trap I hit. Don't be me.)

**Step 5 — Compile it:**

```bash
gh aw compile summarize
```

//add screenshot placeholder here

The compiler reads your Markdown file and (re)generates `summarize.lock.yml` — a standard GitHub Actions workflow that does all the plumbing: sets up the agent runtime, wires the slash-command dispatcher, enforces the `safe-outputs` contract, runs the threat-detection job on any proposed comment, and posts it.

Two things that confused me the first time and are worth knowing:

1. **`summarize.md` is your only source of truth. Never edit `summarize.lock.yml` by hand.** Every time you change the `.md`, you must rerun `gh aw compile summarize` to regenerate the lockfile. If you skip the recompile and push, the agent runs whatever was in the last lockfile — not what you just wrote. (This is exactly how I ended up with a workflow that still had the old `workflow_dispatch` trigger even though my `.md` had been replaced.)
2. **The generated `summarize.lock.yml` will still contain `workflow_dispatch` somewhere in it — that's normal.** Even when your source is `on.slash_command`, the compiler emits a `workflow_dispatch` dispatcher alongside the `issue_comment` trigger that actually listens for `/summarize`. Don't try to "fix" it by deleting the `workflow_dispatch` from the lockfile; that's part of the compiled wiring.

What you can do to sanity-check that the compile picked up your change: open `summarize.lock.yml` and look for `issue_comment` in the `on:` block. If it's there, your slash command is wired up. If the only trigger you see is `workflow_dispatch`, your `.md` didn't get the new `on.slash_command:` block from Step 4 — go back and fix it, then recompile.

**Step 6 — Give the workflow a token to talk to Copilot.**

Quick note on credentials, because this trips up almost everyone on their first run: the `GITHUB_TOKEN` that Actions ships with handles the *repo-side* write operations declared in `safe-outputs:` — posting that one comment, in our case. What it doesn't handle is the agent calling **Copilot's API** to do the actual reasoning. For that, the Copilot engine needs a separate secret called `COPILOT_GITHUB_TOKEN`. If it's missing, your workflow will fail on the very first run with `missing secret COPILOT_GITHUB_TOKEN`.

(Yes, I know — the next section of this post is literally called "No More PAT Required." That's still true, but it's about the *repo-side* write surface. Engine auth is its own separate thing on personal repos. I'll come back to this in a minute.)

Three steps to set it up:

1. Open [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new) and create a **fine-grained personal access token** under your user account. Scope it to *only* this sandbox repo while you're learning — don't grant org-wide or all-repos access.
2. Under **Permissions → Account permissions**, set **Copilot Requests** to **Read**. That's the only permission this token needs. (No repo permissions. No anything else. Keep its blast radius small.)
3. Save the token value to a file (or just paste it inline), then push it into the repo as a secret:

```bash
gh secret set COPILOT_GITHUB_TOKEN < token.txt
# or, GUI route: Repo → Settings → Secrets and variables → Actions → New repository secret
```

Verify it's set:

```bash
gh secret list
```

You should see `COPILOT_GITHUB_TOKEN` in the list. Now you're actually ready to run.

**Step 7 — Commit, push, and test it:**

```bash
git add .github/workflows/summarize.md .github/workflows/summarize.lock.yml
git commit -m "feat: add /summarize agent"
git push

# Create a test issue with enough content to be worth summarizing
gh issue create --title "Should we move to Bicep?" --body "Long-form discussion about migrating our IaC from ARM to Bicep — team concerns about learning curve, our current ARM template count, timing relative to the Q3 release, plus a few links to prior discussions."

//add image placeholder screenshot here


# Comment /summarize on the resulting issue (replace <n> with the issue number)
gh issue comment <n> --body "/summarize"
```

Within seconds you'll see the 👀 reaction land on your `/summarize` comment. About 2 minutes later, the TL;DR shows up as a new comment on the issue:

![The /summarize agent posting a TL;DR comment](../images/TODO-summarize-result.png)
<!-- TODO screenshot: the resulting **TL;DR** comment on the test issue with the 3 bullets -->

That's the whole loop. **You wrote the prompt. The agent did the action. The contract between them is right there in the same file.**

### A couple of gotchas I hit doing this for real

Worth flagging because the docs don't always shout about them:

- **Working tree must be clean.** Both `gh aw new`/`compile` flows and `gh aw add-wizard` refuse to run if you have uncommitted changes. Commit or stash first.
- **The default remote needs to be called `origin`.** I first tried this against a repo where the remote was named `github` (my Hugo blog repo, in fact) and the wizard cheerfully created a local branch, committed, then died with `fatal: 'origin' does not appear to be a git repository`. Either rename your remote (`git remote rename github origin`) or just use a fresh repo that has the standard layout.
- **Keep `gh aw` itself current.** Things move fast in preview:

```bash
gh extension upgrade github/gh-aw   # extension itself
gh aw upgrade                       # gh-aw engine
gh aw update                        # update any workflows you installed from a `source:` field
```

(I'm planning to leave this running on the sandbox repo for a week or two before pointing it at anything I actually care about — basic hygiene with any agent automation.)

## The Big Security Win: No More PAT Required (for repo writes, at least)

Now let's talk about the second changelog entry, because this is where things get genuinely better from a security standpoint.

Previously, if you wanted an agentic workflow to interact with your repository — labeling issues, opening pull requests, updating documentation — you needed a **personal access token (PAT)** *for those write operations*. That meant creating a long-lived token with `repo` scope, storing it as a secret, worrying about rotation policies, and hoping it didn't leak. PATs are powerful, and they're a common target for attackers. (I've seen too many PAT leaks in my time as a consultant, and they're never fun to clean up...)

As of June 11th, **agentic workflows now do those repo-side writes via GitHub Actions's built-in `GITHUB_TOKEN`**, routed through the `safe-outputs:` pipeline. No more `repo`-scoped PAT. No more secret rotation for the write surface. No more long-lived credentials sitting in your repository settings just so the workflow can drop a comment.

A quick honesty check, because we just hit this in Step 6: the `COPILOT_GITHUB_TOKEN` you set up earlier is *not* the PAT that just got retired. That one is a much smaller, fine-grained token — read-only, scoped to Copilot Requests on one repo — used purely so the engine can talk to Copilot's API. The old PAT was a sprawling thing with full repo write. Trading the sprawling one for `GITHUB_TOKEN` + a tiny scoped engine token is still a clear net win for blast radius, even though you didn't get to drop all secrets entirely.

And if you're running in an **organization-owned repository**, you can actually skip the engine token too. Add `copilot-requests: write` to the `permissions` frontmatter, recompile, push — and now the workflow uses `GITHUB_TOKEN` for the engine call as well, with AI credits billed directly to the organization rather than an individual user's Copilot quota. Make sure your extension is current first:

```bash
gh extension upgrade github/gh-aw
```

![Enabling org billing in an agentic workflow](../images/TODO-agentic-workflows-2.png)
<!-- TODO screenshot: show the frontmatter with copilot-requests: write added to permissions -->

This change removes operational friction and reduces the attack surface. It's a solid improvement, and frankly, it should have been like this from the start. But better late than never.

## Security Layers Built In

GitHub Agentic Workflows also ships with several security safeguards that make me more comfortable trusting an agent to make changes:

- **Integrity filter**: agents access GitHub content respecting defined integrity rules.
- **Read-only by default**: workflows run with read-only permissions unless you explicitly grant write access.
- **Sandboxed execution**: workflows execute inside a container behind the "Agent Workflow Firewall".
- **Safe outputs validation**: outputs are validated before being used.
- **Threat detection job**: scans all proposed changes before they're applied.

These layers matter. Getting an agent to open a pull request was never the hard part — trusting it enough to merge is. GitHub is clearly thinking about this, and the safeguards are a good start.

## Cost Control

Because agentic workflows consume AI credits, GitHub added cost management tools. You can cap token usage per workflow run using the [built-in cost management tools](https://gh.io/gh-aw-cost). If you're using organization billing, you can also configure [cost centers](https://docs.github.com/billing/concepts/cost-centers) to track spend across groups of organizations.

This is important. Without guardrails, a runaway workflow could burn through your credits fast. (Ask me how I know... or actually, don't.)

![Cost management settings for agentic workflows](../images/TODO-agentic-workflows-3.png)
<!-- TODO screenshot: show the cost management UI or settings page for capping token usage -->

## What I'd Still Want to See

This is a solid public preview, but there are a few things I'd love to see GitHub add as this matures:

1. **Better observability into what the agent is thinking**. Right now, you get the workflow run logs, but I'd like more transparency into the reasoning steps the agent took before making a decision. Something like an "agent thought process" tab in the Actions UI.

2. **Easier rollback mechanisms**. If an agent makes a bad decision, I want a one-click "undo this entire workflow run" button. Maybe that exists and I just haven't found it yet.

3. **More examples for security use cases**. The current example repo is great, but I'd love to see more workflows focused on vulnerability remediation, license compliance, and secret scanning follow-ups.

These are minor compared to what's already here, but they'd make the experience even better.

## Summary

GitHub Agentic Workflows is a smart way to automate reasoning-based tasks in your repositories. By letting you define workflows in natural language and compiling them into standard Actions, GitHub has lowered the barrier to building agent-driven automation.

But the real win for me is the PAT removal. Using the built-in `GITHUB_TOKEN` means fewer secrets to manage, fewer rotation headaches, and a smaller attack surface. That alone is worth paying attention to.

If you're already using GitHub Actions and you've been curious about agents, this is a low-friction way to experiment. Install the `gh-aw` extension, write a small Markdown file with a prompt of your own (start with `/summarize` if you want a template), and watch the agent take real actions in your repo. If you want to see what bigger prompts look like once you've got the basics down, there are dozens of more elaborate examples in the [agentics repo](https://github.com/githubnext/agentics).

This is available for all Copilot plans — Free, Pro, Pro+, Business, and Enterprise. So there's no barrier to trying it out.

Have you played with agentic workflows yet? If so, I'd love to hear what you built. Drop me a note!

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
