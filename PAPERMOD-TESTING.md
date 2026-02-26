# Testing PaperMod Theme

## Quick Start Commands

### Test PaperMod Theme
```powershell
hugo server --config config-papermod.toml -D
```
Then open: http://localhost:1313

### Revert to CleanWhite Theme
```powershell
hugo server --config config.toml -D
```
Then open: http://localhost:1313

### Compare Side-by-Side
Open two browser windows and run each command in separate terminals.

## What's Been Set Up

✅ PaperMod theme cloned to `themes/PaperMod/`
✅ New config file: `config-papermod.toml` (your current config.toml is untouched)
✅ All your settings migrated:
  - Social links (Twitter, LinkedIn, GitHub, email)
  - Azure blue accent color (#007FFF)
  - App Insights key
  - Menu items (Posts, Books, About, Tags)
  - Pagination (10 posts)
  - Syntax highlighting (Dracula theme)

✅ New PaperMod features enabled:
  - Light/Dark mode toggle
  - Reading time estimates
  - Share buttons
  - Code copy buttons
  - Better mobile experience
  - Search functionality

## To Deploy PaperMod

If you like it and want to deploy:

1. Rename files:
   ```powershell
   mv config.toml config-cleanwhite.toml.backup
   mv config-papermod.toml config.toml
   ```

2. Update pipeline (no changes needed - it will use config.toml automatically)

3. Commit and push

## To Keep CleanWhite

Simply delete:
- `themes/PaperMod/` folder
- `config-papermod.toml` file
- `content/search.md` file

Your original setup remains in `config.toml` and `themes/cleanwhite/`
