---
title: "How I used GitHub Copilot to modernize my 8 year old Hugo website"
date: 2026-02-28
publishdate: 2026-02-28
tags: ["GitHub Copilot", "Hugo"]
draft: false
---

I recently decided to give my 8 year old Hugo website a serious refresh. The trigger was simple: I still used the first Hugo theme I picked up 8 years ago, some content menu options didn't actually do anything or were no longer relevant. Then I also had screenshots and other image files all over the place (5 different folder locations, duplicate image file names and alike). 

Instead of doing this modernization and cleanup manually over a few weekends, I used **GitHub Copilot** as an active engineering partner to accelerate the full modernization journey.

## Where it started: search was broken in production

The first issue looked small, but it exposed deeper reliability problems:

- The search JSON endpoint existed
- The `/search/` page in production was effectively empty
- The pipeline still reported success

So this wasn’t a single typo. It was a classic “green pipeline, broken runtime behavior” scenario.

With Copilot, I moved from guessing to structured troubleshooting:

1. Validate generated Hugo output
2. Compare source routing/content metadata with deployed artifacts
3. Harden the pipeline to fail fast when critical pages are missing

That immediately changed the workflow from reactive debugging to proactive validation.

## Copilot helped me modernize beyond just the bug

Once search was fixed, I used the same momentum to clean up years of accumulated content and asset drift.

### 1) Build and deployment reliability

I updated the Azure Static Web Apps pipeline to be more explicit and defensive:

- Build validation checks for critical output files
- Safer prebuilt artifact deployment behavior
- Better guardrails so partial site generation doesn’t silently pass

Result: deployment confidence went up significantly.
### 1) Build and deployment reliability

I updated the Azure Static Web Apps pipeline to be more explicit and defensive:

```yaml
trigger:
    - main

pool:
    vmImage: 'ubuntu-latest'

steps:
    - task: UseHugoExtended@1
        inputs:
            version: 'latest'
    
    - script: hugo --minify
        displayName: 'Build Hugo site'
    
    # 🛡️ GUARDRAIL: Validate critical output files exist
    - script: |
            if [ ! -f "public/search/index.json" ]; then
                echo "ERROR: Search JSON endpoint missing!"
                exit 1
            fi
            if [ ! -f "public/index.html" ]; then
                echo "ERROR: Homepage not generated!"
                exit 1
            fi
        displayName: 'Validate critical pages exist'
    
    # 🛡️ GUARDRAIL: Check for empty or malformed search index
    - script: |
            SIZE=$(wc -c < public/search/index.json)
            if [ $SIZE -lt 100 ]; then
                echo "ERROR: Search index is suspiciously small ($SIZE bytes)!"
                exit 1
            fi
        displayName: 'Validate search index integrity'
    
    # 🛡️ GUARDRAIL: Verify content pages were generated
    - script: |
            COUNT=$(find public -name "index.html" -type f | wc -l)
            if [ $COUNT -lt 10 ]; then
                echo "WARNING: Only $COUNT pages generated (expected more)"
                exit 1
            fi
        displayName: 'Verify minimum content threshold'
    
    - task: PublishBuildArtifacts@1
        inputs:
            pathToPublish: 'public'
            artifactName: 'hugo-site'
        displayName: 'Publish build artifacts'
    
    - task: AzureStaticWebApp@0
        inputs:
            azure_static_web_apps_api_token: $(AZURE_STATIC_WEB_APPS_TOKEN)
            repo_token: $(GITHUB_TOKEN)
            action: 'upload'
            app_location: 'public'
        displayName: 'Deploy to Azure Static Web Apps'
```

**Key safety improvements:**
- ✅ Explicit validation that search index exists and has realistic content
- ✅ Minimum page count check to catch silent generation failures
- ✅ Pipeline fails fast instead of deploying broken output
- ✅ Clear error messages for debugging

Result: deployment confidence went up significantly.

### 2) Content architecture cleanup

Over time, I had duplicate and legacy routes (especially around books and videos). Copilot helped audit what was truly used versus what was just historical baggage.

I then:

- Redesigned the Books page into a cleaner 2-column layout (cover + title/description)
- Removed duplicate `publications` pages where canonical pages already existed
- Reviewed and cleaned aliases to keep routing intentional

Result: fewer moving parts and clearer content ownership.

### 3) Image and asset governance

This was the biggest hidden technical debt.

I had images spread across multiple legacy folders with overlapping filenames. That made reference checks noisy and risky. Copilot helped me run source-scoped audits, identify true usage, and avoid false positives from generated output.

I used that to:

- Move post-related images into `content/post/images`
- Rewrite Markdown links in affected posts
- Handle filename collisions safely
- Remove unused files/folders only after reference validation

Result: cleaner repository, fewer dead assets, and lower risk of accidental content breakage.

## What I liked most about using Copilot on an older codebase

The biggest value wasn’t “AI wrote code for me.” It was this:

- Faster root-cause analysis
- Safer bulk refactoring with validation checkpoints
- Less context switching for repetitive search/update tasks
- Better confidence to remove legacy clutter without fear

For old websites, this matters a lot. Most of the work is not feature development — it’s careful archaeology.

## Practical lessons if you want to modernize your own Hugo site

If your site is aging and you don’t know where to start, this sequence worked very well for me:

1. Fix one visible production issue first (high leverage)
2. Add pipeline checks for critical pages/artifacts
3. Identify canonical routes and remove duplicates
4. Consolidate assets by usage domain (e.g., post images)
5. Delete only after source-level reference validation

Small, verified steps beat one giant risky migration every time.

## Final thoughts

This modernization started as a broken search page after switching to a new Hugo theme and ended as a full site health upgrade and removal of technical debt.

GitHub Copilot didn’t replace engineering judgment — it amplified it. For me, that was the real win: I could move faster **and** be more careful at the same time.

If you have an older Hugo site (or any long-running static site), this is absolutely worth doing.

By the way, this whole process took less than 2 hours, and about 20 prompts in a continuous conversational approach. Are you a fan of GitHub Copilot? Let me know what your coolest use case has been so far!

[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
