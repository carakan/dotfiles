# Homebrew on Intel macOS: asdf symlink workaround

Applies to: Intel x86_64, macOS 15.8 Sequoia, Homebrew at `/usr/local`
Set up: 2026-10-06 · Updated: 2026-10-23 (llvm compiled once, parked in `Cellar/.llvm-builds`)

**Not applicable on Apple Silicon or Linux.** There, brew ships bottles (or a
distro package manager does the job) and the whole "symlink a formula at
another install" scheme is unnecessary. The scripts that implement it
(`packages/llvm/*.sh`) detect `uname -s` / `uname -m` and exit 0 without
touching anything, so this repo runs unchanged on those platforms.

## Why this exists

Homebrew stopped publishing bottles for macOS Intel. Every install on this machine is a
source build, and the two heaviest dependencies build for **hours**:

| Formula | Build time | Pulled in by |
|---------|-----------|--------------|
| `llvm`  | 1-3 h     | `rust` -> `git-delta` |
| `node`  | 10-20 min | `pi-coding-agent` |

Homebrew says so on every install:

> We do not provide support for this platform (as-of September 2026, announced August 2025).
> Apple have dropped Intel x86_64 support in macOS Golden Gate (27).
> Homebrew no longer builds bottles for this configuration.

There is **no Intel macOS bottle for llvm at any version**. Confirmed against the Homebrew
API: llvm 23.1.2 publishes assets for `arm64_sequoia`, `arm64_tahoe`, `arm64_golden_gate`
and `x86_64_linux` - the x86_64 assets are Windows MSVC. Upstream LLVM also has no
`x86_64-apple-darwin` tarball for 23.1.2. MacPorts is not an alternative either: it also
builds locally, and it was explicitly not wanted.

So rather than building, Homebrew is pointed at versions **asdf already installed**.

## Current layout

```
/usr/local/Cellar/llvm/23.1.3    -> llvm/23.1.0   (HOLLOW - see below)
/usr/local/Cellar/llvm@21/21.1.8_1                 (real build, renamed)
/usr/local/Cellar/node/26.12.1   -> ~/.asdf/installs/nodejs/26.12.1 (v26.12.1)
/usr/local/Cellar/bun/1.4.4      -> ~/.asdf/installs/bun/1.4.4      (bun 1.4.4)
/usr/local/Cellar/python@3.14/3.14.9 -> ~/.asdf/installs/python/3.14.9
/usr/local/Cellar/ruby/4.0.8   -> ~/.asdf/installs/ruby/4.0.7     (ruby 4.0.7)
```

**The unversioned `llvm` keg is hollow** (found 2026-10-21 — **superseded
2026-10-23**, see "Session 2026-10-23 (later)" at the end of this file: llvm
is now a real compiled build parked in `Cellar/.llvm-builds/`, and the
hollow `llvm@21` build it replaced was deleted by a failed install's
rollback): `23.1.0` contains
**0 binaries and no receipt** - it is an empty directory with a symlink named
`23.1.3` in front of it. Brew therefore reports llvm as installed and
current, while no llvm exists on the machine. Anything that genuinely needs
llvm's binaries (rust's `llvm-tools` component, crystal) will fail. The
layout block above used to read as if a real build were sitting there; it is
not. `llvm@21` is different: it is a real 155-binary build (see below).

Old (possibly corrupt, outdated-revision) kegs were purged:

```
brew uninstall --force --ignore-dependencies node
rm -rf /usr/local/Cellar/ruby/4.0.6_1
```

Supporting pieces, all required:

- `/usr/local/opt/<formula>` must point at the **current** keg
  ```bash
  ln -sfn ../Cellar/node/26.11.0_1 /usr/local/opt/node
  ```
- each asdf install needs a valid `INSTALL_RECEIPT.json`, or Homebrew treats the keg as
  incomplete and rebuilds it. Safest path: copy the full receipt from the previous asdf
  install (12 top-level fields) and edit only `source.versions.stable`
- inside that receipt: `poured_from_bottle: true`, `installed_as_dependency: false`

## The rule that makes it work

The whole trick, in three parts. All three must agree:

1. **Keg directory name** == formula's stable version *including any revision suffix*
   (`26.10.0_2`, not `26.10.0`)
2. **The receipt's `source.versions.stable`** reports that same string
3. **The formula's current stable version** is that same string

Homebrew compares these as literal strings. It is not "newest wins" and not
"`poured_from_bottle` decides": renaming a keg from `4.0.7` to `4.0.7_2` when the real
stable is plain `4.0.7` made it *stop* matching, which proved the comparison is textual.

The node receipt mismatch is what caused every failed attempt:

```
keg dir:   26.10.0_2
receipt:   26.10.0      <-- mismatch, Homebrew rebuilt node every time
stable:    26.10.0
```

After setting the receipt to `26.10.0_2`, a dry-run of pi-coding-agent stopped listing
node as a dependency at all:

```
brew upgrade --dry-run pi-coding-agent
==> Would upgrade 1 requested outdated package
pi-coding-agent 1.0.0 -> 1.0.2
```

## Pinning caveat

`brew pin` **blocks installs** that need a newer version of the pinned formula:

```
Error: You must `brew unpin node` as installing pi-coding-agent requires
       the latest version of pinned dependencies.
```

- `llvm` is now **unpinned** (2026-10-09): upgrading `crystal`, `pi-coding-agent`,
  `tree-sitter-cli` and `zsh-patina` refused until pinned deps were at latest, so the pin
  had to go. It is safe - nothing rebuilds because the keg name matches current stable
- `node` and `ruby` must stay **unpinned**, or installs of dependents fail

Pinning them does hide them from `brew outdated`, but that is cosmetic and not worth
blocking installs.

## NEVER run `brew cleanup`

With this layout, `brew cleanup` would delete the **real llvm binaries**: it removes kegs
that are not the newest version, and `llvm/23.1.0` (the actual build) looks older than
`llvm/23.1.3` (a symlink). If the old version ever has to go, delete the symlinks first
and keep the real dir under the name `opt` points at. Same logic applies to node/ruby
keg symlinks pointing into `~/.asdf`.

## Verify

