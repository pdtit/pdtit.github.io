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

Let's look at a **real, working workflow** from the [githubnext/agentics](https://github.com/githubnext/agentics) sample family: the [Issue Triage workflow](https://github.com/githubnext/agentics/blob/main/workflows/issue-triage.md). It runs whenever an issue is opened or reopened, decides whether it's spam, picks the right labels, sets an issue type, looks for duplicates, and posts a structured triage comment for the maintainer.

Here's the frontmatter, lifted straight from the sample (I trimmed the long description to keep it readable):

```yaml
---
description: |
  Intelligent issue triage assistant that processes new and reopened issues.
  Analyzes content, detects spam, selects labels, sets issue type,
  detects duplicates, and posts a structured triage report.

on:
  issues:
    types: [opened, reopened]
    reaction: eyes

permissions: read-all

network: defaults

safe-outputs:
  add-labels:
    max: 5
  add-comment:
  set-issue-type:
    max: 1
  close-issue:
    target: "triggering"
    state-reason: "not_planned"
    max: 1

tools:
  web-fetch:
  github:
    toolsets: [issues, labels]
    min-integrity: none

timeout-minutes: 10
---
```

A few things worth pointing out, because this is where agentic workflows differ from the GitHub Actions you're used to:

- **`permissions: read-all`** — the workflow itself only *reads*. Notice there's no `issues: write` anywhere. That's intentional.
- **`safe-outputs:`** — this is how writes happen. Instead of letting the agent call the API directly, you declare which write operations are allowed (`add-labels`, `add-comment`, `set-issue-type`, `close-issue`) and the maximum count per run. Every proposed change is validated by the safe-outputs pipeline and the threat-detection job before it touches your repo. (This is the safety net that lets you actually trust the thing.)
- **`tools:`** — explicitly allow-lists what the agent can call. Here: `web-fetch` for browsing docs, plus the GitHub `issues` and `labels` toolsets. Anything not listed isn't reachable.
- **`reaction: eyes`** — small touch, but the workflow reacts to the triggering issue with 👀 so a human can see at a glance "the agent is on it."

Then below the frontmatter comes the **body in natural language** — the actual instructions for the agent:

```markdown
You are a triage assistant for GitHub issues. Your task is to analyze
issue #${{ github.event.issue.number }}, categorize it with the right
metadata, and help maintainers act quickly.

Do not make assumptions beyond what the issue content supports.
Do not invent missing context.

## Step 1: Gather context

1. Retrieve the issue content using the `get_issue` tool.
2. Fetch any comments on the issue using `get_issue_comments`.
3. Fetch the list of labels available in this repo using `list_label`.
4. Search for similar issues using `search_issues`.

## Step 2: Spam and quality check

If the issue is obviously spam, bot-generated, gibberish, or a test issue:
- Apply the `invalid` or `spam` label if one exists.
- Close the issue as "not planned" with a one-sentence reason.
- Stop here.

If the issue lacks enough detail, ask the author for what's missing
and apply a `needs-info` or `question` label if available.

## Step 3: Triage

- Pick the single best issue type (Bug, Feature, Task) if not already set.
- Choose labels that accurately reflect the issue, from the repo's existing labels only.
- Detect duplicates and related issues (up to 3 each).
- Assess whether the issue is suitable for a coding agent to pick up.

## Step 4: Apply results

Use the safe-outputs tools to apply labels, set type, optionally close,
and post a triage comment using the format below.
```

(That last section, plus a defined comment template, is what produces the structured triage report that actually lands on the issue.)

What I love about this is the **separation of concerns**: the frontmatter is the security/permissions contract, and the natural-language body is the prompt. You can read the body and immediately understand what the workflow does — no chasing through 200 lines of YAML to figure out which `if:` branch runs when.

## From Zero to Running — The Actual Hands-On Steps

Good news: you don't have to write this from scratch. Here's how I'd get the Issue Triage workflow running on one of your own repos.

