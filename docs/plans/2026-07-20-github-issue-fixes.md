# Fix 5 open GitHub issues (array-sentinel corruption, dynamic-key false orphans, extractor false positives)

## Context

Five open issues on bobadilla-tech/rori18n, all found in production via
requiems-api and all silent-data-loss or false-negative bugs — nothing raised
an error, they just produced wrong output that only surfaced later (500s in
production, or hardcoded strings quietly shipping untranslated):

- **#5 / #6** (duplicate reports, same root cause): `translate` corrupted
  every array-valued locale key it touched. `internal/locale/parser.go`'s
  `flattenNode()` emits a synthetic `Entry{Value: "[array]"}` sentinel for
  YAML sequence-valued keys, purely so `lint`/`audit` know the key "exists"
  and don't false-flag `t('foo.items')` calls as missing. But
  `internal/translate/walker.go`'s `FindMissing()` only skipped
  `e.Value == ""` — not the sentinel — so array keys with no target-locale
  counterpart got sent to Google Translate as the literal string `"[array]"`,
  and `internal/locale/writer.go`'s `upsertMappingPath` (which has no
  `SequenceNode` branch at all, only ever creates `yaml.ScalarNode`) wrote
  the translated garbage back over what should have been a YAML array.
  Real damage: 80+ corrupted keys across es/fr industries/comparisons files,
  each one a `NoMethodError: undefined method 'each' for "[formación]":String`
  waiting to happen on the next `.each` in a view.

- **#4 / #1** (duplicate reports, same root cause): `prune` deleted live,
  actively-rendered locale keys. `internal/source/audit.go`'s `tCallRe`
  regex can only match `t()` calls with a literal string key — it produces
  zero matches on Ruby string interpolation like
  `t("systems.index.cards.#{slug.tr('-', '_')}.title")`, a very common
  Rails pattern for pages sharing one partial across N slugs. Because
  `extractTCalls` silently recorded zero usages for these lines, every key
  under that dynamic scope looked orphaned to `Audit()`, and `prune` deleted
  them — 320+ lines gone in one run on requiems-api's industries locale
  file, with no warning printed anywhere that it was guessing around
  unresolvable dynamic calls.

- **#3, bug 1**: `looksLikeCode()` in `internal/source/extractor.go` false-
  positived on ordinary 2-word English phrases containing one hyphenated
  compound word (e.g. "Enterprise-scale APIs"), because its CSS-utility-class
  density heuristic (`words > 1 && hyphens >= words-1`) fires on any 2-word
  string with exactly one hyphen. Real user-facing copy silently never
  surfaced in `report`.

- **#3, bug 2**: bare text nodes inside multi-line `<a>`/`<button>` elements
  (e.g. "Book a Call" sitting between two decorative `<svg>` icons) were
  invisible to every scanner. `blockTagOpenRe` didn't include `a`/`button`
  in its tag alternation, and even fixing that wouldn't have been enough —
  `scanMultiLineTagContent`'s lookahead loop aborted the instant it saw any
  `<`/`>` in a following line, which an icon-adjacent link hits on line one
  of the lookahead.

## Approach

Order followed for every fix: write the regression test first, confirm it
fails for the right reason (missing symbol / wrong assertion, not a typo),
implement the minimal fix, confirm green, then run the full suite.

