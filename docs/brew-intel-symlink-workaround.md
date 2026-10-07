# Homebrew on Intel macOS: asdf symlink workaround

Applies to: Intel x86_64, macOS 15.8 Sequoia, Homebrew at `/usr/local`
Set up: 2026-10-06

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
/usr/local/Cellar/llvm/23.1.2    -> llvm/23.1.0                     (pinned)
/usr/local/Cellar/node/26.10.0_2 -> ~/.asdf/installs/nodejs/26.10.0 (v26.10.0)
/usr/local/Cellar/ruby/4.0.7     -> ~/.asdf/installs/ruby/4.0.7    (ruby 4.0.7)
```

Old (possibly corrupt, outdated-revision) kegs were purged:

```
brew uninstall --force --ignore-dependencies node
rm -rf /usr/local/Cellar/ruby/4.0.6_1
```

Supporting pieces, all required:

- `/usr/local/opt/<formula>` must point at the **current** keg
  ```bash
  ln -sfn ../Cellar/node/26.10.0_2 /usr/local/opt/node
  ```
- each asdf install needs a valid `INSTALL_RECEIPT.json`, or Homebrew treats the keg as
  incomplete and rebuilds it
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

- `llvm` can stay pinned - nothing needs to relink it
- `node` and `ruby` must stay **unpinned**, or installs of dependents fail

Pinning them does hide them from `brew outdated`, but that is cosmetic and not worth
blocking installs.

## Verify

```bash
# should print nothing
brew outdated --json=v2 node ruby llvm

# what brew thinks is installed
brew list --versions node ruby llvm

# binaries must report their real version
/usr/local/Cellar/node/26.10.0_2/bin/node --version   # v26.10.0
/usr/local/Cellar/ruby/4.0.7/bin/ruby --version       # ruby 4.0.7
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

## Removing the workaround

To be undone in a few months, once bottled builds exist for a supported Mac:

```bash
rm /usr/local/Cellar/llvm/23.1.2
rm /usr/local/Cellar/node/26.10.0_2
rm /usr/local/Cellar/ruby/4.0.7

# receipts written into asdf installs must go too
rm ~/.asdf/installs/nodejs/26.10.0/INSTALL_RECEIPT.json
rm ~/.asdf/installs/ruby/4.0.7/INSTALL_RECEIPT.json

brew unpin llvm
brew install node ruby llvm    # real source builds (hours)
```

Then confirm nothing broke:

```bash
node --version && ruby --version && rustc --version && brew doctor
```

## Why these three

`llvm`, `node` and `ruby` are the only formulae here whose builds are long enough to matter
and whose versions asdf already carries. Everything else installed from bottle-equivalent
source or has a real bottle. See `Brewfile` for the full package list and
`packages/asdf` for the asdf version managers.