# FlutterFlow AI Workspace

<!-- ff:project-identity:start -->
## Project

- **Name:** Feed a Paw
- **Project ID:** `feeda-paw-hc0hpt`
- **Environment:** prod
<!-- ff:project-identity:end -->


FlutterFlow AI is a local workspace for creating and editing FlutterFlow apps with a coding agent.

This workspace's project identity (name, ID, environment) and typed-SDK guide live in @PROJECT_CONTEXT.md.

## Files

- `dsl/create.dart`
- `dsl/edit.dart`
- `test/app_test.dart`
- `references/`
- `patterns/`
- `lib/flutterflow_project.dart` — generated typed project SDK barrel. Import it as `ff` in edit flows. The actual content is split across per-entity files under `lib/flutterflow_project/` (one file per page in `pages/`, one per component in `components/`, plus `schemas.dart`, `app_state.dart`, `apis.dart`, `theme.dart`). The barrel re-exports everything, so user code keeps `import '.../flutterflow_project.dart' as ff;` — to read a specific page's tree, jump directly into its file.
- `PROJECT_CONTEXT.md` — tiny onboarding pointer to the typed SDK for project-bound workspaces.
- `generated_code/` — read-only snapshot of the Flutter code FlutterFlow generates from the project. Manifest at `generated_code/.flutterflow/export_manifest.json` maps each entity (page, component, action block, etc.) to its `primary_files`. Use this when debugging visual or runtime bugs the DSL alone cannot explain (overflow, layout, render errors, build failures).
- `.flutterflow/` (SDK-managed: run history, traces, workspace state, plus router config)

## MCP tool profile

`full` advertises every MCP tool. `core` advertises `init`, `status`, `orient`, `docs`, `search`, `inspect`, `run`, `validate`, `patch`, `list_props`, `history`, `resources`, `mock_backend`, and `capabilities`.

In `core`, call `capabilities` for deferred tool routes and CLI equivalents; use `--profile full` or unset `FF_AI_MCP_PROFILE` to expose them.

The SDK source under `.flutterflow/sdk` is not documentation; never grep or read it. Use `docs grep`, `docs symbol`, `docs search`.

When the agent tool interface supports multiple calls in one response, issue independent file reads and `docs` lookups together in one turn.

## Workflow

Unless an authoritative selector or the request says otherwise, call `flutterflow ai orient --full` (or MCP `orient` with `full: true`) once at the start. It includes schemas, app state, every page/component handle and file state, and relevant recipes; do not sweep schema or page files. Trust its edit-lane recommendation unless the request requires another lane.

Once the core requirement compiles, validates, and passes introduced-only preflight, push now, then refine and push again if needed; the final push is what counts, and an unpushed workspace at the end delivers nothing.

Aim for a first pushed version within 10 minutes of work and finish within 20; after the first push, spend at most one more iteration on polish. If the third attempt at the same script still fails, change approach: read `docs symbol <failing-member>`, use a recipe, or narrow the change instead of repeating the same edit.

After two identical server errors on the same raw-proto path, stop retrying that path; switch to a supported typed form or report the unsupported gap in the final message.
After two consecutive "No changes detected" probe runs, stop probing with scripts; use `inspect --node <key> --raw --output <file>` to explore the current representation. DSL script execution has a 30-second wall budget.
Before replacing existing code with replaceCode or a new custom widget, read its current implementation and preserve behavior outside the requested change.

### Selector-first edit workflow

If the user pasted a `FlutterFlow AI Selector v1` block, use it before any broad page/component inspection:

**Widget references (`[#N]`).** Context attached from the IDE ("Add Widget to Context") arrives as inline references like `[#1]`, `[#2]` in the prose, with the full selector blocks collected in a trailing `Context:` footer — each headed by `[#N] Name (Type)`. Resolve every `[#N]` to its block in that footer and treat it as the widget the user means. A message that carries these references (or a raw selector block) **together with any instruction is an actionable request about those widgets** — act on it; do not reply "No response requested".

1. Parse the pasted block for `project_id`, `scope_kind`, `scope_name`, `selector_path`, `node_key`, `node_name`, and `node_type`.
2. **If the request is a fast-lane property edit** (see "Fast-lane patch" below): call `flutterflow_ai__patch` NOW with the block's `node_key` and `node_type` — no inspect first. The block is authoritative; the patch tool itself verifies the node and returns a structured error if the key or type is stale, and only THEN is an inspect warranted. An inspect "to be safe" before a fast-lane patch adds 10-60 seconds (and on some machines times out) for information the block already gave you.
3. Otherwise, resolve the target with `flutterflow ai inspect <project_id> --page|--component <scope_name> --selector-path <selector_path> --dsl-json` and verify the returned `node_type` and `node_name` match the pasted block.
4. **If the user is reporting a visual or runtime bug** (overflow, layout, render error, exception, "looks wrong" / "doesn't fit"): before authoring the patch, read the generated Dart for the selector's scope.
   - Look up the entity in `generated_code/.flutterflow/export_manifest.json` by `name == scope_name` (or `key == node_key`).
   - Read its `primary_files` to see the actual widget tree, constraints, and styling Flutter is rendering.
   - The DSL is intent; the generated code is what is actually running. Overflow, an unbounded `Column` inside a `Row`, fixed sizes vs. `Expanded`, etc. are only visible there.
   - If `generated_code/` is missing or stale (`flutterflow ai codegen status` reports `stale`/`missing`), run `flutterflow ai codegen refresh` first.
