# rori18n-rails

Rails i18n toolchain. Extracts hardcoded strings, injects `t()` calls,
translates via Google Cloud, deduplicates, and renames keys — all from one CLI.

Built at [Bobadilla Technologies](https://bobadilla.tech) to handle i18n at
scale across multiple production Rails apps. Battle-tested in
[Requiems API](https://requiems.xyz)
([source](https://github.com/bobadilla-tech/requiems-api)), among others.

A drop-in replacement for `i18n-tasks` write commands with capabilities it
lacks.

```sh
bin/rori18n generate --fix --root .
```

---

## What it does that i18n-tasks can't

| Capability                                   | Command           |
| -------------------------------------------- | ----------------- |
| Find every hardcoded string in ERB/Ruby      | `report`          |
| Replace hardcoded strings with `t()` calls   | `generate --fix`  |
| Merge sentence fragments into a single `t()` | `merge-fragments` |
| Translate missing keys via Google Cloud      | `translate`       |
| Rename a key across YAML and all callers     | `refactor-key`    |
| Deduplicate identical strings to `shared.*`  | `consolidate`     |

Also covers everything i18n-tasks does: lint, audit, prune.

---

## Install

```ruby
# Gemfile
gem "rori18n-rails", group: :development
```

```sh
bundle install
bundle exec rails g rori18n:install   # creates bin/rori18n
```

The binary is downloaded automatically on first run and cached at
`~/.rori18n/bin/`. Nothing to install manually.

**Supported platforms:** macOS (Apple Silicon, Intel), Linux (x86_64).

---

## Usage

All commands take `--root <path-to-rails-app>`. If you run from inside the app,
`--root .` works.

```sh
bin/rori18n <command> --root <rails-app-root> [flags]
```

Or via Rake:

```sh
bundle exec rake rori18n:run ARGS="<command> [flags]"
```

---

## Workflow

### 1. See what needs extracting

```sh
bin/rori18n report --root .
```

Lists every hardcoded user-visible string in `app/` with file and line number.
Read-only — nothing is changed.

```sh
# CI: fail if hardcoded strings exist in changed files
git diff --name-only origin/main | \
  bin/rori18n report --root . --fail-on-found --changed-files -
```

### 2. Extract strings to YAML

```sh
# Preview first
bin/rori18n generate --root . --fix --dry-run

# Apply
bin/rori18n generate --root . --fix
```

One pass does everything:

- Strings used in multiple files → written to `shared.{lang}.yml`
- Unique strings → written to the matching topic file (`home.en.yml`, etc.)
- Source files rewritten — hardcoded strings replaced with `t('key')` calls

The app behaves identically after this step.

```sh
# Only process changed files
git diff --name-only origin/main | \
  bin/rori18n generate --root . --fix --changed-files -

# Also create ES/FR skeleton files
bin/rori18n generate --root . --fix --languages es,fr
```

### 3. Merge ERB fragments

Sentences split across ERB interpolations are merged into a single `t()` call:

```erb
<%# Before %>
<p>Hello <%= current_user.name %>, you have <%= count %> messages.</p>

<%# After %>
<p><%= t('.greeting', name: current_user.name, count: count) %></p>
```

```sh
bin/rori18n merge-fragments --root . --dry-run
bin/rori18n merge-fragments --root . --fix
```

Complex cases (boolean operators, nested HTML) are flagged for manual review and
never auto-patched.

### 4. Lint

```sh
bin/rori18n lint --root .
```

Exits `0` if every `t('key')` call resolves to a defined YAML entry. Exits `1`
with `file:line: error: missing key "..."` output. Add to CI.

### 5. Translate

Requires a [Google Cloud Translation API](https://cloud.google.com/translate)
service account key.

```sh
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

bin/rori18n translate --root . --to es,fr --dry-run
bin/rori18n translate --root . --to es,fr
```

**Write safety:** only fills empty values and `TODO:`/`FIXME:` placeholders.
Human translations are never overwritten.

Results are cached — re-running the same source string does not hit the API
again.

```sh
# Protect brand names from being translated
bin/rori18n translate --root . --to es,fr \
  --protect-words "Acme Corp,AbstractAPI"

# Or from a file (one phrase per line)
bin/rori18n translate --root . --to es,fr \
  --protect-file .translate-dictionary.txt
```

### 6. Prune dead keys

```sh
bin/rori18n prune --root . --dry-run
bin/rori18n prune --root .
```

Deletes YAML keys that no source file calls. Understands pluralization —
`foo.one` / `foo.other` are kept when source calls `t('foo', count: n)`.

---

## All commands

| Command           | What it does                                                |
| ----------------- | ----------------------------------------------------------- |
| `report`          | List hardcoded strings (read-only, CI-safe)                 |
| `generate`        | Extract strings to YAML; optionally replace them with `t()` |
| `merge-fragments` | Merge ERB sentence fragments into single `t()` calls        |
| `lint`            | Exit 1 if any `t()` call references an undefined key        |
| `audit`           | Report missing, orphaned, and empty keys                    |
| `add-key`         | Add one key-value pair to the correct YAML file             |
| `prune`           | Delete YAML keys never referenced in source                 |
| `translate`       | Fill missing keys via Google Cloud Translation              |
| `analyze`         | Find duplicate key names or identical values                |
| `consolidate`     | Deduplicate keys and rewrite all callers in one pass        |
| `refactor-key`    | Rename a key in YAML and all `t()` callers                  |

---

## Command reference

### `report`

```sh
bin/rori18n report --root .
bin/rori18n report --root . --fail-on-found
bin/rori18n report --root . --erb-only

# Limit to changed files (reads newline-separated paths from stdin)
git diff --name-only origin/main | \
  bin/rori18n report --root . --changed-files -
```

### `generate`

```sh
bin/rori18n generate --root . --fix --dry-run
bin/rori18n generate --root . --fix
bin/rori18n generate --root . --fix --languages es,fr
bin/rori18n generate --root . --fix --safe-only    # only reuse existing keys
bin/rori18n generate --root . --fix --no-shared    # skip shared.yml consolidation
```

### `merge-fragments`

```sh
bin/rori18n merge-fragments --root . --dry-run
bin/rori18n merge-fragments --root . --fix
```

### `lint`

```sh
bin/rori18n lint --root .
bin/rori18n lint --root . --lang fr
```

### `audit`

```sh
bin/rori18n audit --root . --orphaned        # in YAML, never called
bin/rori18n audit --root . --missing         # called in source, not in YAML
bin/rori18n audit --root . --all
bin/rori18n audit --root . --empty-values
bin/rori18n audit --root . --compare-locale fr
```

### `add-key`

```sh
bin/rori18n add-key --root . \
  --key shared.buttons.save \
  --value "Save changes"

bin/rori18n add-key --root . --lang es \
  --key shared.buttons.save \
  --value "Guardar cambios"
```

Key is routed to the YAML file matching its top-level namespace
(`shared.buttons.save` → `shared.en.yml`, `dashboard.foo` → `dashboard.en.yml`).

### `prune`

```sh
bin/rori18n prune --root . --dry-run
bin/rori18n prune --root .
bin/rori18n prune --root . --lang fr
bin/rori18n prune --root . --pattern 'shared\.common\.'
```

### `translate`

```sh
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

bin/rori18n translate --root . --to es,fr --dry-run
bin/rori18n translate --root . --to es
bin/rori18n translate --root . --to es --no-cache
bin/rori18n translate --root . --to es --report-file reports/translate.json
bin/rori18n translate --root . --to es --protect-words "Acme,AbstractAPI"
```

### `analyze`

```sh
bin/rori18n analyze --root .
bin/rori18n analyze --root . --all     # include same-name, different-value keys
bin/rori18n analyze --root . --source  # also scan ERB for hardcoded duplicates
```

### `consolidate`

```sh
bin/rori18n consolidate --root . --dry-run
bin/rori18n consolidate --root .
bin/rori18n consolidate --root . --no-prune   # rewrite callers, skip key deletion
```

### `refactor-key`

```sh
# Always dry-run first
bin/rori18n refactor-key --root . \
  --old shared.common.copy_btn \
  --new shared.buttons.copy \
  --dry-run

bin/rori18n refactor-key --root . \
  --old shared.common.copy_btn \
  --new shared.buttons.copy

# EN only (skip other locale files)
bin/rori18n refactor-key --root . \
  --old shared.common.copy_btn \
  --new shared.buttons.copy \
  --all-lang=false
```

---

## CI integration

```yaml
# Minimal: lint only
- name: Lint i18n keys
  run: bin/rori18n lint --root .

# Full: block hardcoded strings + lint
- name: Check hardcoded strings
  run: |
    git diff --name-only origin/main | \
      bin/rori18n report --root . --fail-on-found --changed-files -

- name: Lint i18n keys
  run: bin/rori18n lint --root .
```

---

## YAML layout expected

```
config/locales/
  en/
    home.en.yml        # en.home.*
    dashboard.en.yml   # en.dashboard.*
    shared.en.yml      # en.shared.*
  es/
    home.es.yml
    shared.es.yml
  fr/
    ...
```

---

## vs i18n-tasks

rori18n handles all write operations. `i18n-tasks` is still useful as a passive
health-checker (`bundle exec i18n-tasks health`) — its scanner covers some
Rails-specific patterns (before_actions, model translations) that static
analysis misses. Use both: rori18n for writes, i18n-tasks health-only in CI.