```bash
# should print nothing
brew outdated --json=v2 node ruby llvm

# what brew thinks is installed
brew list --versions node ruby llvm

# binaries must report their real version
/usr/local/Cellar/node/26.11.0_1/bin/node --version   # v26.11.0
/usr/local/Cellar/ruby/4.0.7_1/bin/ruby --version     # ruby 4.0.7
rustc --version                                       # 1.99.0
```

## Traps hit while doing this

Worth keeping, they cost most of the time:

- **`ln -sfn` into a non-empty directory creates the link *inside* it.** Twice this left a
  "linked" directory with no `bin/`. Always `rm -rf` the target first.
- **A killed build leaves a 0-byte keg** (e.g. an empty `llvm/23.1.2`). Homebrew then tries
  to repair it on every later install - that caused the repeated LLVM rebuilds. Delete
  empty kegs.
- **Stale locks** in `/usr/local/var/homebrew/locks/` make brew block on phantom processes:
  `rm -f /usr/local/var/homebrew/locks/*.lock`
- **Orphaned builds outlive `kill` on the parent brew process.** Also
  `pkill -9 -f "llvm-project"` / `pkill -9 -f "node-20261006"`, then confirm with `ps`.
- **Killed builds leak gigabytes** in `/private/tmp/s-*` (saw 2.2 GB and 4.0 GB). Clean up.
- **`brew upgrade` has no `--ignore-dependencies`** in this Homebrew version; `brew install`
  and `brew reinstall` do.
- **Symlinking an empty asdf install** makes brew believe the version exists while every
  command fails. Check the target has `bin/<tool>` before linking.
- **`brew pin <formula>` blocks installs** of anything needing a newer version (above).
- **Rebuilding is not always a dependency chain.** `git-delta` does not depend on llvm; the
  chain is `git-delta -> rust -> llvm`. Check `brew uses --installed llvm` before assuming.
- **Revisions bump mid-session.** While working on 2026-10-09, node's stable moved
  `26.11.0 -> 26.11.0_1` and ruby's `4.0.7 -> 4.0.7_1` between checks - both had already
  been renamed once. Always re-run `brew outdated --json=v2` immediately before the
  rename; a keg renamed to a version brew no longer wants still counts as outdated.
- **An interrupted upgrade leaves an empty keg** (saw `python@3.14/3.14.8_1` with zero
  entries after a timeout kill). Same repair as the 0-byte keg: `rmdir` it before resuming
  `brew upgrade`.

## Removing the workaround

To be undone in a few months, once bottled builds exist for a supported Mac:

```bash
rm /usr/local/Cellar/llvm/23.1.3   # symlink; keep/inspect llvm/23.1.0 (real build)
rm /usr/local/Cellar/node/26.11.0_1
rm /usr/local/Cellar/ruby/4.0.7_1

# receipts written into asdf installs must go too
rm ~/.asdf/installs/nodejs/26.11.0/INSTALL_RECEIPT.json
rm ~/.asdf/installs/ruby/4.0.7/INSTALL_RECEIPT.json

brew install node ruby llvm    # real source builds (hours)
```

Then confirm nothing broke:

```bash
node --version && ruby --version && rustc --version && brew doctor
```

## Doctrine: swap vs build (2026-10-09)

| situation | action |
|---|---|
| no asdf plugin (crystal, llvm, go, rust, redis, tmux, ...) | let brew build from source - nothing to swap |
| asdf plugin, version already installed (node, bun, ruby) | symlink keg → asdf install (the pattern below) |
| asdf plugin, version missing (e.g. python 3.14.x) | `asdf install` also compiles from source - no savings; let brew build once, symlink only on **future** bumps |

Swap steps (all required, in order): copy the real keg's `INSTALL_RECEIPT.json` into the
asdf install → `rm -rf` the real keg → `ln -s ~/.asdf/installs/<p>/<v> <keg>` → verify
`/usr/local/bin/<tool> --version` and `brew list --versions <f>`.

Applied 2026-10-09: **bun 1.4.2** was a real Sep-14 build, now a keg symlink to asdf.

**NEVER delete old asdf versions.** They are pinned by legacy projects through
project-local `.tool-versions` files that no home-directory scan will reveal. The swap
doctrine only ever **adds** the one version brew currently demands and symlinks it.
(2026-10-09 incident: a purge of "unpinned" versions - nodejs 12/18/24/26.10, ruby
2.x/3.2/4.0.0, bun 1.0-1.3, elixir 1.16.1 - hit legacy pins and had to be restored.
Restored: nodejs 12.14.1/18.19.1/24.7.0/24.14.0, bun 1.0.35/1.2.19/1.3.14,
ruby 2.6.10. **ruby 2.3.8: restored 2026-10-12** — current ruby-build (v20260924)
auto-builds `openssl-1.0.2u` from source (the old `openssl@1.1` header rejection is
moot), and modern clang passes with just CFLAGS:
`CFLAGS="-Wno-error=implicit-function-declaration -Wno-deprecated-declarations
-Wno-error=incompatible-pointer-types-discards-qualifiers" asdf install ruby 2.3.8`,
then `gem install bundler -v 2.3.27` + `gem update --system 3.2.3` (last lines
supporting ruby 2.3). Pending review: ruby 2.7.7/2.7.8/3.2.11/4.0.0 (restoration
stopped mid-compile at user request; their stale install-locks cleared 2026-10-12).
Dropped by owner: elixir 1.16.1-otp-26 (not used). nodejs 26.10.0 stays deleted:
explicitly ordered, superseded by 26.11.0.)

Caveats learned:

- **A killed `asdf install` leaves `~/.asdf/install-locks/<tool>/<version>` behind,
  and asdf 0.20 then treats that version as nonexistent** — hidden from `asdf list`,
  shim suggestions, and project `.tool-versions` resolution even though the install
  dir is fully populated. After any interrupted install: `rm` the stale lock (0-byte
  file, owner dead) and re-run `asdf reshim <tool>` — shims generated while the lock
  existed don't register the version. (2026-10-12: ruby 2.3.8 invisible for an hour
  because of this; same zombie locks sat on 2.7.7/2.7.8/3.2.11/4.0.0/elixir 1.16.1
  from the earlier interrupted restoration.)