**Prereqs** (5 min if you don't already have them):

- `gh` CLI v2.0.0+ — check with `gh --version`
- Logged in with the right scopes: `gh auth login --scopes repo,workflow`
- A repo where you have write access, with GitHub Actions enabled
- An AI account — Copilot, Claude, Codex, or Gemini. (For this demo I'm using Copilot.)

**Step 1 — Install the `gh-aw` extension:**

```bash
gh extension install github/gh-aw
```

![GH Auth and install extension](../images/2026-06-19_09-57-12.png)

If you hit auth weirdness, the docs ship a fallback installer:

```bash
curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
```

**Step 2 — From the root of your target repo, add the workflow with the wizard:**

```bash
gh aw add-wizard githubnext/agentics/issue-triage
```

I found out that it actually checks the clean state of your repo (staged changes). And it won't do anything if your repo is not in a clean state. 

![GH aw expect clean state](../images/2026-06-19_16-26-38.png)


The `<owner>/<repo>/<workflow-name>` format tells `gh-aw` to pull `issue-triage` from the public [githubnext/agentics](https://github.com/githubnext/agentics) examples repo. The wizard then walks you through:

1. Checking your repo permissions.
2. Picking your AI engine — Copilot / Claude / Codex / Gemini.
3. Setting up the secret the chosen engine needs (e.g. `COPILOT_GITHUB_TOKEN`, `ANTHROPIC_API_KEY`, etc.). It will offer to do this for you via `gh secret set`.
4. Writing two files into `.github/workflows/` — `issue-triage.md` (the workflow you'll edit) and `issue-triage.lock.yml` (the compiled Actions YAML — don't touch this one by hand).
5. Optionally kicking off an immediate run.

(Yes, the wizard is interactive. It saves a lot of guess-and-check.)

**Step 3 — Watch it run:**

```bash
gh aw status        # list workflow state
# or
gh run watch        # stream the most recent run
```

Or just open the Actions tab in the browser if you prefer screenshots over terminal output. A run typically takes 2–3 minutes. When it succeeds, open any newly created/reopened issue in the repo and you'll see the 👀 reaction and a fresh triage comment.

**Step 4 — Customize:**

Open `.github/workflows/issue-triage.md` and edit the natural-language steps to match your team's reality — your label set, your duplicate-detection rules, your tone. If you change anything in the frontmatter (engine, permissions, safe-outputs caps), recompile:

```bash
gh aw compile
```

Then commit, push, and trigger a fresh run:

```bash
gh aw run issue-triage
```

**Keeping it up to date** (run these every once in a while):

```bash
gh extension upgrade github/gh-aw   # extension itself
gh aw upgrade                       # gh-aw engine
gh aw update                        # update workflows you've added
```

That's the whole loop. (I'm planning to wire this onto a side repo first to see how it behaves on real traffic before turning it loose on anything I care about — that's just basic hygiene with any agent automation.)

## The Big Security Win: No More PAT Required

Now let's talk about the second changelog entry, because this is where things get genuinely better from a security standpoint.

Previously, if you wanted an agentic workflow to interact with your repository — labeling issues, opening pull requests, updating documentation — you needed a **personal access token (PAT)**. That meant creating a long-lived token, storing it as a secret, worrying about rotation policies, and hoping it didn't leak. PATs are powerful, and they're a common target for attackers. (I've seen too many PAT leaks in my time as a consultant, and they're never fun to clean up...)

As of June 11th, **agentic workflows now work with GitHub Actions's built-in `GITHUB_TOKEN`**. No more PAT creation. No more secret rotation. No more long-lived credentials sitting in your repository settings.

When you run an agentic workflow in an organization-owned repository using the Actions token, AI credits consumed by the workflow bill directly to the organization — not to an individual user's Copilot quota. This is a cleaner model, especially at scale.

To enable org billing, you add `copilot-requests: write` to the `permissions` frontmatter in your workflow Markdown file, then recompile and push the updated lockfile. You'll need to upgrade to the latest version of the extension first:

```bash
gh extension upgrade aw
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

If you're already using GitHub Actions and you've been curious about agents, this is a low-friction way to experiment. Install the `gh-aw` extension, grab a prebuilt workflow from the [examples repo](https://github.com/githubnext/agentics), and see what happens.

This is available for all Copilot plans — Free, Pro, Pro+, Business, and Enterprise. So there's no barrier to trying it out.

Have you played with agentic workflows yet? If so, I'd love to hear what you built. Drop me a note!

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