**Array sentinel (#5/#6).** Centralized the sentinel as
`locale.ArraySentinel` (was a bare `"[array]"` string literal duplicated in
`parser.go` and `value_lint.go`) since the fix required touching this exact
logic anyway. Added the same value as a third skip condition in
`FindMissing()`, alongside the existing empty-string check. This makes array
keys permanently invisible to the translate pipeline — never sent to the
API, never written over. Recursively translating array *element* leaves
(feature/title/body strings nested inside array items) was considered and
explicitly deferred — it needs `flattenNode` to emit per-element addressable
entries and the writer to gain a `SequenceNode` construction path, a
materially bigger change than "stop the bleeding," which is what both
issues asked for as the minimum safe fix.

**Dynamic keys (#4/#1).** Added a second regex, `dynamicTCallRe`, that
matches `t()` calls containing `#{` and captures the static text before the
first interpolation as a `Prefix` (empty string when interpolation is the
very first character, e.g. `t("#{scope}.key")`). Every such call is recorded
as a `DynamicKeyUsage` on the new `AuditResult.DynamicKeys` field, mirroring
the existing `RelativeKeys` mechanism used for mailer-style relative keys.
The design decision here: orphan candidates whose key falls under a
*non-empty* dynamic prefix are auto-excluded from `OrphanedKeys` (so `prune`
simply can't touch them) — but calls with no extractable static prefix at
all only get counted as a diagnostic, not used to blanket-protect anything.
Auto-excluding on an empty prefix would have meant one ambiguous call could
silently disable pruning across an entire locale tree, trading one
data-loss failure mode for a different, harder-to-notice one. `audit` and
`prune` both now print a "Dynamic keys: N" line so the empty-prefix case is
at least visible instead of silent. True interpolation resolution (actually
evaluating `#{slug.tr(...)}` against real data) stays out of scope, per
ARCHITECTURE.md's existing "strict-off" design note — this fix stops the
deletion, it doesn't pretend to solve static analysis of arbitrary Ruby.

**`looksLikeCode` (#3 bug 1).** Tightened the density heuristic from
`words > 1` to `words >= 3` before applying the hyphen-density check. Hand-
verified against the full existing 15-case test table that this causes zero
regressions — the two cases that drop out of the density branch under the
tightened guard (`"text-gray-900 dark:bg-gray-800"`, `"px-4 flex items"`)
are still caught by the separate `cssKeywords` substring-match fallback
further down the function, so nothing that used to correctly return `true`
stopped doing so.

**Multi-line anchor text (#3 bug 2).** The issue's own suggested fix (just
add `a|button` to `blockTagOpenRe`) was checked against its own proposed
test and found insufficient for two independent reasons: the open-tag line
in the repro (`<a href="<%= url %>" ...>`) contains a literal `>` inside the
ERB tag, which breaks the regex's `[^>]*>$` anchor even after widening the
tag list; and separately, the lookahead loop terminated on the first `<`/`>`
it saw in a following line, which in the repro is the very first icon
`<svg>`, before ever reaching the text. Fixed both: strip embedded
`<%= ... %>` output via the already-existing `erbTagRe` (same pattern used
identically in three other scanners in this file) before matching the open
tag, and rewrote the lookahead loop to skip lines starting with a small
dedicated `decorativeMarkupPrefixes` list (`<svg`, `<path`, `<pre`, `<code`,
and their closing tags) instead of aborting on them, stopping only at the
real `</tagname>` close. Kept this skip-list separate from `scanTagContent`'s
existing (differently-scoped) `skipTag` slice rather than sharing it, to
avoid any blast radius on that unrelated scanner.

## Final notes

All 5 issues fixed; 10 new test functions added (2 in
`internal/translate/translate_test.go`, 6 in `internal/source/audit_test.go`,
2 in `internal/source/extractor_test.go` plus 3 table-driven cases added to
the existing `TestLooksLikeCode` table). `go build`, `go vet`, and the full
`go test ./...` suite are green with no regressions in the pre-existing ~40
tests touching the same shared code paths.

Manually smoke-tested both non-extractor fixes end-to-end with throwaway
repro directories (not checked in): confirmed `translate --dry-run` no
longer lists an array-valued key with no target counterpart; confirmed
`audit`/`prune` correctly protect a key referenced via a resolvable dynamic
prefix (`systems.index.cards.#{slug}.title`) while still surfacing — but not
falsely protecting — a fully-dynamic call with no static prefix
(`#{i18n_scope}.hero.headline`), matching the deliberate scope decision
above.

No deviations from the approved plan. Nothing landed for the "recursively
translate array element leaves" stretch goal noted in #5/#6 — flagged above
as an explicit follow-up if it's ever wanted, not attempted here.

Files touched: `internal/locale/parser.go`, `internal/locale/value_lint.go`,
`internal/translate/walker.go`, `internal/translate/translate_test.go`,
`internal/source/audit.go`, `internal/source/audit_test.go`,
`internal/source/extractor.go`, `internal/source/extractor_test.go`,
`cmd/audit.go`, `cmd/prune.go`. Not yet committed.
