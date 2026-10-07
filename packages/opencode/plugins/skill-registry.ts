/**
 * skill-registry
 * Refreshes Gentle AI's project skill registry when OpenCode starts.
 *
 * Codex and Claude Code use native startup hooks for the same command. OpenCode
 * loads plugins at startup, so this plugin provides the equivalent behavior
 * without depending on shell interpolation or command-file parse-time cwd.
 *
 * 2.x port notes:
 *  - Default export is now `Plugin.define({ id, setup })` via @opencode/plugin.
 *    opencode validates plugin modules against the *promise* contract, which
 *    wants `setup: (ctx) => Promise<Cleanup | void>`; the Effect-flavoured
 *    `@opencode/plugin/effect` variant (which wants `effect`) is rejected with
 *    "Plugin must export a default definition with an id and an effect or
 *    setup function".
 *  - The 1.x `input.directory || input.worktree || process.cwd()` chain
 *    collapses to `ctx.location.directory`, which is already a resolved
 *    AbsolutePath for the location OpenCode is running against. The cwd
 *    fallback is no longer needed.
 *  - Still fire-and-forget: the command is fingerprint-cached, and blocking
 *    plugin load on a subprocess would slow every startup.
 */

import { Plugin } from "@opencode/plugin"
import { execFile } from "child_process"
import { promisify } from "util"

const execFileAsync = promisify(execFile)

async function refreshSkillRegistry(cwd: string) {
  try {
    await execFileAsync(
      "gentle-ai",
      ["skill-registry", "refresh", "--quiet", "--no-gitignore", "--cwd", cwd],
      { timeout: 30_000 },
    )
  } catch (err) {
    console.error("[skill-registry] refresh failed:", err)
  }
}

export default Plugin.define({
  id: "skill-registry",
  // Fire and forget: do not await the refresh, so plugin load stays fast.
  setup: (ctx) => {
    void refreshSkillRegistry(ctx.location.directory)
  },
})
