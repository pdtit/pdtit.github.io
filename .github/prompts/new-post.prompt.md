---
description: "Stamp the blog post template with today's date and open the new draft. Use when starting a post outside the Researcher → Composer workflow (e.g. your own idea you want to draft yourself)."
name: "New blog post"
argument-hint: "Title of the new post (used as filename and frontmatter title)"
agent: "agent"
tools: [read, edit]
---

Create a new Hugo blog post under `content/post/` based on the project template, then open it for editing.

## Inputs

- The user's prompt is the **post title** (e.g. `Using deployment stacks to enforce drift detection`).
- If the user did not give a title, ask once for one and stop.

## Steps

1. Read [the blog template](../../content/post/____Template___.md) to get the exact frontmatter shape.
2. Compute today's date in `YYYY-MM-DD` format (system date).
3. Determine the filename:
   - Use the title **as given** (mixed case, spaces preserved — match the convention of other posts under `content/post/`).
   - Strip any character not valid on Windows (`< > : " / \ | ? *`).
   - File path: `content/post/<Title>.md`.
   - If a file with that name already exists, append ` (2)` and try again. Do not overwrite.
4. Create the file with this exact content (substitute `<Title>` and `<TodaysDate>`):
   ```markdown
   ---
   title: "<Title>"
   date: <TodaysDate>
   publishdate: <TodaysDate>
   tags: ["<tag1>", "<tag2>"]
   draft: true
   ---

   <!-- Hook: short personal opener in Peter's voice. See .github/copilot-instructions.md for style rules. -->

   ## Why this matters

   <!-- 1-2 short paragraphs of context -->

   ## Walkthrough

   1. <step one>

      ![<caption>](../images/TODO-<short-slug>.png)
      <!-- TODO screenshot: what to capture -->

   2. <step two>

   ## Summary

   <!-- key takeaway in 2-3 lines -->

   [![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

   Cheers!!

   /Peter
   ```
5. Reply with a single line: `Draft created: [<Title>](content/post/<Title>.md) — ready to edit.`

## Constraints

- DO NOT write the body. This prompt only scaffolds.
- DO NOT set `draft: false`. The Composer/manual workflow keeps drafts as `draft: true` until Peter flips them.
- DO NOT pick tags blindly — leave `["<tag1>", "<tag2>"]` as a placeholder if the title is ambiguous.
