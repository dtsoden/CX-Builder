# Landing page

Source for **https://cx-builder.com**.

Moved here from `iX-Studio/landing` on 2026-07-30, where it was untracked and had no
history. iX-Studio is a separate concept; this page belongs with CX-Builder.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole page. Self-contained apart from Google Fonts. |
| `404.html` | Not-found page. Without it Cloudflare Pages serves `index.html` with a 200 for every path, which reads as a soft 404 to crawlers. |
| `sitemap.xml` | Submitted to Google Search Console. |
| `robots.txt` | Points crawlers at the sitemap. |
| `og-image.png` | Social share card, 1200x630. |
| `cx-builder-dark.png` | Logo, 189x51 |
| `cx-avitar-dark.png` | Favicon / avatar, 93x92 |

A `cx-builder-dark.zip` sat alongside these in the old location. It only contained
copies of the three files above, so it was not carried over; git provides the history
a zip snapshot was standing in for. The original is still in `iX-Studio/landing`.

## Links this page depends on

The install commands and the GitHub button point at this repository:

- `https://raw.githubusercontent.com/dtsoden/CX-Builder/master/install.sh`
- `https://raw.githubusercontent.com/dtsoden/CX-Builder/master/install.ps1`
- `https://github.com/dtsoden/cx-builder`

Renaming or moving this repository breaks all three. Check them after any repository
change.

## Deploying

This directory is the source for the maintainer's site at cx-builder.com, which is
hosted on Cloudflare Pages as a direct-upload project. Pushing to GitHub does not
deploy it; publishing is a separate manual step the maintainer runs.

If you forked this project, point `landing/` at your own host and domain, or delete the
directory entirely. Nothing else in the repository depends on it, and it is excluded
from the Docker build.

## Known cleanups

- The page says nothing about CX-Builder being independently maintained, which is
  worth considering now that upstream Flowise has been discontinued.
- Numeric claims (document loaders, LLM integrations, templates) are counted from
  `packages/components/nodes/` and `packages/server/marketplaces/`. Re-check them when
  the base version changes; they were wrong once already.
