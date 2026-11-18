# cfsite

How Radim Klaška's static sites are hosted on Cloudflare, published at
**https://cfsite.klaska.net**, and built exactly the way it describes. It is also the
template for a new site (see [New site](https://cfsite.klaska.net/new-site/)).

## Hosting

- Cloudflare Worker `cfsite`, static assets only, on the custom domain
  cfsite.klaska.net (`wrangler.jsonc`). Publishes `site/`; nothing to build.
- Cloudflare creates the DNS record and certificate on deploy. Never create a DNS record
  for the hostname by hand: the deploy refuses to replace one (error 100117).
- Analytics: Cloudflare Web Analytics, added by the klaska.net zone (no tag in the code).

## Deploys and previews (`.github/workflows/deploy.yml`)

- Push to `main` (or run the workflow by hand): production.
- Pull request: a Workers Preview `pr-<N>`, a new comment per deploy with the preview
  URL, this commit's URL, the run, a QR code and Lighthouse scores; older preview comments
  are collapsed. Jobs `visual` (screenshots vs production; `tests/visual-report.mjs` makes
  the diffs page) and `lighthouse`; job `comment` writes both results into the comment.
- Pull request closed: the preview is deleted and the comments collapsed.
- Also: `link-checker.yml` (lychee), `claude-code-review.yml` and `claude.yml`.

## Secrets

- `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`: created by
  `scripts/create-deploy-token.sh cfsite` (least privilege, one year).
- `CLAUDE_CODE_OAUTH_TOKEN`: for the Claude workflows (`/install-github-app` in Claude Code).

## Local

```sh
npm ci
npx wrangler dev                                   # http://localhost:8787, with 404 + redirects
PREVIEW_URL=http://localhost:8787 npx playwright test   # visual test against production
```
