---
title: "GitHub Agentic Workflows hits public preview — and you can finally drop the PAT"
date: 2026-06-19
publishdate: 2026-06-19
tags: ["GitHub Copilot", "DevOps", "AI"]
draft: false
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

Here's the entire file I will use in my practical example later. One Markdown file, `summarize.md`, that you have to drop into `.github/workflows/`. (DON'T DO THIS YET, JUST SHOWING THE SYNTAX AS ILLUSTRATION...)

````yaml
---
name: Summarize Issue
description: Posts a 3-bullet TL;DR when someone comments /summarize on an issue.

on: /summarize

permissions:
  contents: read
  issues: read
  pull-requests: read
  copilot-requests: write

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

- **Frontmatter = the contract.** `permissions:` says the agent can only *read* issues and repo contents. The `copilot-requests: write` line is the new bit — it lets the workflow's built-in `GITHUB_TOKEN` talk to Copilot's inference API directly, so you don't need a separate personal access token for the engine. `safe-outputs: add-comment: max: 1` declares the *one and only* write action the agent is allowed to take, capped at one comment per run. That's the entire write surface. The agent literally cannot do anything else even if it wanted to.
- **`on: /summarize`** — the slash-prefix shorthand. One line. The `gh-aw` compiler expands this into an `issue_comment` listener that fires whenever someone posts a comment starting with `/summarize` (plus a manual dispatcher you can run from the Actions tab). No webhooks to configure, no separate trigger script.
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

![Initially throwaway repo](../images/2026-06-20_09-04-57.png)


`gh aw init` scaffolds the bits the CLI needs: a `.gitattributes` entry, a `.github/skills/agentic-workflows/` skill folder (so coding agents understand the format), a `.github/agents/agentic-workflows.md` custom-agent file, and an MCP config. Commit it before going further, otherwise the next step will complain about a dirty tree:

```bash
git add -A && git commit -m "chore: gh aw init scaffolding" && git push
```

**Step 3 — Create a blank workflow:**

```bash
gh aw new summarize
```

where summarize reflects the name of the markdown and corresponding yaml workflow file later on.

