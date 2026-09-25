# .ffai_staging — scratch sandbox for custom-code iteration

This directory is **gitignored and ephemeral**. Do not put anything here that
needs to persist.

## What belongs here

Candidate Dart files for custom functions/actions/widgets/classes that you
want to validate with `dart analyze` before handing them to the DSL or the
`add*` helpers in `flutterflow_ai`.

## How to use it

1. Write your candidate file to `.ffai_staging/lib/whatever.dart`.
2. Run `dart pub get` inside this directory the first time you add a file
   (picks up `generated_code/` as a path dep so types resolve).
3. Run `dart analyze .ffai_staging/` — fix whatever it flags.
4. When it's clean, read the file contents back out and pass them as the
   `code:` argument to `app.customWidget(...)` / `addCustomAction(...)` /
   etc.
5. Compile + push. Successful `flutterflow ai run` pushes refresh
   `generated_code/` by default, keeping it canonical.

## What NOT to do

- Never write in-progress code into `generated_code/`. That directory is the
  canonical mirror of the pushed project — if it drifts, agents reading it
  for context make wrong decisions.
- Don't commit anything from this directory (it's gitignored).
