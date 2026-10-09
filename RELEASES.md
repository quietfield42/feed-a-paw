# Feed-a-Paw: what shipped, and how to get back

The ledger. Newest first. Every row names a FlutterFlow **branch** taken before
the work, which is what to check out to undo it — a branch is a whole project,
so going back to one restores the app exactly as it was.

Nothing here is in a store yet. "Shipped" means **live on the web** at
`spotapaw.github.io/a-paw-apps/feed/`, which is what Ash tests on his phone.

## How to go back

```
flutterflow ai branch checkout <branch>      # the app as it was before that work
flutterflow ai branch checkout main          # back to current
```

Pushing while a branch is checked out writes to that branch, not to main —
check `flutterflow ai branch current` if unsure.

## 9 October 2026

| What | Roll back to |
|---|---|
| A pickup records **which** butcher rather than a retyped name, so `feed_butchers` fills up and two spellings stop being two suppliers | `feed-volunteer-feeds-9oct` |
| A meal handed out **away from the truck** can be recorded at all — the public counter was always designed to include it | `feed-team-gate-9oct`¹ |
| A round follows the route the driver picked, in order, with fed spots ticking off | `feed-team-gate-8oct` |

¹ taken as `feed-volunteer-feeds-9oct`; the volunteer form and the route work
went out together.

## 8 October 2026

| What | Roll back to |
|---|---|
| A signed-in stranger is told they are not on the feeding team, instead of a Start button that silently did nothing | `feed-team-gate-8oct` |
| Three pages that could not scroll now scroll (the stop, the pickup, About) | `feed-team-gate-8oct` |

## Earlier

| When | What | Roll back to |
|---|---|---|
| 3 Oct | the family's bottom bar and the regional look | `before-family-bar-3oct` |

## The rule

Take a branch **before** medium or larger work, not after — a snapshot taken
once the work has started is not a fallback.
