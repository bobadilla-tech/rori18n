# rori18n

[![codecov](https://codecov.io/gh/bobadilla-tech/rori18n/graph/badge.svg?token=N3O0R9J0SN)](https://codecov.io/gh/bobadilla-tech/rori18n)

Production-grade Rails i18n toolchain. Built at
[Bobadilla Technologies](https://github.com/bobadilla-tech) and running in
production across multiple client apps, including
[Requiems API](https://requiems.xyz).

Full replacement for `i18n-tasks` write commands, plus capabilities it lacks:

- Extract hardcoded strings from ERB/Ruby and inject `t()` calls automatically
- Merge sentence fragments split across ERB interpolations into a single `t()`
  call
- Translate missing keys via Google Cloud Translation with brand-name protection
- Rename a key across YAML and all source callers in one command
- Deduplicate identical strings across files and consolidate them to `shared.*`

Also covers everything i18n-tasks does: lint, audit, prune.

## Install

```ruby
gem "rori18n-rails", group: :development
```

```sh
bundle install
bundle exec rails g rori18n:install
bin/rori18n generate --fix --root .
```

The binary is downloaded automatically on first run and cached locally.
**Supported platforms:** macOS (Apple Silicon, Intel), Linux (x86_64).

**Requirements:** a Rails app with a `config/locales/{lang}/` layout. A Google
Cloud Translation API service account key is only needed for the `translate`
command.

Full command reference, workflow walkthrough, and CI recipes:
**[gem/README.md](gem/README.md)**

## Example

```erb
<!-- Before -->
<h1>Welcome back</h1>
<p>Hello <%= current_user.name %>, you have <%= count %> messages.</p>
```

```sh
bin/rori18n generate --fix --root .      # extract + inject t() calls
bin/rori18n merge-fragments --fix --root .  # merge the sentence fragment
```

```erb
<!-- After -->
<h1><%= t('.welcome_back') %></h1>
<p><%= t('.greeting', name: current_user.name, count: count) %></p>
```

The app behaves identically after this step — only source and YAML change. Then
translate:

```sh
export GOOGLE_APPLICATION_CREDENTIALS=service-account.json
bin/rori18n translate --root . --to es,fr
```

---

## vs i18n-tasks

| Feature                            | rori18n                         | i18n-tasks              |
| ---------------------------------- | ------------------------------- | ----------------------- |
| Extract hardcoded strings from ERB | ✅ `report`, `generate`         | ❌                      |
| Inject `t()` calls into source     | ✅ `generate --fix`             | ❌                      |
| Merge ERB sentence fragments       | ✅ `merge-fragments`            | ❌                      |
| Translate missing keys             | ✅ `translate` (Google API)     | ✅ (multiple backends)  |
| Lint undefined `t()` calls         | ✅ `lint`                       | ✅ `health` / `missing` |
| Prune orphaned keys                | ✅ `prune`                      | ✅ `remove-unused`      |
| Rename keys + update callers       | ✅ `refactor-key`               | ✅ `mv`                 |
| Deduplicate shared values          | ✅ `consolidate`                | ❌                      |
| Rails integration                  | Ruby gem, auto-installed binary | Ruby gem in Gemfile     |

i18n-tasks is still useful as a passive health checker
(`bundle exec i18n-tasks health`) because its Prism-based scanner handles some
Rails-specific patterns (before_actions, model translations) that rori18n's
static scanner does not. Run rori18n for all write operations; use i18n-tasks
health-only in CI.

## Using the CLI without Rails

The `rori18n` binary works standalone against any `config/locales/` tree:

```sh
go install github.com/bobadilla-tech/rori18n@latest
export PATH="$PATH:$(go env GOPATH)/bin"
rori18n report --root <app-root>
```

## Docs

- [gem/README.md](gem/README.md) — full command reference, workflow, CI
- [docs/core/ARCHITECTURE.md](docs/core/ARCHITECTURE.md) — package internals
- [docs/core/CONTRIBUTING.md](docs/core/CONTRIBUTING.md) — dev setup, release
  process, adding commands
