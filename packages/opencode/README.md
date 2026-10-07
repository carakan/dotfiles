# opencode config

Config, agents, skills and plugins for opencode. Linked per-file into
`~/.config/opencode/` by `install.conf.yaml`; `opencode.json` itself is **not**
linked because it holds a local apiKey (same pattern as the gh hosts.yml).

## Install

The CLI is **not** a Homebrew formula. opencode 2.x is source-only on the brew
side — no Intel bottle, and the build pulls the whole `llvm → rust → bun → zig`
chain from source, which fails repeatedly. Install the prebuilt binary instead:

```sh
npm install -g @opencode/cli      # 2.x — ships @opencode/cli-darwin-x64
```

`brew "opencode"` in the repo `Brewfile` is commented out for this reason.
If homebrew-core ever ships an Intel bottle for 2.x, brew is the better option
again and the comment should go.

### Under asdf: install once per nodejs version

asdf keeps **no** global npm directory. `npm -g` writes into the *active*
nodejs install, and the `~/.asdf/shims/opencode` shim resolves against whichever
version the nearest `.tool-versions` selects. So a per-project pin like
`trm/.tool-versions` (`nodejs 24.7.0`) hides a package installed under the
global pin (22.23.0) and yields:

```
No version is set for command opencode
Consider adding one of the following versions in your config file at
  /Users/carakan/development/nodejs/trm/old-changes/.tool-versions
nodejs 22.23.0
```

Nothing is wrong with opencode; the shim is just looking in the wrong version.
Install it into every nodejs version you actually use:

```sh
for v in 22.23.0 24.14.0 24.7.0; do
  ASDF_NODEJS_VERSION=$v npm install -g @opencode/cli
done
```

**Re-run that loop after `asdf install nodejs <new-version>`**, or the new
version's trees will fail the same way. Verify with:

```sh
for v in 22.23.0 24.14.0 24.7.0; do
  printf '%s: ' "$v"
  ls -d ~/.asdf/installs/nodejs/$v/lib/node_modules/@opencode/cli 2>/dev/null \
    || echo MISSING
done
```

## The 2.x plugin contract

2.x replaced the 1.x plugin API. A plugin's default export must be an **object**
produced by `Plugin.define`:

```ts
// 1.x (dead)                          // 2.x (current)
import type { Plugin }                 import { Plugin } from "@opencode/plugin"
  from "@opencode-ai/plugin"
const P: Plugin = async (input) => ({    export default Plugin.define({
  "tool.execute.after": async () => {},   id: "my-plugin",
})                                        setup: (ctx) => { /* ... */ },
export default P                        }
                                       })
```

Notes that cost real debugging time:

- **`@opencode/plugin`, not `@opencode-ai/plugin`.** The old package is frozen
  at 1.18.34 and will never gain 2.x.
- **Use the promise flavour.** `@opencode/plugin` wants `setup: (ctx) => ...`.
  The sibling `@opencode/plugin/effect` wants `effect:` returning an Effect, and
  opencode's loader **rejects** it with
  `Plugin must export a default definition with an id and an effect or setup
  function (Expected object at ["default"])`. The promise form is the one the
  loader validates.
- **`setup` may return a `Cleanup`.** Return one only if you allocate something
  that needs tearing down.
- **Context renames.** `input.directory` / `input.worktree` are both
  `ctx.location.directory` (an already-resolved absolute path — no `process.cwd()`
  fallback needed). `input.client.provider.list()` is `ctx.provider.list()` /
  `ctx.model.list()`; `ctx.model.list()` returns a **flat** array of models, each
  with `providerID`, `id` and `variants` (an array of `{ id, ... }`).
- **Runtime imports must resolve from the repo dir.** `plugins/` is a symlink
  into `.dotfiles`, so a bare `import "some-dep"` resolves relative to
  `packages/opencode/`, not `~/.config/opencode/`. That directory needs its own
  `npm install` — which is why `packages/opencode/package.json` exists. A
  missing runtime dep surfaces only as the generic LoadError above.

Check what actually loaded:

```sh
grep "failed to load plugin" ~/.local/share/opencode/log/opencode.log | tail
```

Note that opencode runs a **persistent background service**
(`opencode.exe serve --service`). Plugin modules are cached by that process, so
after editing a plugin, `pkill -f "opencode.exe serve"` or your change will not
be picked up — which masquerades as "my fix did nothing".

## Plugins

| Plugin | Status | What it does |
|---|---|---|
| `skill-registry.ts` | ported to 2.x | On startup runs `gentle-ai skill-registry refresh` for the current project, so the repo's skill index stays current. |
| `model-variants.ts` | ported to 2.x | Writes `~/.gentle-ai/cache/model-variants.json` — per-model effort levels, so gentle-ai can populate its picker offline. Output shape is deliberately unchanged from 1.x, since gentle-ai consumes it directly. |
| `review-result-artifacts.ts` | **1.x only** | Persists artifacts from the `review-*` subagents. Fails to load under 2.x. |
| `local-glm-fallback.ts` | **1.x only** | Routes mechanical work to a local llama.cpp model. Fails to load under 2.x; currently inert anyway (no server on :8080). |

## engram: MCP only

`engram.ts` was **deleted**. It talked to `engram serve` over HTTP on port 7437,
which nothing was listening on. `opencode.json` already runs engram as an MCP
server (`engram mcp --tools=agent`), which provides 19 `mem_*` tools directly —
more than the 13 the plugin hardcoded — with no plugin in the way.

The `mem_*` calls in `skills/sdd-*` are tool calls, so they work over MCP
unchanged. `~/.engram/engram.db` is that MCP server's live database; do not
delete it. The `engram` **binary** is still a Brewfile dependency for the same
reason.