This creates `.github/workflows/summarize.md` from a template and opens it for editing. (If your editor doesn't pop up, just open the file manually.)

**Step 4 — Replace the template with your own prompt.**

**Wipe the file completely** — the entire frontmatter block *and* the entire body — and paste in the `summarize.md` from the previous section. The single most important line is the trigger:

```yaml
on: /summarize
```

That slash-prefix is what tells `gh-aw` to compile an `issue_comment` listener that responds to `/summarize` comments. 

Make sure the `permissions:` block in your file also includes `copilot-requests: write`. That's the one line that means you *don't* need to set up a separate personal access token for the Copilot engine — the workflow's built-in `GITHUB_TOKEN` will handle both the repo write and the engine call.

**Step 5 — Compile it:**

```bash
gh aw compile summarize
```

![actions workflow gets compiled](../images/2026-06-20_09-07-37.png)


The compiler reads your Markdown file and (re)generates `summarize.lock.yml` — a standard GitHub Actions workflow that does all the plumbing: sets up the agent runtime, wires the slash-command dispatcher, enforces the `safe-outputs` contract, runs the threat-detection job on any proposed comment, and posts it.

One thing that's easy to miss: **`summarize.md` is your only source of truth. Never edit `summarize.lock.yml` by hand.** Every time you change the `.md`, rerun `gh aw compile summarize` to regenerate the lockfile. If you skip the recompile and push, the agent runs whatever was in the last lockfile — not what you just wrote.

**Step 6 — Commit, push, and test it:**

With the new workflow files generated, time to initiate a new commit and push the changes to the repo. 

```bash
git add .github/workflows/summarize.md .github/workflows/summarize.lock.yml
git commit -m "feat: add /summarize agent"
git push
```

![repo ready with all assets](../images/2026-06-20_09-08-22.png)

Next, let's create a sample issue to test the summarize step with. I'm using **gh issue** cli for this, but you can obviously just create a new one from the GitHub Portal, or point to an existing one if you already have some in your test repo. 

**One thing to watch out for:** remember the rule we put in the prompt — *"if the issue has fewer than 3 comments and the body is under 200 words, reply with 'nothing to summarize yet' and stop."* So if you just throw `--body "short test"` at it, the agent will (correctly) refuse to do anything. Give it some actual meat to work with:

```bash
gh issue create --title "Should we move from ARM to Bicep?" --body @- <<'EOF'
We currently have ~140 ARM templates spread across three subscriptions, mostly
hand-written over the last two years. They work, but each new resource type
means another 200-line JSON blob, and our junior engineers consistently
struggle to read them during code review. I've been quietly trialling Bicep
on a couple of side projects and the developer experience is in another
league — modules, type checking, much cleaner diffs in PRs.

The question on the table is whether we commit to migrating now or kick the
can down the road until after the Q3 release. Arguments for moving now:
every new ARM template we write between now and Q3 is one more we'll have to
migrate later, and the team is already going to be heads-down on Q3 features
so the "perfect window" never actually arrives. Arguments for waiting: nobody
on the team has shipped Bicep to production yet, we'd be learning on a
deadline, and `bicep decompile` on our existing templates is going to need
real review afterwards rather than a clean lift-and-shift.

Looking for honest opinions before I take this to the architecture review
next week. Particularly interested in hearing from anyone who has done a
migration of this size on a live workload — what bit you that you didn't
expect?
EOF
```

Seed a couple of comments so the agent has actual discussion to summarize (otherwise it'll just summarize the body, which is less interesting):

```bash
gh issue comment 2 --body "I'm +1 on moving now. The longer we wait the bigger the migration gets. Suggest we pick one non-critical subscription, port it module-by-module over two sprints, and use that as the team's learning vehicle."

gh issue comment 2 --body "Counter-take: don't underestimate \`bicep decompile\` output. I tried it on a 600-line ARM template last month and ended up rewriting roughly 40% of it by hand. The savings are real, but they're not free."
```

Now trigger the agent (update <n> with the actual issue number):

```bash
gh issue comment <n> --body "/summarize"
```

Within seconds, the workflow posts a status comment back on the issue with a direct link to the running Actions job (`gh-aw` does this automatically for slash-command workflows — no need to wire it up yourself). Click through to watch the agent think. About 2 minutes later, the actual TL;DR shows up as a second comment on the issue:

![summarize Actions workflow triggered](../images/2026-06-20_09-13-43.png)

That's the whole loop. **You wrote the prompt. The agent did the action. The contract between them is right there in the same file.**

![Issue gets comment about the summarize flow](../images/2026-06-20_09-44-57.png)

And after about a minute or 2, it provides a summary:

![Summarize step completed](../images/2026-06-20_09-45-56.png)

### What the Actions workflow actually did

If you click through to the Actions run, you'll see something that looks more elaborate than you wrote — six separate jobs, not just "run the agent." That's because `gh aw compile` expands your one Markdown file into a real pipeline with proper guardrails. Worth a quick tour so the run page isn't a black box:

1. **`pre_activation`** — the gatekeeper. Confirms the trigger actually matches (a comment starting with `/summarize`), checks the commenter has permission, and decides whether the workflow should run at all. Cheap, fast, ~10 seconds. Most accidental triggers get rejected here.

![Full workflow view](../images/2026-06-20_09-53-14.png)

2. **`activation`** — the setup. Gathers the context the agent will need (issue body, comment thread, repo metadata), assembles the prompt, and prepares the Copilot inference call.

![Summarize step completed](../images/2026-06-20_09-52-41.png)

3. **`agent`** — the actual reasoning step. This is where Copilot reads your prompt, calls the GitHub tools you allowed (`get_issue`, `get_issue_comments`), and produces a *proposed* output. Nothing is posted yet. This is also the longest-running job — usually 1–2 minutes.

![agentic conversation](../images/2026-06-20_09-53-45.png)

4. **`detection`** — the threat-detection scan. Inspects whatever the agent wants to do for prompt injection, suspicious patterns, or anything outside the `safe-outputs` contract you declared. If something looks off, it gets blocked here before it ever touches the repo.

![Threat detection](../images/2026-06-20_09-54-30.png)


5. **`safe_outputs`** — the writer. Only now does the workflow's `GITHUB_TOKEN` post the comment, and only inside the bounds you set (`add-comment: max: 1`). Even if the agent had wanted to do five things, only the one declared action makes it through.

![Safe Outputs - the write action](../images/2026-06-20_09-54-52.png)


6. **`conclusion`** — the cleanup. Updates the status comment with the final link, uploads artifacts (the agent's logs, the safe-output payload, the detection result), and marks the run complete.

The takeaway: **the agent itself is just one of six jobs.** Everything around it is policy, validation, and audit trail — and you didn't write any of that. The compiler did, based on the `permissions:` and `safe-outputs:` you declared in the frontmatter.

Now let's talk about the second changelog entry, because this is where things get genuinely better from a security standpoint.

Previously, if you wanted an agentic workflow to interact with your repository — labeling issues, opening pull requests, updating documentation — you needed a **personal access token (PAT)** for those write operations. That meant creating a long-lived token with `repo` scope, storing it as a secret, worrying about rotation policies, and hoping it didn't leak. PATs are powerful, and they're a common target for attackers. (I've seen too many PAT leaks in my time as a consultant, and they're never fun to clean up...)

On top of that, the *engine* call — the workflow asking Copilot to actually do the reasoning — needed its own separate `COPILOT_GITHUB_TOKEN` secret. Two long-lived tokens, one for repo writes and one for the engine, just to drop a comment.

As of June 11th, **both of those are gone**. Repo-side writes go through GitHub Actions's built-in `GITHUB_TOKEN` (routed via the `safe-outputs:` pipeline), and the Copilot engine call is now authorized by the same `GITHUB_TOKEN` as soon as you add `copilot-requests: write` to the workflow's `permissions:` block — which is exactly what we did in the sample above.

No more `repo`-scoped PAT. No more `COPILOT_GITHUB_TOKEN` secret. No more secret rotation. No more long-lived credentials sitting in your repository settings just so the workflow can drop a comment. The whole credential dance is replaced by one line in `permissions:`.

This change removes operational friction and reduces the attack surface. It's a solid improvement, and frankly, it should have been like this from the start. But better late than never.

## Security Layers Built In

While already discussed as part of the GitHub Actions stages, GitHub Agentic Workflows also ships with several security safeguards that make me more comfortable trusting an agent to make changes:

- **Integrity filter**: agents access GitHub content respecting defined integrity rules.
- **Read-only by default**: workflows run with read-only permissions unless you explicitly grant write access.
- **Sandboxed execution**: workflows execute inside a container behind the "Agent Workflow Firewall".
- **Safe outputs validation**: outputs are validated before being used.
- **Threat detection job**: scans all proposed changes before they're applied.

These layers matter. Getting an agent to open a pull request was never the hard part — trusting it enough to merge is. GitHub is clearly thinking about this, and the safeguards are a good start.

## Cost Control

Because agentic workflows consume AI credits, GitHub added cost management tools. You can cap token usage per workflow run using the [built-in cost management tools](https://gh.io/gh-aw-cost). If you're using organization billing, you can also configure [cost centers](https://docs.github.com/billing/concepts/cost-centers) to track spend across groups of organizations.

![Token Usage per stage](../images/2026-06-20_09-59-50.png)

This is important. Without guardrails, a runaway workflow could burn through your credits fast. (Ask me how I know... or actually, don't.)

## Summary

GitHub Agentic Workflows is a smart way to automate reasoning-based tasks in your repositories. By letting you define workflows in natural language and compiling them into standard Actions, GitHub has lowered the barrier to building agent-driven automation.

But the real win for me is the PAT removal. Using the built-in `GITHUB_TOKEN` means fewer secrets to manage, fewer rotation headaches, and a smaller attack surface. That alone is worth paying attention to.

If you're already using GitHub Actions and you've been curious about agents, this is a low-friction way to experiment. Install the `gh-aw` extension, write a small Markdown file with a prompt of your own (start with `/summarize` if you want a template), and watch the agent take real actions in your repo. If you want to see what bigger prompts look like once you've got the basics down, there are dozens of more elaborate examples in the [agentics repo](https://github.com/githubnext/agentics).

One thing to know up front: this needs a **paid Copilot plan**. Agentic workflows run on the same engine as Copilot's cloud agent, and that's a Pro-and-above feature — Copilot Free only covers chat and in-IDE agent mode, not server-side automation. So Pro, Pro+, Business, or Enterprise will all work; Free won't.

Have you played with agentic workflows yet? If so, I'd love to hear what you built. Drop me a note!

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