5. Author the patch in `dsl/edit.dart` through the generated typed widget tree:
   ```dart
   import 'package:<workspace>/flutterflow_project.dart' as ff;

   app.editPage(ff.Pages.homePage, (page) {
     page.find(
       ff.Pages.homePage.widgets.byPath('PageName.body[0].children[1]').single,
     ).update((patch) {
       // ...
     });
   });
   ```
6. Apply and verify the change. Run `flutterflow ai run <script> --dry-run` once, fix every reported error, then run `flutterflow ai run <script>` to push. Read every `compileDslApp` task note in the result. Finally, **verify the outcome** by re-reading the edited page or component through its typed handles, or through the bounded `flutterflow ai inspect <project-id> --page|--component <scope-name>` outline. Confirm the requested elements, bindings, and actions are present; finish only then.
7. If `--selector-path` fails, fall back to `--selector-key` with the `node_key` from the block.
8. Only do a broad `flutterflow ai inspect --page/--component` pass when the selector is stale or missing. That default is a bounded outline; use `--node <key>` for one subtree, `--tree` for the full page view, or `--dsl-json` for the machine-readable snapshot.

### General workflow

1. Use the recipes listed by the initial full orientation; call `flutterflow ai docs recipe <name>` (MCP `docs` with `recipe`) for the closest shape.
2. Open only the recommended editable file. Use `inspect --node`, `--tree`, `--dsl-json`, or `--schema` only to drill into detail absent from the full orientation.
3. Edit `dsl/create.dart` or `dsl/edit.dart`; never write `const` in DSL scripts because DSL values are built at run time. Change only `buildEditFlow` (or `buildCreateFlow`) with the `Edit` tool.
4. Edit `test/app_test.dart` only for greenfield `dsl/create.dart` work when the request asks for tests or adds behavior worth a durable test. Never update it to mirror an existing-project edit. `flutterflow ai test` remains an optional `dart test` wrapper; tests never block a push.
5. Run `flutterflow ai run <script> --dry-run` once and fix all reported errors.
6. **Execute the push** — this is NOT optional. `flutterflow ai run <script>` validates and pushes; iterate until it succeeds. Always include `--commit-message` with a short description of what changed:
   - **Create:** `flutterflow ai run dsl/create.dart --project-name "<name>" --commit-message "<what the app does>"`
   - **Edit:** `flutterflow ai run dsl/edit.dart --project-id "<id>" --commit-message "<what changed>"`
   - Use `--find-or-create` only as a retry/recovery option when a previous create run may already have created the remote project but the local workspace is not bound yet.
   - If the workspace is already bound to a project in `.flutterflow/workspace.json`, FlutterFlow AI will refuse plain create mode by default. Use `--allow-new-project` only when you intentionally want a second project from the same workspace.
7. **Verify the outcome after the push.** Read every `compileDslApp` task note; re-inspect only what changed with `--node <key>` for one widget/action or `--page <name> --dsl` for structure. Confirm the requested elements, bindings, and actions. Use `flutterflow ai review <project-id>` for a whole-project wiring audit; pushes preflight only touched entities. Run `flutterflow ai test` only if requested or `test/app_test.dart` changed. Preserve unrelated behavior and finish after this check.
8. Successful `flutterflow ai run` pushes refresh `lib/flutterflow_project.dart` automatically. Run `flutterflow ai refresh-context <project-id>` after remote changes made outside this workspace.

### When to use `flutterflow ai validate`

Use `flutterflow ai run <file> --dry-run` for authoring verification; reserve `validate <file>` for CI, where unchanged successful files are skipped by content hash.

### Verification

Before concluding that no change is needed, run `flutterflow ai inspect --node <key>` on the surface named in the request and quote the action chain that implements it; wiring on another node does not satisfy that surface.

### Fast-lane patch (`flutterflow_ai__patch` MCP tool) — MANDATORY for property edits

**REQUIRED FIRST ATTEMPT**: If the user's request can be expressed as "set property P on existing widget W to literal value V", you MUST call the `flutterflow_ai__patch` MCP tool **before** considering `flutterflow ai run`. This is not optional — the fast lane lands the edit on the FF backend in ~30s versus 2+ minutes for the slow path. Going to slow-path-first burns ~90 extra seconds of the user's time on every trivial edit.

