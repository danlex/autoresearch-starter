# Autoresearch

Autonomous AI research system. Define a subject, run one command, get a verified research document with inline citations and a published website.

**Live demo:** [danlex.github.io/autoresearch](https://danlex.github.io/autoresearch/) (Andrej Karpathy)

## Install

```bash
git clone https://github.com/danlex/autoresearch-starter.git my-research
cd my-research
bash install.sh
```

The installer handles everything: dependencies (Node.js, GitHub CLI, Claude Code), authentication, task generation, and website build. Works on macOS and Linux.

## How It Works

```
goal.md (you write)
    |
    v
explode-goal.sh --> 30-50 GitHub Issues (research questions)
    |
    v
research.sh --> Claude Code searches the web, writes findings with [N] citations
    |
    v
3 judges --> Evidence, Consistency, Completeness review
    |
    v
PR merged --> website rebuilt --> score climbs toward 100%
```

Every claim has inline citations. Three independent judges review all content. The entire process is transparent on GitHub.

## Quick Reference

| Command | What it does |
|---|---|
| `bash install.sh` | Full setup (deps, auth, tasks, site) |
| `bash research.sh` | Run research loop |
| `bash watch.sh` | Monitor progress |
| `bash autoresearch.sh` | Check score |
| `cd site && npm run dev` | Preview website |
| `Ctrl+C` | Stop research (safe, resumes from where it left off) |

## Configuration

### 1. Research Subject (`goal.md`)

```markdown
# Research Goal: Albert Einstein

## Subject
Albert Einstein — theoretical physicist, Nobel laureate.

## What I Want to Understand
- Scientific contributions and impact
- Education and intellectual development
- Views on philosophy and politics
- Key relationships and collaborations

## Completion Criteria
- Every finding backed by 2+ sources
- All sections at HIGH confidence
```

### 2. Website & Author (`research.config.json`)

```json
{
  "subject": "Albert Einstein",
  "tagline": "Theoretical physicist and Nobel laureate",
  "image": "subject.jpg",
  "author": {
    "name": "Your Name",
    "company": "Your Company",
    "github": "yourusername"
  },
  "repo": "yourusername/your-repo",
  "site_url": "https://yourusername.github.io/your-repo"
}
```

### 3. Environment (`.env`)

| Variable | Default | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | required | Claude API key (or use `CLAUDE_CODE_OAUTH_TOKEN`) |
| `MAX_ITERATIONS` | 100 | Iterations per session |
| `NO_JUDGES` | 0 | `1` = auto-merge (fast), `0` = three-judge review |
| `AUTO_ACCEPT` | 0 | Auto-accept proposed tasks: `high`, `medium`, `all` |

## Deploy Website

1. Push to GitHub
2. Settings > Pages > Source: `/docs` branch `main`
3. Site rebuilds after each research iteration

## Tech Stack

- **Research:** [Claude Code](https://claude.ai/claude-code) CLI (`claude -p`)
- **Website:** [Astro](https://astro.build) + [Svelte](https://svelte.dev) + [Tailwind CSS](https://tailwindcss.com)
- **Tasks:** GitHub Issues with priority labels
- **Hosting:** GitHub Pages (static)
- **Effects:** WebGL particle system, scroll animations, glassmorphism

## Author

Built by [Alexandru DAN](https://github.com/danlex), CEO [TVL Tech](https://www.tvl.tech).

## License

MIT
