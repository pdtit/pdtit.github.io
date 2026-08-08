# Copilot Instructions - PDTIT Public Hugo Site

This public repository contains only the Hugo website and published content.
Private drafts, custom agents, MCP servers, social assets, and authoring scripts
live in the sibling private `pdtit-blog-automation` repository.

## Site conventions

- Published posts: `content/post/<Title With Spaces>.md`
- Post template: `content/post/____Template___.md`
- Images: `content/images/<filename>.png`, referenced as `../images/<filename>.png`
- Theme: Stack
- Live site: https://www.pdtit.be
- GitHub Pages workflow: `.github/workflows/hugo.yml`

Every published post requires `title`, `date`, `publishdate`, `tags`, and
`draft: false` frontmatter. Preserve filename casing and existing tag casing.
Never change `draft: true` to `draft: false` unless Peter explicitly requests
publication.

## Voice and style

Peter's posts are low-key, personal, hands-on, and technically accurate. Use
first person, lead with practical experience, keep parenthetical asides sparse,
and be honest about gotchas and unfinished work. Standard posts are roughly
800-1500 words, but do not pad short topics.

Do not use "delve into", "harness the power of", "unlock the potential",
"in today's fast-paced world", "in the ever-evolving landscape",
"revolutionary", "game-changer", or "paradigm shift". Do not use emojis in
headings.

Every post ends with this exact block:

```markdown
[![BuyMeACoffee](../images/buy_me_a_coffee.png)](https://www.buymeacoffee.com/pdtit)

Cheers!!

/Peter
```

The public Hugo build must remain self-contained and must never depend on files
from the private automation repository.