**Full reference**: `flutterflow ai docs fast-lane` — auto-generated from the live `kFastPatchOps` table. Always current with the SDK. Read this when you're unsure whether an op exists or what its value shape is.

The decision rule:
- "change this text", "make this color X", "set fontSize to N", "hide this widget", "fade this to 50% opacity" on an EXISTING widget → **fast lane (`flutterflow_ai__patch`)**, no exceptions.
- Anything that requires writing or reading Dart, mutating the tree shape, or wiring action chains → slow path (`flutterflow ai run`).

**Mandatory first-attempt criteria** (use fast lane if ALL apply):
- The target already exists (you have its handle in `lib/flutterflow_project/`, or you're tweaking a project-level setting like dark mode / fonts)
- The change is one of the ~100 ops in the fast-patch table (see "Op surface" below) — when in doubt, try it; the tool returns a structured `invalid_request` error listing valid ops if you guessed wrong, which is still cheaper than the slow path
- The value is a literal (a string, a number, a bool, a theme-token name, or an ARGB int) — NOT a variable/state/API/conditional binding

**When to fall back to `flutterflow ai run`** (slow path):
- The fast lane returned `error_kind: invalid_request` and the error message says the op isn't supported. Don't retry — switch to `run` immediately.
- The change is structural (insert/remove/move widgets, wrap/unwrap, change widget type)
- Custom code (functions, actions, widgets, classes, enums)
- Action wiring (onTap → Navigate, action chains, triggers)
- Binding a property to a variable / state / API response / conditional
- App-state field declarations, custom constants, API config, pub dependencies (use slow path)

**Disallowed pattern**: editing `dsl/edit.dart` with `page.update(widget, (patch) { patch.color(...); patch.fontSize(...); })` and running `flutterflow ai run` for a request that matches the fast-lane criteria above. Doing this slows the user down by ~90 seconds for no gain. If the fast lane fits, use the fast lane.

**How to invoke (call shape):**
```
flutterflow_ai__patch({
  project_id: <id>,
  commit_message: '<op summary>',
  node_key: ff.pages.Home.widgets.welcomeTitle.key,
  widget_type: ff.pages.Home.widgets.welcomeTitle.type,
  patches: [
    { op: 'text', value: 'Hello, World' },
    { op: 'color', value: { token: 'primary' } },
  ],
})
```

`node_key` and `widget_type` are both available on every typed SDK widget handle (no discovery query needed). The `ProjectWidgetHandle.fastPatch(...)` helper returns the right `{node_key, widget_type, patches}` shape ready to pass to the tool.

**CAS / `parent_updated_at_ms` is automatic** — the SDK client caches the project's updated_at_ms after every patch and re-fetches transparently on a 409. Agents do NOT pass it. The tool's input schema lists it as optional only for the rare case where you want to force a specific CAS check.

**Context auto-refreshes after every fast-patch** — both `lib/flutterflow_project/` (typed SDK, completes in seconds) AND `generated_code/` (full Flutter snapshot, can take 10–30s) are regenerated in the background. The patch response returns to you in ~30s; by the time you make the next prompt, the typed SDK is fresh and `generated_code/` is either fresh or refreshing. Don't call `flutterflow ai refresh-context` / `flutterflow ai codegen refresh` manually for fast-patch flows — they'd duplicate the background work.

**Colors:**
- Theme slot: `{ op: 'set', prop: 'color', value: 'primary' }`. Valid slots: `primary`, `secondary`, `tertiary`, `alternate`, `primaryBackground`, `secondaryBackground`, `primaryText`, `secondaryText`, `accent1`–`accent4`, `success`, `warning`, `error`, `info`.
- Literal: `{ op: 'set', prop: 'color', value: '#E91E63' }` (also `#AARRGGBB` or `{ argb: 0xFFE91E63 }`).
- The named `color` / `colorArgb` ops are the older spelling and work on the widgets listed for them in `flutterflow ai docs fast-lane`. `set` reaches colors those two never covered — an AppBar or Scaffold `backgroundColor`, a TabBar's, a Tooltip's. Use the property name, not the widget-specific op, when you're not sure.

**Two ways to name the edit — prefer `set`:**
- `{ op: 'set', prop: '<name>', value: <v> }` covers **every literal-valued property of the widget**, including nested ones (`title.fontSize`, `toolbarHeight.pixels`). Call the `flutterflow_ai__list_props` MCP tool with a `widget_type` (and optionally `filter: 'color'`) to see the exact names — they mirror the IDE labels. This is the surface to reach for by default: if `list_props` shows the property, the fast lane can write it.
- Named ops (`text`, `color`, `fontSize`, `visible`, `opacity`, …) are shorthands for the most common edits and emit an identical update. App-scoped ops (`darkMode`, `primaryFont`, `secondaryFont`) need no `node_key` and have no `set` equivalent.

**Don't enumerate either surface from memory.** `flutterflow ai docs fast-lane` is generated from the live tables and lists both, with exact counts. `list_props` answers "what can I set on this widget" in one call, which is almost always the question.

**When in doubt, try the fast lane first.** A wrong op name returns `invalid_request` in <500ms with a list of valid ops; the slow path takes 2+ minutes whether the op exists or not. The cost of a wrong fast-lane guess is one extra round-trip; the cost of defaulting to slow path is the full 2+ minutes.

**Failure modes** — the tool returns a structured `error_kind`:
- `invalid_request`: malformed op, unknown widget type, or op not valid for this widget type. Fix the args and retry.
- `cas_conflict`: the project changed underneath you AND the client's transparent retry also lost the race. Rare. Just re-run the tool — the SDK client refreshes its CAS cache on every 409, so a fresh call picks up the new server state.
- `fast_lane_disabled`: server kill switch is on. Use `flutterflow ai run` instead.
- `server_error`: anything else. Fall back to slow path.

After a successful fast-patch, the backend proto is updated and the workspace's `lib/flutterflow_project/` (typed SDK) plus `generated_code/` (full Flutter snapshot) are refreshed in the background. The patch tool returns immediately; by your next prompt the typed SDK is fresh and `generated_code/` is fresh-or-soon. Only run `flutterflow ai refresh-context` manually if you made a structural change via `flutterflow ai run` and need fresh handles right now.

## Design & Quality Rules

These rules are **mandatory for every create and edit script**. Quick summary; read `flutterflow ai docs design-quality` for the full reference.

- **Theme first** — set up `app.themeColor(...)`, `app.typography(...)`, and design tokens before building UI; bind widgets to `Colors.primary` / `Colors.secondaryText` / etc. for cohesion. **Scope colors correctly:** widget-specific color requests → `Colors.hex(...)` on the node; brand/app-wide requests → `app.themeColor(...)`.
- **Components for reuse** — extract any repeated subtree into `app.component()` with typed `params:`.
- **Default values on params** — give every `app.page`/`app.component` param a `.withDefault(...)` unless every call site provably supplies a non-null value. Required page params crash on cold-entry deep links.
- **Descriptions everywhere** — pass `description:` on `app.page/component/actionBlock/collection/table/event/customFunction`. Short, clear text — it shows up in the FF editor.
- **Visual quality** — size buttons with `width`/`padding`/`borderRadius`/`color`; use `Container` for cards; `spacing:` on `Column`/`Row`; `Styles.titleLarge` etc. for text hierarchy; `maxLines:` + `TextOverflow.ellipsis` on overflow-prone text; explicit size on `ProgressBar.circular`; avoid `shrinkWrap: true` on dynamic `ListView`.
- **Action outputs** — output variable names must be unique across *every* widget and trigger on a page/component (FlutterFlow validator rule). In greenfield bodies and brownfield edits the compiler renames a reused name (`loadedTasks` → `loadedTasks2`) and reports it; `ActionOutput('loadedTasks')` in that chain still resolves. Replacing a node's own chain preserves its current name, while a `Checkbox`/`Toggle` `onChanged` chain still counts twice (toggle-on and toggle-off).
- **DSL ↔ Flutter drift** — a handful of widgets/props differ from Flutter (no `Center`, no `GestureDetector`, `Shadow(dx:, dy:)` not `Offset`, `Param(...)` not `ComponentParam(...)`, etc.). See the docs for the full drift table; check `references/` when a Flutter-shaped symbol fails to compile.

## Create → Edit Transition

**IMPORTANT:** Create scripts (`dsl/create.dart`) are one-shot — they create pages and components from scratch. You **cannot** re-run a create script against the same project; it will fail with duplicate-name errors.

After the first successful create push:
1. The project now exists. Read `projectId` from `.flutterflow/workspace.json`.
2. If `flutterflow` CLI is available, FlutterFlow AI also exports a local Flutter snapshot into `generated_code/`.
3. `flutterflow ai init --project <id>` and successful `flutterflow ai run` pushes keep `lib/flutterflow_project.dart` current for work done in this workspace.
4. For all subsequent edits, use **edit flows** in `dsl/edit.dart` with `--project-id "<id>"`.
5. Use `lib/flutterflow_project.dart` (the barrel) to understand the current page/component structure before editing — or jump straight into `lib/flutterflow_project/pages/<slug>.dart` for a specific page's typed tree. `flutterflow ai inspect <project-id> --page <PageName>` returns a bounded outline; use `--node <key>` for one subtree, `--tree` for the full page view, or `--dsl-json` for the machine-readable snapshot.
6. Read `references/taskboard_dsl.dart` or other edit references for patterns.
7. After later pushes, `lib/flutterflow_project.dart` is regenerated and `generated_code/` is re-exported when refresh is enabled. If a push leaves the snapshot stale (codegen skipped or the export failed), run `flutterflow ai codegen refresh`.

Do NOT modify and re-run `dsl/create.dart` to make changes to an existing project.
Do NOT switch back to `--project-name` in a bound workspace unless you intentionally want a separate project and pass `--allow-new-project`.

## Edit Context

- `flutterflow ai init --project <id>` creates a project-bound workspace and writes `lib/flutterflow_project.dart` when credentials are available.
- When available, `flutterflow ai init --project <id>` also exports a local Flutter snapshot into `generated_code/`.
- `lib/flutterflow_project.dart` is the **authoring and inspection map** (a thin barrel; the content lives in per-entity files under `lib/flutterflow_project/`). Import the barrel as `ff` and prefer `ff.Pages.*`, `ff.Components.*`, `ff.Collections.*`, `ff.Tables.*`, `ff.AppState.*`, and widget handles over raw strings. For a single page or component, navigate into its per-entity file (`lib/flutterflow_project/pages/<slug>.dart`, `lib/flutterflow_project/components/<slug>.dart`) rather than scrolling the barrel.
- `generated_code/` is the **runtime truth**. The DSL describes intent; the generated Dart is what Flutter actually builds and renders. Read it whenever you need to reason about layout, sizing, overflow, render exceptions, build errors, or any "why does the rendered app look or behave like this" question — these are not answerable from the DSL alone.
- Use the manifest at `generated_code/.flutterflow/export_manifest.json` to jump directly from an entity (page, component, action block) to its `primary_files`. Look up by `name` (matches the selector's `scope_name`) or `key` (matches `node_key`). Do not grep for files when the manifest exists.
- Treat `generated_code/` as read-only. Do NOT edit files there directly — make changes in `dsl/edit.dart` or other FlutterFlow AI-managed source, then push through `flutterflow ai run`.
- If a task starts from a generated Dart file, identify the corresponding page, component, or resource from that file and apply the change through FlutterFlow AI rather than patching the generated output.
- Successful `flutterflow ai run` pushes refresh `lib/flutterflow_project.dart` automatically and refresh `generated_code/` by default. If codegen is skipped or the export fails, the generated-code snapshot is marked stale and `flutterflow ai codegen status` / `codegen refresh` apply.
- `flutterflow ai refresh-context <project-id>` rewrites `lib/flutterflow_project.dart` **and** re-exports `generated_code/` after meaningful remote changes made outside this workspace.
- Run `flutterflow ai context-check` to verify whether generated typed SDK metadata is still fresh.
- **Do NOT use `flutterflow ai inspect <id> --dsl-json` for general discovery.** Read `lib/flutterflow_project.dart` (or, for surgical reads of a single entity, `lib/flutterflow_project/pages/<slug>.dart` / `components/<slug>.dart`) instead — every page, component, collection, table, app-state field, and widget selector lives there as a typed handle. `inspect --dsl-json` is reserved for two narrow cases: (1) resolving a pasted FlutterFlow AI Selector v1 block via `--selector-path` (see the selector workflow above), and (2) explicit debug/export when the typed SDK genuinely doesn't carry what you need (e.g. raw FFNode shape). For human-readable discovery, a page/component-scoped plain inspect is a bounded outline (default depth 4); follow a returned handle with `--node <key>`, use `--tree` only for the full page view, or reach for `flutterflow ai resources <id>`.

## Edit APIs for Existing Resources

Quick summary; read `flutterflow ai docs edit-apis` for the full reference with code samples.

- **Typed handles** — use `ff.Collections.*`, `ff.Components.*`, `ff.Pages.*`, `ff.AppState.*` from `lib/flutterflow_project.dart` everywhere. Raw `app.existing*` helpers were removed.
- **Component instances** — `ff.Components.tripCard(title: ...)`. `name:` and `visible:` are reserved on every component call (don't declare params with those names).
- **Component param binding** — `page.setComponentParam(selection, 'paramName', expr)`.
- **Page-load actions** — `app.editPageOnLoad(ff.Pages.myPage, [...])`.
- **Idempotent creation** — `app.ensurePage(...)`, `app.ensureFirebaseAuth(...)` no-op if already present.
- **Page metadata** — use brownfield helpers: `setPageRoute`, `setPageRequiresAuth`, `updatePage`. Do NOT touch `routePath` on `ensurePageRouteSettings()` directly (skips normalization).
- **Removing entities** — `app.removePage/Component/Collection/Table/DataStruct/Enum/ActionBlock/AppEvent/CustomFunction/CustomAction/CustomWidget/SpacingToken/RadiusToken/ShadowToken`. Fails loudly if the name is also declared in the same App. There is no `app.removeProject(...)`.
- **Edit property patches** — `page.update(selection, (patch) { ... })` exposes typed methods on `EditWidgetPatch` (`text`, `color`, `visible`, `spacing`, `padding`, `borderRadius`, `size`, `icon`, `margin`, `alignment`, `border`, `shadow`, `opacity`, etc.). Escape hatch: `page.mutateNode(selection, (node) { ... })`.

## Runtime Artifacts

- `.flutterflow/runs.jsonl`: local run history
- `.flutterflow/history/<run-id>/`: archived source files and plan
- `.flutterflow/traces/<run-id>.json`: canonical run trace
- Use `flutterflow ai history`, `flutterflow ai trace latest`, and `flutterflow ai support inspect <run-id>` to debug what happened.

## Source Tracking

Executed scripts are archived for replay. Use `flutterflow ai support bundle`, `support replay`, or `support case` with a run ID.

## References

- Start from `references/recipes/`, then use other `references/` for lower-level patterns.
- **If a widget or property fails to compile and the symbol isn't in the drift table above, check `references/` for the nearest working example before iterating.** The DSL surface is curated; when it diverges from Flutter, the right form is documented in a reference.
- After two plausible fixes fail, validate the closest `references/` example. If it also fails, stop and report the SDK gap.
- Only use `flutterflow ai docs api-surface` or `flutterflow ai docs ui` when the references do not cover what you need or you are blocked on a specific API detail.
- `flutterflow ai docs api-surface` covers the lower-level helper contract. `flutterflow ai docs ui` covers the broader widget and action authoring surface.
- Use `flutterflow ai docs symbol <Name>` for a live signature, its doc comment, focused usage snippets, and related symbols.
- Use `flutterflow ai docs search "<words>"` to find the relevant public DSL symbol by intent before opening a whole topic.
- CRUD: `references/shopflow_dsl.dart`
- Task board: `references/taskboard_dsl.dart`
- Auth: `references/auth_shell_dsl.dart`
- Supabase: `references/supabase_crud_auth_shell_dsl.dart`
- Firestore: `references/social_feed_data_dsl.dart`
- Query-backed Firestore lists and grids (`where`, `orderBy`, limits, loading/empty slots): `references/query_backed_list_dsl.dart`
- Forms: `references/workflow_forms_dsl.dart`
- Shell/navigation: `references/commerce_shell_dsl.dart`
- Content generation: `references/content_companion_dsl.dart`
- Resource/library usage: `references/resource_library_dsl.dart`
- Postgres compile-only: `references/postgres_compile_only_dsl.dart`
- Action blocks: `references/action_block_showcase_dsl.dart`
- App events: `references/app_event_showcase_dsl.dart`
- GenUI: `references/genui_catalog_assistant_dsl.dart`
- Action reuse/composability: `references/taskboard_dsl.dart`
- Local state CRUD (lists, forms, per-item actions): `references/local_state_crud_dsl.dart`
- Theming, styling, layout (colors, fonts, sizing, borders, password fields): `references/styled_profile_dsl.dart`
- Media/content (horizontal lists, grids, images, text truncation, scrollable rows): `references/media_browser_dsl.dart`
- Asset/reference types (`imagePath`, `videoPath`, `audioPath`, `docRef(...)`, typed media/reference state): `references/asset_and_reference_surface_dsl.dart`
- Uploading media assets and referencing them (`sdk.assets.*`, storage paths vs Flutter bundle paths): `flutterflow ai docs assets`
- Edit: search + filter on existing page: `references/edit_add_search_filter_dsl.dart`
- Edit: add form + detail page + navigation: `references/edit_form_and_detail_dsl.dart`
- Edit: restyle, enhance, empty states, refresh: `references/edit_restyle_and_enhance_dsl.dart`
- Edit: existing collections, components, data binding, idempotent ops: `references/edit_data_binding_dsl.dart`
- Multiple API calls with explicit `outputAs:` naming: `references/multi_api_call_dsl.dart`
- REST + GraphQL APIs (`app.api(...)`, all five HTTP methods, `Endpoint.graphql`, headers, body types, `EndpointSettings` for cache/auth/private/streaming; env-driven base URLs via `app.apiGroup(baseUrlFromEnvironment:, environmentBaseUrls:)` so each environment hits a different URL): `references/rest_graphql_api_dsl.dart`
- Theme & design system (color slots, typography scale, spacing/radius/shadow tokens, custom fonts/icons, scrollbar, pull-to-refresh): `references/theme_design_system_dsl.dart`
- Animations + page transitions (`Lottie` / `Rive` widgets; `StartAnimation` / `StopAnimation` / `ResetAnimation` / `ReverseAnimation` / `ToggleLottie` / `ToggleRive` actions; `NavigateTransition` for page-to-page transitions): `references/triggers_and_animations_dsl.dart`
- Custom code + pub.dev packages — greenfield: pair a custom action with `http` and a custom widget with `intl` in a fresh project (`buildPubPackageShowcase`). Brownfield: add the same artifacts to an **existing** project using the `find* → add* → editPage` shape with structural inserts (`buildPubPackageEdit`, run with `--mode brownfield`). Read this when adding any pub-dep-backed feature, especially in edit flows. `references/custom_code_pub_package_dsl.dart`
- Custom Dart classes + enums used as typed args/returns via `classRef` / `customEnumRef`: `references/custom_code_classes_and_functions_dsl.dart`

Media uploads use `sdk.assets.*`, `flutterflow ai assets`, or `assets.*` MCP tools. Use the returned storage path, never `assets/images/...`. Uploads are public; keep credentials and private data out. Read `flutterflow ai docs assets` for formats, limits, and examples.

## Mock backend (run apps without a real backend)

Every API endpoint can be backed by the built-in mock backend, so the app you
build is runnable immediately — no real backend, keys, or CORS setup. Mocks
are STATEFUL: a `create` through one endpoint is visible to `list`/`getById`
through others during an app session. Prefer wiring mocks whenever you create
API calls for a backend that doesn't exist yet; the user flips one toggle to
go live later without touching the UI or data model.

Greenfield DSL (inside `buildApp`) — datasets are backend-agnostic; only the
binding builders reference endpoints:

```dart
final members = app.mockDataset('members', dataStructName: 'Member', seedRows: [
  {'id': 1, 'name': 'Ada', 'email': 'ada@example.com', 'role': 'admin'},
  // ... invent realistic rows; schema is inferred from the first row when
  // dataStructName: is omitted.
]);
app.mockApiWithDataset('ListMembers', dataset: members, operation: 'list',
  filters: {'role': 'role'},            // endpoint variable -> row field
  limitVariable: 'limit', offsetVariable: 'page', offsetIsPageNumber: true,
  responseTemplate: '{"items": <rows>, "total": <totalCount>}',
  latencyMs: 300);
app.mockApiWithDataset('GetMember', dataset: members, operation: 'getById',
  idVariable: 'memberId');
app.mockApiWithDataset('AddMember', dataset: members, operation: 'create');
app.mockApi('GetConfig', body: {'featureEnabled': true});  // static
app.useMockDataSource(useMock: true);   // app boots against mocks

// Firestore: seed a top-level collection from a dataset so Test Mode runs
// against test data with NO Firebase project configured (Test Backend =
// mock Firestore + auth). Rows should carry the collection's field names.
final tasks = app.collection('Task', fields: {'title': string, 'completed': bool_});
final taskSeed = app.mockDataset('tasks', seedRows: [
  {'id': 1, 'title': 'Buy groceries', 'completed': false},
]);
app.bindMockCollection(tasks, taskSeed);
```

Per-endpoint Live/Mock override: pass `dataSource:` to `mockApi` /
`mockApiWithDataset` (`follow` — the default, uses the project/environment data
source; `mock` — always this mock even in Live; `live` — always the real
backend even in Mock). Brownfield: `setApiMockDataSourceOverride(project,
endpointName: ..., dataSource: 'mock')`. Lets a project mock only certain
endpoints while the rest stay live.

Brownfield helpers (when editing a pulled project) mirror the DSL:
`addMockDataset`, `setMockDatasetRows`, `mockApiWithDataset`,
`mockApiWithStaticResponse`, `bindMockCollection` (+
`clearMockCollectionBinding`, `findMockDatasetForCollection`,
`listMockCollectionBindings`), `setMockDataSource`, `clearApiMock`,
`removeMockDataset`. Don't mix greenfield and brownfield in one script.
Datasets are capped at 500 rows and 256 KiB of encoded seed data; over-cap
`addMockDataset`/`setMockDatasetRows` (and the `mock_backend` MCP
`add_dataset`/`set_rows` ops) throw `ArgumentError` before any mutation.
Reference: `references/mock_backend_dsl.dart`.

Operations: `list` / `getById` / `create` / `update` / `delete`. Operations on
a single row require `idVariable` (an endpoint variable name) — the greenfield
DSL throws at declaration time, helpers at call time. The greenfield DSL allows
ONE binding per endpoint (declaring the same endpoint twice throws). All names
resolve with did-you-mean hints and throw `ArgumentError` before any proto
mutation. `clearApiMock(project, endpointName: ...)` removes a mock;
`removeMockDataset` disables bindings that referenced the dataset. The
project's existing mock state (datasets, which endpoints are mocked, the
Live/Mock toggle) is visible under `apis` in `flutterflow ai resources`, and in
the typed SDK as `MockBackend` / `MockDatasets` / `MockBindings`. A dedicated
`mock_backend` MCP tool authors mock state directly when not in a DSL script.

## Custom code authoring

The SDK is the canonical way to add, update, and remove user-authored Dart inside a FlutterFlow project. Read `flutterflow ai docs custom-code` for the full reference (typing, validation, staging sandbox, non-goals).

Quick map:

| Artifact | DSL (greenfield) | Helper (brownfield) |
| --- | --- | --- |
| Custom function | `app.customFunction` | `addCustomFunction` |
| Custom action | `app.customAction` | `addCustomAction` |
| Custom widget | `app.customWidget` | `app.editCustomWidget` / `addCustomWidget` |
| Custom class | `app.customClass` | `addCustomClass` |
| Custom enum | `app.customEnum` | `addCustomEnum` |
| Pub dep | `app.pubDependency` / `pubGitDependency` / `pubDevDependency` / `pubDependencyOverride` | `addPubDependency` / `addPubGitDependency` / `addDevDependency` / `addDependencyOverride` |

- **Greenfield vs brownfield** — DSL inside `buildApp`, helpers when editing a pulled project. Don't mix in one script.
- **Validation** checks format, identifiers and shape. For types involving `FFAppState`, structs or generated code, use `.ffai_staging/` + `dart analyze`.
- **Pub deps** — declare dependencies beside their custom code. Git sources use `app.pubGitDependency(name, url:, ref:, path:)`; prefer a commit SHA for `ref`. Read `flutterflow ai docs custom-code` for validation and helper forms.
- **Param typing** — `DslType` covers scalars, `listOf(T)`, `classRef(handle)`, `customEnumRef(handle)`, `app.enum_/struct` handles, Firestore/Postgres handles, `action`. For uncovered types (`Document`, `SQLiteRow`, RevenueCat, etc.) drop into `app.raw(...)` and set `FFParameter.dataType` directly.
- **Existing custom widgets** — edit params with `app.editCustomWidget(... ensureParam(...))`; bind args with `page.update(... patch.arguments(...))`. Create with `CustomWidget(..., arguments: {...})`.
- **Folder organization** — only relevant when the target project has `useFolderOrganizedCustomCode` on (an IDE-owned opt-in the SDK reads but never flips). On the standard layout the SDK auto-files new artifacts into the synthetic `CustomCode/Functions|Widgets|Actions` tree; pass `folderKey:` to override (`kCustomCodeFolderKey` = synthetic root; `''` falls back to legacy paths, NOT the root). On adopted layouts (rare brownfield) you must pass `folderKey:` explicitly. Full rules — standard vs adopted layout, fallbacks, flag-off behavior: `flutterflow ai docs custom-code` → "Folder organization".

## More guides (load only when the request needs them)

- Integrations (RevenueCat, Stripe, Braintree, Razorpay, AdMob, Gemini, Mux, Firebase Analytics/Crashlytics/Remote Config/Performance/App Check, Google Maps, Algolia, push, OneSignal, SQLite, Supabase OAuth/Edge Functions/RPC, custom auth): `flutterflow ai docs integrations` or the `docs` MCP tool with topic `integrations`.
- AI Agents: `flutterflow ai docs ai-agents` or the `docs` MCP tool with topic `ai-agents`.
- Test Pilot: `flutterflow ai docs test-pilot` or the `docs` MCP tool with topic `test-pilot`.
- FlutterFlow Desktop Live Session: `flutterflow ai docs live-session` or the `docs` MCP tool with topic `live-session`.
- Branches & merges: `flutterflow ai docs branches` or the `docs` MCP tool with topic `branches`.

## Deprecated proto fields are OFF LIMITS

When you drop into `app.raw((project) { ... })` (or any helper that hands you a raw proto message), **never read or write any field annotated `[deprecated = true]` in `flutterflow.proto`** — and never write a field named `legacy_*`. Codegen reads only the modern fields; data written to the deprecated pair is invisible to codegen and can crash it.

The canonical landmine is `FFConditionActions`:

```proto
message FFConditionActions {
  FFActionCondition legacy_condition   = 1 [deprecated = true]; //  do NOT use
  FFActionNode      legacy_true_action = 2 [deprecated = true]; //  do NOT use
  repeated FFTrueConditionAction true_actions = 4;              //   modern shape
  FFActionNode      false_action       = 3;
}
```

Walking the schema and picking the two scalar fields that look like "condition + true action" lands you in the deprecated pair. Codegen (`generateConditionActionsCode`) then reads `trueActions.first` and crashes with `Bad state: No element` — the SDK now rejects this shape at compile time with `MalformedConditionActionsError` so you'll see the failure before the push lands.

**Always build conditional action chains with the typed builders** — they emit the modern `true_actions[0]` shape and the SDK validators pass them by construction. There is no legitimate reason to reach for `app.raw` to construct a conditional:

```dart
// if/else
Actions.conditional(
  condition: someBoolVariable,
  trueActions: Actions.chain([Actions.snackBar('Yes')]),
  falseActions: Actions.chain([Actions.snackBar('No')]),
);

// if/else-if/else
Actions.conditionalMulti(
  branches: [
    (condition: isPremium, actions: premiumChain),
    (condition: isTrial,   actions: trialChain),
  ],
  fallback: Actions.chain([Actions.snackBar('Free tier')]),
);
```

The general rule: any field with `[deprecated = true]` or a name starting with `legacy_` is for backwards-compatible reads by other consumers — never write to them. If you're not sure, use the typed DSL/helper surface. If the typed surface really doesn't cover what you need, ask first; don't poke deprecated proto fields.
