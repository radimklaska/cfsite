# CLAUDE.md

Self-documenting site about how the klaska.net static sites run on Cloudflare
(https://cfsite.klaska.net). The content describes the repository's own setup, so a change
to the setup must update the page that explains it, and the other way round.

## Layout

- `site/` is published as-is (no build). One page per folder (`hosting/index.html` ->
  `/hosting/`), `404.html`, `_redirects`, `style.css`, `favicon.svg`, `robots.txt`.
  The header/nav/footer is repeated in every page on purpose (no build step): change all
  pages together.
- `wrangler.jsonc`: assets-only Worker `cfsite`, custom domain cfsite.klaska.net.
- `.github/workflows/deploy.yml`: production, previews + comment (QR, collapse), visual,
  lighthouse, cleanup. `.github/lighthouse-summary.jq`: Lighthouse job summary.
- `tests/visual.spec.mjs`: preview vs production screenshots; keep the page list complete.
- `scripts/create-deploy-token.sh`: per-repo Cloudflare token -> repo secrets.

## Rules

- Changes go through pull requests. A PR that changes how pages look fails `visual` on
  purpose: check the `visual-diffs` artifact, then merge.
- Keep every tool pinned to an exact version and commit `package-lock.json`.
- Never create a DNS record for cfsite.klaska.net by hand: the deploy creates it.
- Content: plain English, minimal design, no JavaScript, no web fonts. Keep Lighthouse
  accessibility, best practices and SEO at 100.
- Links to repository files use `https://github.com/radimklaska/cfsite/blob/main/...`; the
  link checker fails if the file is not on `main` yet.
- No personal or internal details (private hosts, account IDs, tokens) in the content.
