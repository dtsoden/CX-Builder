# Landing page

Source for **https://cx-builder.com**.

Moved here from `iX-Studio/landing` on 2026-07-30, where it was untracked and had no
history. iX-Studio is a separate concept; this page belongs with CX-Builder.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole page. Self-contained apart from Google Fonts. |
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

The live copy is byte-identical to `index.html` here. Whatever hosts cx-builder.com is
not wired to this directory, so publishing is still a manual step: update this file
first, then deploy, so the repository stays the source of truth rather than a copy that
drifts.

## Known cleanups

- The page uses em dashes throughout, including in the `<title>`.
- It says nothing about CX-Builder being independently maintained, which is worth
  considering now that upstream Flowise has been discontinued.
