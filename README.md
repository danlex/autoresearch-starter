# Autoresearch Starter Kit

Autonomous AI research system. Define a subject, run one command, get a verified research document with citations.

## Quick Start

```bash
# 1. Clone this repo (or use "Use this template" on GitHub)
git clone https://github.com/danlex/autoresearch-starter.git
cd autoresearch-starter

# 2. Edit goal.md with your research subject
nano goal.md

# 3. Edit research.config.json with your details
nano research.config.json

# 4. Run setup
bash start.sh

# 5. Start research
NO_JUDGES=1 bash research.sh
```

## What It Does

1. **Generates research questions** from your `goal.md` (30-50 tasks as GitHub Issues)
2. **Researches each question** using Claude Code (web search + write)
3. **Writes findings** with inline `[N]` citations to section files
4. **Three judges review** every finding (Evidence, Consistency, Completeness)
5. **Publishes** a static website with all findings, sources, and progress

## Files You Edit

| File | What to do |
|---|---|
| `goal.md` | Define your research subject, areas of inquiry, and completion criteria |
| `research.config.json` | Your name, company, site URL, accent color, optional timeline/videos |
| `.env` | Your `ANTHROPIC_API_KEY` (created by `start.sh`) |

## Files the System Creates

| File | Purpose |
|---|---|
| `sections/*.md` | Research findings per topic |
| `document.md` | Index with coverage stats |
| `changelog.md` | Research activity log |
| `docs/` | Static website (deploy to GitHub Pages) |

## Commands

```bash
bash start.sh              # One-time setup
bash research.sh           # Run research loop (Ctrl+C to stop)
bash watch.sh              # Monitor progress
bash explode-goal.sh       # Generate more research tasks
bash propose.sh accept     # Accept proposed tasks
bash autoresearch.sh       # Check current score
cd site && npm run dev     # Preview website locally
cd site && npm run build   # Build website
```

## Configuration

### research.config.json

```json
{
  "subject": "Albert Einstein",
  "tagline": "Theoretical physicist and Nobel laureate",
  "image": "subject.jpg",
  "author": {
    "name": "Your Name",
    "company": "Your Company",
    "company_url": "https://example.com",
    "github": "yourusername"
  },
  "repo": "yourusername/your-repo",
  "site_url": "https://yourusername.github.io/your-repo",
  "timeline": [],
  "videos": {}
}
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | required | Your Claude API key |
| `MAX_ITERATIONS` | 100 | Max research iterations per session |
| `NO_JUDGES` | 0 | Set 1 to auto-merge (faster, no review) |
| `AUTO_ACCEPT` | 0 | Auto-accept proposed tasks: `high`, `medium`, `all` |

## Deploy Website

1. Go to repo Settings > Pages > Source: Deploy from branch > `/docs`
2. The site rebuilds automatically after each research iteration

## Built With

- [Claude Code](https://claude.ai/claude-code) — AI research engine
- [Astro](https://astro.build) + [Svelte](https://svelte.dev) + [Tailwind](https://tailwindcss.com) — Website
- GitHub Issues — Task management
- GitHub Pages — Hosting

## Author

Built by [Alexandru DAN](https://github.com/danlex), CEO [TVL Tech](https://www.tvl.tech).