- **`asdf uninstall` takes ONE version per invocation** - extra arguments are silently
  ignored. Loop over versions.
- **Brew's own Tab can record `stable` WITHOUT the revision suffix** (seen on
  python@3.14: keg `3.14.8_1`, receipt said `3.14.8`). The formula then shows as outdated
  forever even though installed == current. Rewrite the receipt's
  `source.versions.stable` to the full keg string - same rule as node's `26.10.0_2`.
- **`opt/<formula>` links are NOT always repointed by brew** after a build lands in a new
  keg (python@3.14 stayed on the old keg from Oct 2). Verify `readlink /usr/local/opt/...`
  after every swap. Beware: version-only verifications can pass against the WRONG keg when
  old and new print the same version string.
- **python@3.x kegs host dependents' site-packages** (`awscli`, `meson`,
  `gobject-introspection`, `sphinx-doc` install into it). A swap works, but brew-written
  modules then live inside the asdf dir - uninstalling that asdf version breaks them.
- `python 3.13.16` kept despite no pin: recent, plausibly in interactive use.

## Why these three

`llvm`, `node` and `ruby` are the only formulae here whose builds are long enough to matter
and whose versions asdf already carries. Everything else installed from bottle-equivalent
source or has a real bottle. See `Brewfile` for the full package list and
`packages/asdf` for the asdf version managers.

## Session 2026-10-09 (evening): node 26.11.0_1 → 26.11.1, python@3.14 3.14.8_1 → 3.14.8_2

Same doctrine, fastest form — both versions were **already installed by asdf**
(zero compile):

1. Receipt: copy the old keg's `INSTALL_RECEIPT.json` into the asdf install
 dir, set `source.versions.stable` to the **keg string** (`26.11.1`,
 `3.14.8_2`).
2. Keg: `rm -rf` any stale keg dir, `ln -s ~/.asdf/installs/<plugin>/<ver>`
 under the new keg name (`Cellar/node/26.11.1`,
 `Cellar/python@3.14/3.14.8_2`).
3. `opt` pointers: `ln -sfn ../Cellar/node/26.11.1 /usr/local/opt/node`,
 `ln -sfn ../Cellar/python@3.14/3.14.8_2 /usr/local/opt/python@3.14`.
4. Unpinned both (`keg == stable` ⇒ nothing rebuilds when dependents ask).
5. Bin symlinks: `ln -sfn ../Cellar/node/26.11.1/bin/node
 /usr/local/bin/node` (and `python3.14`) — `brew link` reported
 "0 symlinks created", so create them by hand if missing.

Verified: `brew outdated node python@3.14` empty; `/usr/local/bin/<tool>
--version` correct; asdf shims resolve to the same versions.

One trap from this session: **hardlinked receipts**. A prior `cp -R` of the
asdf tree into a keg made the receipt in `~/.asdf/installs/...` the *same
file* as the old keg's — `cp` then fails with "are the same file". Harmless:
edit the file in place (the `jq > tmp && mv` pattern above) instead of
copying over it.

## Session 2026-10-21: node 26.11.1 → 26.12.0, bun 1.4.2 → 1.4.3

The last two runtimes moved to the versions brew asks for. Both were already
in the symlink pattern, just one release behind (`brew outdated` listed
node 26.11.1 → 26.12.0 and bun 1.4.2 → 1.4.3), and **both targets already
existed in asdf**, so the whole swap was zero-compile.

Per formula (node shown; bun is identical with plugin `bun`):

1. `~/.asdf/installs/<plugin>/<new>/` must have `bin/<tool>` — check before
   linking; a symlinked empty install makes brew believe the version exists
   while every command fails.
2. Copy the previous install's `INSTALL_RECEIPT.json` into the new install,
   then rewrite only `source.versions.stable` to the new keg string:
   ```bash
   cp ~/.asdf/installs/nodejs/26.11.1/INSTALL_RECEIPT.json \
      ~/.asdf/installs/nodejs/26.12.0/INSTALL_RECEIPT.json
   jq --arg v 26.12.0 '.source.versions.stable = $v' \
      ~/.asdf/installs/nodejs/26.12.0/INSTALL_RECEIPT.json > /tmp/r.json
   mv /tmp/r.json ~/.asdf/installs/nodejs/26.12.0/INSTALL_RECEIPT.json
   ```
3. `rm -f` the old keg **symlink** (not the asdf dir), then
   `ln -s ~/.asdf/installs/<plugin>/<new> /usr/local/Cellar/<formula>/<new>`.
4. `rm -rf /usr/local/opt/<formula>` **then** `ln -sfn ../Cellar/<formula>/<new> /usr/local/opt/<formula>`
   — `ln -sfn` into an existing directory nests the link inside it.
5. Bin links: `ln -sfn ../Cellar/node/26.12.0/bin/{node,npm,npx} /usr/local/bin/`.
   `npm`/`npx` were missing before this session (only `node` was linked), so
   non-asdf contexts (cron, GUI apps) had no npm at all.

New trap: **an inherited receipt can be missing the flags brew needs.**
bun's copied receipt had `poured_from_bottle: false` and
`installed_as_dependency: null` (17 top-level fields instead of 18) — brew
can then treat the keg as incomplete and rebuild it. Normalize after copying:

```bash
jq '.built_as_bottle = true | .poured_from_bottle = true
    | .installed_as_dependency = false | .installed_on_request = true' \
   ~/.asdf/installs/bun/1.4.3/INSTALL_RECEIPT.json > /tmp/r.json
mv /tmp/r.json ~/.asdf/installs/bun/1.4.3/INSTALL_RECEIPT.json
```

**The decisive verification is the dry-run of a dependent, not `brew info`:**

```bash
brew outdated --json=v2 node bun          # empty
brew list --versions node bun             # node 26.12.0 / bun 1.4.3
brew install --dry-run pi-coding-agent
```

