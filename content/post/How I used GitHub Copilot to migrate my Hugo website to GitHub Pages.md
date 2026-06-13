---
title: "How I used GitHub Copilot to migrate my Hugo website to GitHub Pages"
date: 2026-06-13
tags: ["Hugo", "GitHub", "GitHub Pages", "GitHub Copilot", "DevOps", "Azure"]
draft: false
---

If you've followed this blog for a while, you know it runs on **[Hugo](https://www.gohugo.io)**, a fantastic static site generator that turns a folder of Markdown files into a fast, fully static website. For the past couple of years that site has been hosted on **Azure Static Web Apps**, with an **Azure DevOps pipeline** doing the heavy lifting of compiling Hugo and publishing the output.

That setup served me well. After migration my old site templates and structure to a new one last February (see:https://www.pdtit.be/post/how-i-used-github-copilot-to-modernize-my-8-year-old-hugo-website/), I now wanted to consolidate everything into a single ecosystem and move the site to **GitHub Pages**, built and deployed by **GitHub Actions**. And because I wanted to see how far the tooling has come, I did the entire migration side-by-side with **GitHub Copilot in agent mode** inside VS Code.

**Apart from moving the site, I also made the decision to decommission the 007FFFLearning.com brand, and go back to the "good-old" pdtit.be" one I had since the early days of the internet in 1996 already.**

This post walks through *why* I made the move, *what* my old setup looked like, the *plan* I followed, and *how* the migration actually went, including the DNS part that always makes people nervous. I'm deliberately keeping it conceptual rather than copy-paste exact, so you can map it to your own site.

Here's the prompt I used:

```
/plan a migration from this repo from azure static webapps with Hugo to a GitHub Pages environment. The goal is to migrate away from Azure hosting, Azure DevOps pipeline for the blog post updates and run everything in GitHub. The new domain name should be www.pdtit.be instead of www.007FFFLearning.com, as a redirection from pdtit.github.io default Pages name. Prepare a migration plan, identify the successes, potential risks and evaluation criteria to move the site.

If a migration is technically possible without losing functionality, highlight the actual steps to migrate, knowing we want a smooth migration with minimal downtime
```

![GitHub Copilot agent mode in VS Code](../images/placeholder-copilot-agent-mode.png)

// change draft: true to false

## 1. Why GitHub Pages for a static site?

A Hugo blog is, by definition, just a pile of static HTML, CSS, JavaScript and images once it's built. You don't need servers, containers, or databases to host it, you only need somewhere that can serve files over HTTPS. That's exactly what **GitHub Pages** does, for free, directly from a repository.

A few reasons it's a great fit:

- **One place for everything.** Your content, your build pipeline, and your hosting all live in the same GitHub repo. No jumping between portals.
- **Build on push.** With **GitHub Actions**, every push to your main branch rebuilds the site and publishes it automatically. Write a post, commit, done.
- **Free TLS and custom domains.** GitHub Pages provisions a certificate for your own domain at no cost and can enforce HTTPS.
- **No build output in source control.** The generated site is produced fresh in CI on every push, so you never have to commit the compiled HTML again.

For a personal blog, this removes a surprising amount of moving parts.

## 2. Where I was coming from (the old setup)

Before the migration, the moving pieces looked like this:

- **Hugo** as the site generator, with content written in Markdown.
- **Azure Static Web Apps** as the host, serving the compiled site and handling TLS for my custom domain.
- An **Azure DevOps pipeline** that triggered on every commit, installed the right Hugo version, built the site, ran a couple of validation checks (more on that later), and deployed it.
- The compiled output and even a copy of the Hugo binary were **committed into the repository**, a habit from earlier days that I wanted to leave behind.

Nothing here was *broken*. But it meant my publishing flow spanned two platforms (Azure DevOps for builds, Azure for hosting), and the repo carried a lot of generated weight it didn't need.

## 3. The migration plan

Rather than diving straight into edits, I asked Copilot Plan mode to help me draft a phased plan first. Having a clear plan up front is what keeps a migration like this calm instead of chaotic. At a high level it broke down into:

**Phase 1 - Prepare the repository.**
Stop committing build output. Add a `.gitignore` for the generated site, the Hugo cache, and any local binaries. Pin the exact Hugo version so local builds and CI builds always match.

**Phase 2 - Recreate the build in GitHub Actions.**
Replace the Azure DevOps pipeline with a GitHub Actions workflow that installs Hugo, builds the site, and deploys it to Pages. Importantly, I carried over the **validation checks** my old pipeline did, things like confirming the search index was generated and that newly added posts actually appear in the output, so I didn't lose that safety net.

**Phase 3 - Publish to GitHub.**
Create the GitHub repository, point the local repo at it, rename the default branch to `main`, and push. Then flip the repo's Pages setting to build from **GitHub Actions**.

**Phase 4 - Custom domain.**
Tell GitHub which domain to serve, update the site's base URL, configure DNS, and enforce HTTPS once the certificate is issued.

**Phase 5 - Redirect the old domain.**
Keep the previous domain alive for a while and forward it to the new one so existing links and search engine results don't break.

**Phase 6 - Decommission the old platform.**
Once the new site is confirmed healthy, retire the Azure DevOps pipeline and the Azure Static Web App.

![The phased migration plan drafted with Copilot](../images/placeholder-migration-plan.png)

Writing the plan down also surfaced the *risks* early, the trickiest being deep links from the old domain and making sure the search feature kept working. Knowing those in advance meant I could check for them deliberately instead of discovering them after go-live.

## 4. How the migration actually went

With the plan agreed, the execution was honestly the easy part, this is where working alongside Copilot in agent mode really paid off. Instead of me hand-editing dozens of files, I described the outcome I wanted and reviewed the changes it proposed.

A few highlights of the actual approach:

**Cleaning up the repo.**
The first win was getting the compiled site and the committed Hugo binaries *out* of version control. Going forward, the build output is regenerated by CI on every push, so the repository only contains what it should: content and configuration.

**A single build-and-deploy workflow.**
The GitHub Actions workflow became the new "engine" of the site, the direct replacement for the old pipeline. On every push to `main` it installs the pinned Hugo version, builds the site, runs the validation checks, and deploys the result to Pages. The very first run going green was the moment I knew the new platform was viable.

![The GitHub Actions build and deploy workflow running green](../images/placeholder-actions-run-green.png)

Check out the actual GitHub Actions YAML if you want:

https://github.com/pdtit/pdtit.github.io/actions/runs/27473418917/workflow



**Fixing up internal links.**
Because the domain was changing, I had Copilot sweep the content for hard-coded absolute links pointing at the old address and make them relative instead. Relative links survive a domain change without any further edits, which is exactly what you want.

**Validating before trusting.**
Before pushing anything live, I rebuilt the site locally from a clean slate and verified the important things: the homepage and posts pointed at the new address, the client-side search index was present and valid, and no stale references lingered in the output. Only then did I publish.

**The DNS part (kept high-level on purpose).**
This is the step people worry about most, but the pattern is well-trodden:

- The **`www` subdomain** gets a **CNAME** pointing at the GitHub Pages host.
- The **root (apex) domain** gets a set of **A records** (and IPv6 `AAAA` records) pointing at GitHub's Pages addresses. GitHub publishes the exact values, you just enter them at your registrar.
- GitHub then automatically redirects the apex to your `www` canonical address.

![The DNS records configured at the registrar](../images/placeholder-dns-records.png)

One gotcha worth calling out: if your registrar had any leftover parking or forwarding records on the apex, remove them, otherwise the certificate can struggle to provision. Once DNS resolved cleanly, GitHub issued the TLS certificate within minutes, and I switched on **Enforce HTTPS**.

**Don't strand the old domain.**
Finally, the previous domain stays alive and forwards to the new one. The key detail is to use a **path-preserving redirect**, so an old deep link to a specific article lands on that same article on the new domain, not just the homepage. That protects your existing readers and your search rankings while everything propagates.

## Wrapping up

The migration itself, prepare, rebuild in Actions, publish, wire up the domain, redirect the old one, was conceptually simple, but having GitHub Copilot do the repetitive editing, validation, and verification turned what could have been a tense weekend into a calm afternoon. The site you're reading this on right now is the result: a Hugo blog, built by GitHub Actions, served from GitHub Pages, on my own domain.

If you're sitting on a static site hosted somewhere heavier than it needs to be, this is a very approachable move, and a great little project to try out agent-mode tooling on a real, low-risk task.

// should always be the last section of the blog

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
