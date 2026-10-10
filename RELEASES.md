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

## 10 October 2026 — nobody had ever been able to start a round

Found by sweeping for page state that is read but never assigned, after that
fault turned out to be hiding the rescue half of Adopt.

| What | Roll back to |
|---|---|
| **A driver can start a round.** `routes` was never loaded, and tapping a round in that list is the only place in the whole app that sets `currentRunId` — so the page showed "no rounds yet" forever and everything behind it (the places in order, logging a stop, the photos, the summary) was unreachable | `feed-volunteer-feeds-9oct` (9 Oct — the last one taken) |
| The two counters above the list, `stopsToday` and `mealsToday`, read 0 forever; they now come from `feed_run_totals`, which the end-of-round summary was already reading correctly | `feed-volunteer-feeds-9oct` (9 Oct — the last one taken) |
| A round already in progress is picked up again instead of offering to start a second one — `onTheRoad` reset on every open, so a driver whose phone locked came back to the picker and would have orphaned the half-finished run | `feed-volunteer-feeds-9oct` (9 Oct — the last one taken) |

No SQL. `feed_routes` has carried two active rounds, with its grant and its
`feed_is_team()` policy, the whole time.

**No snapshot was taken before this work, which breaks the rule at the bottom
of this page — my fault.** The nearest branch is `feed-volunteer-feeds-9oct`, from 9 October, so going back there also undoes that day's work and the icon pack. So the roll-back column above names the
nearest honest fallback, not a snapshot of the state just before these
changes. A branch of the state *after* them, `feed-driver-fixed-10oct`,
protects the next piece of work but not this one.

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