The dry-run must NOT list node under "Would install N dependency" and node
must be absent from "would build from source". After this swap it listed
only `cxxopts` (pi-coding-agent's own build dep) and
`pi-coding-agent 1.1.0 -> 1.3.0` as the one source build — node itself
never appears, so no 10-20 min compile.

Note the deliberate split: `~/.tool-versions` keeps the *interactive* pins
(nodejs 22.23.0, bun 1.4.2) while brew's kegs point at the *newest* asdf
installs, because brew dependents want "current stable". Both sets of asdf
installs are kept — old versions are never deleted.

## Session 2026-10-21 (evening): llvm@21 21.1.8 → 21.1.8_1, python@3.14 3.14.8_2 → 3.14.8_3

Two more revision bumps that would each have triggered a source build
(llvm: hours, python: minutes), plus two discoveries that change how the
swap must be done.

### llvm@21 — real build, so RENAME the keg (a third variant of the pattern)

`llvm@21` is a genuine 155-binary build with a valid receipt — not an asdf
swap, and not the hollow trick the unversioned `llvm` uses. A revision bump
(`21.1.8` → `21.1.8_1`) only changes the packaging revision, so the build is
still correct: rename it.

```bash
mv /usr/local/Cellar/llvm@21/21.1.8 /usr/local/Cellar/llvm@21/21.1.8_1
jq --arg v 21.1.8_1 '.source.versions.stable = $v' \
   /usr/local/Cellar/llvm@21/21.1.8_1/INSTALL_RECEIPT.json > /tmp/r.json
mv /tmp/r.json /usr/local/Cellar/llvm@21/21.1.8_1/INSTALL_RECEIPT.json
rm -rf /usr/local/opt/llvm@21
ln -sfn ../Cellar/llvm@21/21.1.8_1 /usr/local/opt/llvm@21
```

Verified: `brew list --versions llvm@21` → `21.1.8_1`, `brew outdated
llvm@21` → empty, `clang --version` → 21.1.8. No dependents and no
`/usr/local/bin` links reference llvm@21, so nothing else needed fixing.

### python@3.14 — asdf-backed keg, so RENAME THE LINK and rewrite the receipt

Same shape as node/bun: the keg is a symlink to the asdf install, and the
revision lives in the link's name and in the receipt inside the asdf dir.

```bash
rm -f /usr/local/Cellar/python@3.14/3.14.8_2
ln -s ~/.asdf/installs/python/3.14.8 /usr/local/Cellar/python@3.14/3.14.8_3
jq --arg v 3.14.8_3 '.source.versions.stable = $v' \
   ~/.asdf/installs/python/3.14.8/INSTALL_RECEIPT.json > /tmp/r.json
mv /tmp/r.json ~/.asdf/installs/python/3.14.8/INSTALL_RECEIPT.json
rm -rf /usr/local/opt/python@3.14
ln -sfn ../Cellar/python@3.14/3.14.8_3 /usr/local/opt/python@3.14
ln -sfn ../Cellar/python@3.14/3.14.8_3/bin/python3.14 /usr/local/bin/python3.14
```

Verified: `brew list --versions python@3.14` → `3.14.8_3`, `brew outdated
python@3.14` → empty, `python3.14 --version` → 3.14.8, asdf's own python
pin (3.14.8) untouched.

### Discovery: the earlier python swap silently deleted its dependents' modules

`brew uses --installed python@3.14` → asciidoc, awscli, gobject-introspection,
meson, sphinx-doc. But the asdf install's site-packages contains **only pip**
— the brew-written modules for those five are GONE, because they lived in the
old real keg (`3.14.8_2` as a directory) and were deleted when it was
replaced by the symlink. Current state:

- `awscli`, `sphinx-doc`, `gobject-introspection` — no binary at all
- `meson` — binary present, tracebacks (its module is missing)
- `asciidoc` — self-contained, works

**Rule for the next python-keg swap:** before removing the old keg, copy its
`lib/python3.14/site-packages` into the asdf install (that is where brew
writes the modules now), or reinstall the dependents afterwards. Same trap
as the "kegs host dependents' site-packages" note above, with the twist that
here the data was lost rather than moved.

### This brew version's CLI gaps

`brew reinstall --dry-run`, `brew install --force-reinstall` and
`brew upgrade --skip-dependencies` are all rejected ("invalid option").
Plan with `brew upgrade --dry-run <formula>` (works), and use
`brew install --ignore-dependencies` / plain `brew reinstall` for the rest.
`brew link node` created 22959 symlinks (the whole npm-globals tree from the
asdf install) — it does not clobber pre-existing
`/usr/local/lib/node_modules/{eslint,npm}` because it skips existing files
without `--overwrite`.

### Also: formula name != binary name

`pi-coding-agent` installs a binary called **`pi`**
(`/usr/local/bin/pi -> ../Cellar/pi-coding-agent/1.1.0/bin/pi`). "command not
found: pi-coding-agent" is expected, not a broken install.

## Session 2026-10-21 (late): the network firewall decides what can be built

Before touching anything, map what the machine can actually reach. Result
(2026-10-21):

| Host | Reachable | Consequence |
|------|-----------|-------------|
| `github.com`, `raw.githubusercontent.com`, release asset CDN | yes | brew's own tarball downloads, and **release binaries** work |
| `registry.npmjs.org` | yes | npm-based formulae build (pi-coding-agent ✓) |
| `proxy.golang.org` + every mirror (goproxy.cn, aliyun, bj, gonexus) | **no** | Go builds that fetch modules fail (gh's `make licenses` step) |
| `golang.org` | **no** | `GOPROXY=direct` does NOT help - vanity paths need it |
| `crates.io`, `static.crates.io` | **no** | Rust builds fail (atuin) |
| `objects.githubusercontent.com` | yes | cask/app downloads fine (draw-things ✓, 245 MB) |

`GOPROXY`/`GOSUMDB` env vars do not survive Homebrew's build sandbox anyway
(they are filtered out); `go env -w` in Go's own config file does — but that
still fails here because of `golang.org`.

**Go formulae that vendor their dependencies still build fine** (lazygit
0.66.2 in 19 s, omp 18.12.5, engram 3.5.1, gentle-ai 4.2.0 - all vendored).

### New swap variant: the official RELEASE BINARY instead of a source build

When crates.io/proxy.golang.org are firewalled but GitHub is reachable, a
formula with official release assets can be swapped the same way as the
asdf-backed runtimes - with the release binary standing in for the build.
Done for **gh 2.102.1** and **atuin 18.24.1**:

1. Download the release asset and **verify the sha256** when the project
   publishes one (atuin does; gh does not):
   ```bash
   curl -sSL -O https://github.com/atuinsh/atuin/releases/download/v18.24.1/atuin-x86_64-apple-darwin.tar.gz
   curl -sSL -O .../atuin-x86_64-apple-darwin.tar.gz.sha256
   shasum -a 256 atuin-x86_64-apple-darwin.tar.gz   # must match the .sha256
   ```
   gh ships macOS assets as **`.zip`** (`gh_2.102.1_macOS_amd64.zip`), not
   tar.gz - the guessed `.tar.gz` URL returns a 9-byte "Not Found".
2. `cp -R` the old keg to the new version name, then replace the payload:
   ```bash
   cp -R /usr/local/Cellar/gh/2.102.0 /usr/local/Cellar/gh/2.102.1
   chmod u+w /usr/local/Cellar/gh/2.102.1/bin/gh      # <-- see trap below
   cp <release>/bin/gh /usr/local/Cellar/gh/2.102.1/bin/gh
   rm -rf <keg>/share/man/man1 && cp -R <release>/share/man/man1 <keg>/share/man/man1
   ```
3. Receipt + links, same as every other swap:
   ```bash
   jq --arg v 2.102.1 '.source.versions.stable = $v' <keg>/INSTALL_RECEIPT.json > /tmp/r.json
   mv /tmp/r.json <keg>/INSTALL_RECEIPT.json
   rm -rf /usr/local/opt/gh && ln -sfn ../Cellar/gh/2.102.1 /usr/local/opt/gh
   ln -sfn ../Cellar/gh/2.102.1/bin/gh /usr/local/bin/gh
   ```
4. Remove the superseded keg only after the new one verifies
   (`gh --version`, `brew outdated gh` empty).

**Trap: Homebrew keg files are read-only (444).** A plain `cp` over an
existing keg file fails with "Permission denied" - `chmod u+w` first (the
copy inherits the old mode).

**Trap: gh's macOS asset naming** - `.zip` and `macOS` (not `darwin`) in the
filename.

### python@3.14's dependents now demand python@3.15

The four broken formulae (awscli, meson, sphinx-doc, gobject-introspection)
have newer versions that depend on **python@3.15**, which is not installed -
upgrading them would trigger a python@3.15 source build (the exact long
compile this whole setup exists to avoid). The fix that avoids it:
**reinstall at the current version** (`brew reinstall awscli meson
sphinx-doc gobject-introspection`) so their modules are written back into the
python@3.14 keg (which is the asdf install) without changing any dependency.

### Other notes from this session

- `brew upgrade <formula>` also upgrades that formula's outdated
  dependencies (node's aws-c-*/simdjson C deps showed up). There is no
  `--skip-dependencies` in this brew version, so expect the extra churn.
- `brew cleanup <formula>` (scoped to one formula) is safe; the global
  `brew cleanup` is still forbidden by this document. Scoping it to
  engram/gentle-ai/omp freed 511 MB of superseded tap kegs.
### The cask path is unaffected by the firewall: `brew upgrade --cask
  draw-things` pulled 26.1013.0-9bb6696f fine.

## Session 2026-10-21 (night): rust via rust-lang's standalone installer

brew's `rust` was unusable: its `rustc` links
`/usr/local/opt/llvm/lib/libLLVM.23.1.dylib`, and the llvm keg is hollow
(no `lib/` at all) → `rustc` aborted with
`dyld: Library not loaded ... libLLVM.23.1.dylib` and every cargo build
died at `cargo fetch`. llvm cannot be fixed cheaply here: **no bottle for
any platform**, and upstream publishes **no macOS x86_64 asset for any
23.1.x** (checked 23.1.0 - 23.1.4) → a source-built llvm is 1-3 h.
llvm@21 is not a substitute (ABI mismatch:
`Symbol not found: __ZN4llvm10PGOOptions...`).

Solution: rust-lang's own **standalone installer** (see
https://forge.rust-lang.org/infra/other-installation-methods.html) - a
self-contained toolchain that does not need Homebrew's llvm at all
(its `rustc` uses `@rpath/libLLVM.dylib`).

```bash
V=1.99.1
curl -sSLO https://static.rust-lang.org/dist/rust-$V-x86_64-apple-darwin.tar.xz
curl -sSLO https://static.rust-lang.org/dist/rust-$V-x86_64-apple-darwin.tar.xz.sha256
shasum -a 256 rust-$V-x86_64-apple-darwin.tar.xz   # must equal the .sha256
tar xf rust-$V-x86_64-apple-darwin.tar.xz
cd rust-$V-x86_64-apple-darwin
./install.sh --prefix=/usr/local/Cellar/rust/$V --disable-ldconfig
```

Then the usual swap bookkeeping (the keg name must equal the formula's
stable version, `1.99.1`):

```bash
cp <old keg>/INSTALL_RECEIPT.json /usr/local/Cellar/rust/1.99.1/
jq --arg v 1.99.1 '.source.versions.stable = $v' \
   /usr/local/Cellar/rust/1.99.1/INSTALL_RECEIPT.json > /tmp/r.json && mv /tmp/r.json ...
rm -rf /usr/local/opt/rust && ln -sfn ../Cellar/rust/1.99.1 /usr/local/opt/rust
for b in cargo cargo-clippy cargo-fmt clippy-driver rust-analyzer rust-gdb \
         rust-gdbgui rust-lldb rustc rustdoc rustfmt; do
  ln -sfn ../Cellar/rust/1.99.1/bin/$b /usr/local/bin/$b
done
mv /usr/local/Cellar/rust/1.99.0_1 /tmp/rust-keg-1.99.0_1-backup   # broken build
```

**The llvm dependency still bites:** brew's rust formula depends on llvm,
and llvm's stable is now `23.1.4` while the hollow keg was named `23.1.3`
→ any brew operation touching rust would try to install llvm (1-3 h
build). Fix the NAME, not the content:

```bash
ln -sfn 23.1.3 /usr/local/Cellar/llvm/23.1.4      # 23.1.3 -> 23.1.0 (dangling)
mkdir -p /usr/local/Cellar/llvm/23.1.0            # the target never existed
# ...and drop a receipt claiming stable 23.1.4 into it
rm -rf /usr/local/opt/llvm && ln -sfn ../Cellar/llvm/23.1.4 /usr/local/opt/llvm
```

Verified after the swap: `rustc 1.99.1`, `cargo 1.99.1`, `rustfmt 1.10.0`,
`brew list --versions rust` → `1.99.1`, `brew outdated rust llvm` → empty,
and `otool -L rustc` shows `@rpath/libLLVM.dylib` (no Homebrew llvm).

The old broken keg (442 MB) was moved to
`/tmp/rust-keg-1.99.0_1-backup` rather than deleted - it can be removed
once you are happy with the standalone toolchain. rustup is still
installed (`/usr/local/bin/rustup`, toolchain in `~/.rustup`) and is now
redundant: `~/.cargo/bin` holds no rust shims, so `/usr/local/bin` (the
standalone install) wins in PATH.

### Bonus: atuin is now a genuine source build

With a working cargo, brew's own route was tried first and failed:
`brew reinstall --build-from-source atuin` first wants to upgrade the
dependency **z3 5.1.0 → 5.3.1** (a large C++ source build) and dies with
`Error: atuin: An exception occurred within a child process` - and it has
already removed the old binary by then, so the tool is left missing.

Two lessons from that:

- **A failed `brew reinstall`/`reinstall --build-from-source` leaves the
  formula unbuilt and gone.** Keep a binary backup before forcing one.
- **brew pulls outdated dependencies into the build**, even for a
  `--build-from-source` target, so one stale C++ dep can sink an
  otherwise-hours build.

Building from the crate directly skips the dependency dance (z3 5.1.0 is
already installed and `pkg-config --modversion z3` resolves, so atuin
links against it):

```bash
curl -sSL -o atuin.crate https://crates.io/api/v1/crates/atuin/18.24.1/download
tar xzf atuin.crate && cd atuin-18.24.1
cargo build --release --locked        # 7m04s, needs cmake + ninja + z3
cp target/release/atuin "$(brew --prefix)/Cellar/atuin/18.24.1/bin/atuin"
```

Verified: `atuin 18.24.1 (NO_GIT)` - `NO_GIT` is the marker of a build
from the crate tarball (the GitHub release build reports a commit hash
like `(c58d2e993d05be423315f6ae3739e9ab3e45eea5)`). `atuin history list`
works, `brew outdated atuin` is empty.

## Session 2026-10-22: node 26.12.0 -> 26.12.1, bun 1.4.3 -> 1.4.4, python@3.14 3.14.8_3 -> 3.14.9

All three were already in the symlink pattern, but **the symlinks had gone
stale**: asdf no longer had `nodejs/26.12.0` or `bun/1.4.3`, so the keg
symlinks pointed at nothing.

**New trap - a dangling keg symlink makes brew report NO version at all:**

```
$ brew list --versions node bun python@3.14
bun
node
python@3.14 3.14.8_3
```

`brew list --versions` prints the formula name with an *empty* version for
node and bun, and `brew outdated` does **not** list them either - brew
cannot read a version out of a broken symlink, so the formula looks
installed-but-versionless rather than outdated. Nothing warns you; the
keg just quietly stops counting as installed. Check with
`readlink /usr/local/Cellar/<formula>/*` that the target still exists.

The same session also showed that `asdf install` **does not write a
receipt**: none of the asdf installs had `INSTALL_RECEIPT.json` except the
two that had been swapped before (the receipt is copied in by hand during
a swap, it is not produced by asdf).

All three targets already existed in asdf, so the whole swap was
zero-compile:

| formula | old keg | new keg | asdf target |
|---|---|---|---|
| `node` | `26.12.0` (dangling) | `26.12.1` | `~/.asdf/installs/nodejs/26.12.1` |
| `bun` | `1.4.3` (dangling) | `1.4.4` | `~/.asdf/installs/bun/1.4.4` |
| `python@3.14` | `3.14.8_3` | `3.14.9` | `~/.asdf/installs/python/3.14.9` |

Steps per formula (all three, in order):

1. Write `INSTALL_RECEIPT.json` into the asdf install. There is no node/bun
   receipt left to copy (both asdf dirs were replaced), so the receipt was
   **built from brew's own metadata** instead: `brew info --json=v2` gives
   `versions.stable`, `tap` and the dependency list; the previous
   python@3.14 receipt supplied the remaining top-level fields. The two
   fields that matter for the "don't rebuild" behaviour:
   `poured_from_bottle: true` and `installed_as_dependency: false`, plus
   `source.versions.stable` = the keg string.
2. `rm -f` the old keg **symlink** (never the asdf dir) and
   `ln -s ~/.asdf/installs/<plugin>/<ver> /usr/local/Cellar/<formula>/<ver>`.
3. Repoint the opt link: `ln -sfn ../Cellar/<formula>/<ver> /usr/local/opt/<formula>`.
4. Repoint the bin symlinks by hand (`brew link` reports "0 symlinks
   created" for symlinked kegs): `node`, `npm`, `npx`, `bun`, `python3.14`.

Note `python@3.14`'s aliases: `brew info --json=v2` returns an empty
`aliases` list for versioned formulae, so the receipt keeps the known set
(`python`, `python3`, `python@3`) from the previous receipt.

Verified after the swap:

```
$ brew outdated --json=v2 node bun python@3.14      # empty
$ brew list --versions node bun python@3.14
bun 1.4.4
node 26.12.1
python@3.14 3.14.9
$ /usr/local/bin/node --version        # v26.12.1
$ /usr/local/bin/bun --version         # 1.4.4
$ /usr/local/bin/python3.14 --version  # Python 3.14.9
$ brew list --pinned                    # empty: node must stay unpinned
```

asdf's own shims still win on PATH and resolve to the global
`tool-versions` pins (nodejs 22.23.0, bun 1.4.4, python 3.14.9) - brew's
node 26.12.1 is the fallback for anything that bypasses the shims.

## Session 2026-10-23: ruby 4.0.8 -> asdf ruby 4.0.7, plus a brew upgrade batch

### ruby: brew 4.0.8 pointed at asdf 4.0.7

brew had built a **real** ruby 4.0.8 keg (115 MB) that morning. Same swap
as node/bun/python, only the direction is reversed: the asdf install is
*older* than the formula's stable version.

- keg name = brew's stable = `4.0.8`
- keg symlink target = `~/.asdf/installs/ruby/4.0.7` (the actual binaries)
- the receipt in the asdf install must claim `4.0.8`, so brew sees it as
  current and does not rebuild

The real build was **moved, not deleted** (same as the rust session):

```
mv /usr/local/Cellar/ruby/4.0.8 /tmp/ruby-keg-4.0.8-backup
ln -s ~/.asdf/installs/ruby/4.0.7 /usr/local/Cellar/ruby/4.0.8
```

`opt/ruby` and the bin symlinks (`ruby`, `gem`, `irb`, `rake`, `bundle`,
`bundler`, `erb`, `rdoc`, `ri`) already pointed at `../Cellar/ruby/4.0.8`
and kept working through the symlink.

Verified: `brew list --versions ruby` -> `ruby 4.0.8`, `brew outdated ruby`
empty, `ruby --version` -> `ruby 4.0.7 (2026-09-15)`, `gem` -> 4.0.20,
`bundle` -> 4.0.22, ruby still unpinned. Note the version skew on purpose:
**brew calls it 4.0.8, the binary is 4.0.7** - the same trap as every
other entry here, so check the real binary, not brew's number.

### The upgrade batch

```
atuin            18.24.2     (already current, no action)
engram           3.5.1  -> 3.5.2
gh               2.102.1 -> 2.103.0
omp              18.12.5 -> 18.12.6
pi-coding-agent  1.3.0  -> 1.4.0     (the binary is `pi`, not pi-coding-agent)
luajit           2.1.1791988261 -> 2.1.1792588164
bitwarden        2026.8.0 -> 2026.10.1        (cask)
draw-things      26.1013.0 -> 26.1020.0       (cask)
whatsapp         26.41.14 -> 26.42.19         (cask)
crystal          1.21.1_1 -> 1.22.1            (ABORTED - see below)
```

### crystal: three separate traps, all worth knowing

**1. The hollow `llvm` keg breaks *linking*, not just running.** crystal
depends on `llvm`, and the formula sets `ENV["LLVM_CONFIG"] =
llvm.opt_bin/"llvm-config"`. Pointing `opt/llvm` at the real llvm@21 build
gets a working `llvm-config` (21.1.8, and crystal 1.22 supports 21.1 -
its Makefile lists `24 23.1 22.1 21.1 20.1 ...`), but brew's link flags
point at the **keg** path `/usr/local/Cellar/llvm/23.1.0/lib`, and that
keg is hollow:

```
ld: library 'LLVM-21' not found
```

`libLLVM-21.dylib` exists in llvm@21 all the same - the linker was
searching a directory that has no `lib` at all. Repointing the keg
(`23.1.0 -> ../llvm@21/21.1.8_1`) satisfies the linker.

**2. The build bootstraps with the *system* `crystal`.** crystal's
Makefile shells out to whatever `crystal` is on PATH - and the installed
1.21.1_1 is itself broken, for the same reason:

```
dyld: Library not loaded: /usr/local/opt/llvm/lib/libLLVM.23.1.dylib
```

So the build dies before it starts. The fix is to bootstrap with the
prebuilt **boot** compiler the formula downloads
(`crystal--boot--1.18.2-1.tar.gz`) and to export `LLVM_CONFIG` for
`make deps`:

```bash
export LLVM_CONFIG=/usr/local/opt/llvm/bin/llvm-config
export PATH="<unpacked>/crystal-1.18.2-1/bin:$PATH"   # boot compiler first
make deps
CRYSTAL_CONFIG_LIBRARY_PATH='$ORIGIN/../../../../lib' \
CRYSTAL_CONFIG_PATH='$ORIGIN/../share/crystal/src' \
make crystal release=true FLAGS=--no-debug interpreter=true
```

With that, the build **does** get past the LLVM link (only the usual
`REFERENCED_DYNAMICALLY` deprecation warnings). It was stopped there on
purpose (2026-10-23); the manual build is the way to finish crystal
without brew's build environment in the way.

**3. `brew upgrade` leaves the old version in place when the build
fails** - crystal 1.21.1_1 survived both failed attempts. That is the
good case; the bad case is the doc's existing warning that a failed
`reinstall` can remove the formula entirely.

**Not fixed by any of this:** crystal 1.21.1_1 still cannot run - it
wants `libLLVM.23.1.dylib` and only LLVM 21 exists on this machine.
Until crystal is rebuilt, `crystal` is a broken command, exactly as it
was before this session.

### Note: "You have unlinked kegs in your Cellar" (2026-10-23)

Brew warns about unlinked kegs for **node, bun, python@3.14 and rust** -
the four whose kegs are symlinks into asdf (or the standalone rust install).
Brew cannot link a symlinked keg the normal way, so it never wrote the
marker it uses to track linked state:

```
/usr/local/var/homebrew/linked/<formula>/     # one dir per linked formula
```

`brew doctor`'s check is literally `next true if
(HOMEBREW_LINKED_KEGS/rack.basename).directory?` - so the warning is
purely about the missing marker, not about the binaries.

Fix (what `brew link` does, minus the churn):

```bash
brew link node bun python@3.14 rust
```

Two things to know before running it on this layout:

- **The keg symlinks must not already exist**, or brew stops with
  `Could not symlink bin/<x> ... already exists`. Delete the hand-made
  `/usr/local/bin` links first and let brew recreate them.
- **python@3.14 and python@3.15 both provide `python3`, `idle3` and
  `python3-config`.** Linking 3.14 with `--overwrite` takes those from
  3.15; re-point them afterwards to keep 3.15 as the system default:
  ```bash
  for b in python3 idle3 python3-config; do
    ln -sfn ../Cellar/python@3.15/3.15.0_1/bin/$b /usr/local/bin/$b
  done
  ```

**Side effect to check:** `brew link node` links the whole keg's
`lib/node_modules`, so asdf's npm globals (eslint, prettier, stylelint,
tsc, vls) get symlinked into `/usr/local/lib/node_modules` - shadowing
the `npm` formulae this Brewfile pins. Link *without* `--overwrite` so
brew skips the files that already exist, and restore the ones it did
replace from a snapshot taken beforehand.

Afterwards: `brew doctor` reports no unlinked kegs, and node/bun/
python@3.14/rust are all linked.

## Session 2026-10-23 (later): llvm is compiled ONCE, parked, and symlinked forward

The `brew install crystal` attempt (2026-10-23) failed and took the real
LLVM with it: brew's rollback **deleted `/usr/local/Cellar/llvm@21/21.1.8_1`**
- the 155-binary real build that had been there since 2026-10-09 - and left
`/usr/local/Cellar/llvm/23.1.4` as a **dangling** symlink. Two consequences:

```
Errno::EEXIST: File exists @ dir_s_mkdir - /usr/local/Cellar/llvm/23.1.4
```

- brew wanted to install llvm (the dangling keg had no receipt, so
  `any_version_installed?` was false) and could not, because the symlink was
  in the way;
- `brew list --versions llvm` had started reporting a version whose keg did
  not exist.

### The rule now

**llvm is compiled once per version, parked outside brew's reach, and the
Cellar entry is only a symlink that moves forward.** Nothing is ever deleted:

```
~/.local/opt/llvm-builds/23.1.4/                      <- the compiled build (kept forever)
/usr/local/Cellar/llvm/23.1.4 -> ~/.local/opt/llvm-builds/23.1.4
/usr/local/opt/llvm -> ../Cellar/llvm/23.1.4
/usr/local/lib/libLLVM-23.dylib -> ~/.local/opt/llvm-builds/23.1.4/lib/libLLVM-23.dylib
```

The build lives **outside `/usr/local/Cellar`** - in `~/.local/opt`, which is
user-owned and invisible to brew. `brew cleanup` cannot remove it, and a
failed install's rollback cannot either. Only the *symlink* in
`Cellar/llvm/` is brew's to move or remove, which is exactly what should
happen.

**Do not park the build inside `Cellar/` - not even in a dot-directory.**
The first attempt used `Cellar/.llvm-builds/`, and brew enumerated it as a
*formula name* and aborted the crystal upgrade with:

```
Error: crystal: No available formula with the name '.llvm-builds'.
```

brew walks `/usr/local/Cellar/*` and treats every directory there as a
formula. Anything that is not a formula - a build, a spare keg, a scratch
directory - must live outside it. (`/usr/local` itself is root-owned, so
`~/.local/opt` is the writable spot that also matches this machine's
`~/.local` convention.)

This is the same doctrine as node/bun/python/ruby, with one difference:
those point at an asdf install that someone else maintains; llvm has no
asdf plugin, so the build is ours and it has to be parked by hand.

### Bumping to a new llvm

```bash
# 1. compile the new version (~1 h on this machine)
brew install llvm

# 2. park it and re-point the symlink (old builds stay put)
packages/llvm/park-llvm.sh

# 3. verify every preserved build is still intact
packages/llvm/check-llvm-keg.sh
```

`park-llvm.sh` moves `Cellar/llvm/<new>` to
`~/.local/opt/llvm-builds/<new>`, replaces it with the symlink, and
re-points `opt/llvm` and `lib/libLLVM-<major>.dylib`. The previously
compiled build keeps running from `~/.local/opt/llvm-builds/<old>` - which
is what "never delete that version" means here. If the new version is
broken, re-point the symlink at the old one and carry on.

### What crystal needs

crystal's Makefile accepts LLVM `24 23.1 22.1 21.1 20.1 19.1 ...`, so
brew's current stable (23.1.4) is exactly right - **provided it is a real
build**. With the hollow keg the link failed with:

```
ld: library 'LLVM-21' not found
```

because brew's link flags point at `Cellar/llvm/<version>/lib`, and the
hollow keg had no `lib` at all. A real build in that path fixes it.

Note: upstream LLVM publishes a **macOS X64** prebuilt only for older
releases (19.1.7 has one; 20.1.8 and 21.1.8 are ARM64-only), so for 23.x
there is no prebuilt to fall back on - it has to be compiled.

With a *real* build the failure changes shape: the compiler link now asks for
`-lLLVM-23` but the `-L` to llvm's lib dir does not survive the build
(crystal's Makefile puts the `llvm-config` call in backticks, and the boot
compiler's link line never got the resulting `-L`), so the build died with:

```
ld: library 'LLVM-23' not found
```

`/usr/local/lib` **is** in that link's search list, so the fix is the
versioned dylib in the default search path:

```
/usr/local/lib/libLLVM-23.dylib -> ~/.local/opt/llvm-builds/23.1.4/lib/libLLVM-23.dylib
```

(`/usr/local/lib/libLLVM.dylib` is a *different* file - rust's own bundled
LLVM. Do not confuse the versioned and unversioned names.) With that in
place crystal 1.22.1 built and reports `LLVM: 23.1.4`.

### The 23.1.4 build (2026-10-23)

`brew install llvm` compiled from source in **54 minutes** (not the 1-3 h the
earlier notes feared), exit code 0:

```
/usr/local/Cellar/llvm/23.1.4/bin/llvm-config --version   ->  23.1.4
lib/libLLVM-23.dylib, lib/libLLVM-C.23.1.dylib             ->  present
keg size                                                 ->  1.6 G
```

Then `park-llvm.sh` moved the build out of the Cellar and left the symlink:

```
~/.local/opt/llvm-builds/23.1.4/                    <- real build, 1.6 G
/usr/local/Cellar/llvm/23.1.4 -> ~/.local/opt/llvm-builds/23.1.4
/usr/local/opt/llvm        -> ../Cellar/llvm/23.1.4
```

`brew list --versions llvm` -> `llvm 23.1.4`, `brew outdated llvm` -> empty.
Note brew's own receipt for a source build carries no `stable` key; the
check that matters is `any_version_installed?`, which only requires
`INSTALL_RECEIPT.json` to exist inside the keg - and it does (it moved with
the build).

**Never leave a dangling symlink in `Cellar/llvm/`.** That is what produced
the `Errno::EEXIST`: the symlink pointed at a directory that no longer
existed, brew decided llvm was uninstalled, and `mkdir` on the symlink path
failed. If a build is moved, the symlink must be re-pointed in the same step.
