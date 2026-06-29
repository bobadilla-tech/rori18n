# Contributing & Maintaining rori18n

## Repo layout

```
rori18n/
├── main.go                     CLI entry point
├── cmd/                        One file per command (add_key.go, generate.go, …)
├── internal/
│   ├── locale/                 YAML read/write, dedup, value linting
│   ├── source/                 ERB/Ruby scanning, t() injection, fragment merging
│   └── translate/              Google Cloud Translation client + cache
├── gem/                        Ruby gem (rori18n-rails on RubyGems)
│   ├── rori18n-rails.gemspec
│   ├── exe/rori18n             Gem binstub
│   ├── lib/
│   │   ├── rori18n-rails.rb
│   │   └── rori18n/
│   │       ├── version.rb      ← single source of truth for version
│   │       ├── platform.rb     OS/arch → binary asset name
│   │       ├── installer.rb    Download + cache binary from GitHub Releases
│   │       └── runner.rb       exec() binary with forwarded args
│   ├── lib/tasks/rori18n.rake
│   └── lib/generators/         rails g rori18n:install
└── .github/workflows/
    └── release.yml             Builds binaries + uploads to GitHub Release
```

---

## Development

### CLI (Go)

```sh
# Run without building
go run . <command> [flags]

# Build binary locally
go build -o rori18n .

# Run tests
go test ./...

# Run tests with race detector
go test -race ./...
```

No external tools required. All dependencies are in `go.sum`.

### Gem (Ruby)

```sh
cd gem

# Load gem in a REPL
ruby -I lib -r rori18n-rails -e "puts Rori18n::Platform.asset_name"

# Build gem locally (does not publish)
gem build rori18n-rails.gemspec

# Syntax check all Ruby files
ruby -c lib/rori18n/version.rb
ruby -c lib/rori18n/platform.rb
ruby -c lib/rori18n/installer.rb
ruby -c lib/rori18n/runner.rb
ruby -c lib/rori18n-rails.rb
ruby -c exe/rori18n
```

### Test gem against local CLI binary

Point the gem at a local binary by setting `RORI18N_BINARY`:

```sh
go build -o /tmp/rori18n-dev .
RORI18N_BINARY=/tmp/rori18n-dev ruby -I gem/lib -r rori18n-rails -e \
  "Rori18n::Runner.run(['--help'])"
```

To support `RORI18N_BINARY`, add this to `installer.rb` `binary_path`:

```ruby
def self.binary_path
  ENV["RORI18N_BINARY"] || File.join(cache_dir, "rori18n-#{CLI_VERSION}-#{Platform.asset_name}")
end
```

---

## Release process

Version in `gem/lib/rori18n/version.rb` is the single source of truth.
It controls both the gem version and which GitHub Release tag the installer
downloads from.

### Full release (CLI + gem)

Run these steps in order.

**1. Bump version**

```sh
# Edit gem/lib/rori18n/version.rb
# VERSION = "X.Y.Z"
```

**2. Commit + tag**

```sh
git add gem/lib/rori18n/version.rb
git commit -m "release vX.Y.Z"
git tag vX.Y.Z
git push && git push --tags
```

Pushing the tag triggers `.github/workflows/release.yml`, which:

- Creates a GitHub Release for `vX.Y.Z`
- Builds `rori18n_darwin_arm64`, `rori18n_darwin_amd64`, `rori18n_linux_amd64`
- Uploads all three as release assets

**3. Wait for CI** (~2 min). Verify assets exist:

```
https://github.com/bobadilla-tech/rori18n/releases/tag/vX.Y.Z
```

**4. Build + publish gem**

```sh
cd gem
gem build rori18n-rails.gemspec
gem push rori18n-rails-X.Y.Z.gem
```

> **Order matters.** Publish the gem only after CI has uploaded all binaries.
> Users who `bundle install` immediately after gem publish will try to download
> a binary that must already exist on the release.

### Gem-only release (docs, Ruby code — no CLI change)

No new binary needed. Use a patch bump and skip tagging.

```sh
# Bump to X.Y.Z+1 in version.rb — keep CLI_VERSION pointing at existing tag
cd gem
gem build rori18n-rails.gemspec
gem push rori18n-rails-X.Y.Z+1.gem
```

The installer will still download the binary for the prior tag (`CLI_VERSION`),
which already exists. No CI run required.

---

## Version policy

| Bump | When |
|---|---|
| Major | Breaking CLI flag changes or incompatible YAML layout changes |
| Minor | New commands, new flags, new gem features |
| Patch | Bug fixes, docs, gem-only changes |

Gem version and CLI version are kept in sync. A gem at `1.2.0` always downloads
the binary tagged `v1.2.0`.

---

## Adding a new command

1. Create `cmd/<name>.go` following the pattern in any existing cmd file.
2. Register with `rootCmd.AddCommand(...)` in an `init()` function.
3. Add `--dry-run` and `--root` flags (all write commands must have both).
4. Test logic in `internal/` — no tests required in `cmd/`.
5. Add the command to the table in `gem/README.md`.

---

## Platform support

Supported targets are defined in two places — keep them in sync:

| File | What to update |
|---|---|
| `gem/lib/rori18n/platform.rb` | `SUPPORTED` hash — maps `[os, arch]` to asset name |
| `.github/workflows/release.yml` | `matrix.include` — adds the build job |

Adding Linux arm64:

```ruby
# platform.rb
["linux", "aarch64"] => "rori18n_linux_arm64",
```

```yaml
# release.yml matrix
- goos: linux
  goarch: arm64
  runner: ubuntu-latest
```

---

## CI

`.github/workflows/release.yml` runs on `v*` tag pushes only — it does not run
on every commit. There is currently no PR CI. To add a test runner on PRs:

```yaml
# .github/workflows/test.yml
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
      - run: go test ./...
```

---

## Key invariants (don't break these)

**Write safety** — `setYAMLPath()` in `internal/locale/writer.go` skips any key
that already has a non-empty value. Only `translate` overwrites values, and only
when they match `IsPlaceholder()` (empty or `^TODO:|^FIXME:`). Never add a write
path that silently overwrites existing human-written values.

**Key routing** — `locale.UpsertTopicFile()` routes keys by top-level namespace.
`dashboard.foo` → `dashboard.{lang}.yml`. Unknown namespaces → `shared.{lang}.yml`.
Don't break this without updating `gem/README.md`.

**All-lang by default** — `refactor-key` renames across every language directory.
`discoverLangs()` reads subdirectories of `config/locales/`. New language
directories are picked up automatically — no code change needed.
