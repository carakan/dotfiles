/**
 * local-glm-fallback
 *
 * Routes small/medium opencode work to the local Qwen3.5-9B (llama.cpp at
 * 127.0.0.1:8080) when reachable, with automatic fallback to the primary
 * model when the local server is down. Saves cloud tokens; never breaks
 * titles/summaries/compaction.
 *
 * Behavior on startup:
 *  1. Probe http://127.0.0.1:8080/v1/models (1s timeout).
 *  2. If reachable:
 *       - Keep small_model = local GLM (set in opencode.json).
 *         - Inject a routing hint into primary-agent system prompts so the
 *         model prefers dispatching small/medium mechanical work to
 *         `qwen-local` over `general`.
 *  3. If unreachable:
 *       - Swap small_model to the primary model so titles/summaries still
 *         work (just using the expensive model).
 *       - Skip the routing hint (don't mislead the agent into dispatching
 *         to a worker that will fail).
 *
 * Limitations:
 *  - Probed once at startup. If the server comes up/goes down mid-session,
 *    behavior does not change until opencode restarts.
 *  - `small_model` is only swapped when it equals the local GLM model
 *    string, so user overrides are preserved.
 */

import type { Plugin } from "@opencode-ai/plugin"

const LOCAL_GLM_URL = "http://127.0.0.1:8080/v1/models"
const LOCAL_GLM_MODEL = "llamacpp/Qwen3.5-9B-UD-Q4_K_XL.gguf"
const PROBE_TIMEOUT_MS = 1000

const ROUTING_HINT = `## Local GLM Routing

When the local llama.cpp server is reachable at 127.0.0.1:8080, a zero-token-cost
worker named \`qwen-local\` (Qwen3.5-9B) is available for small/medium mechanical
tasks. Prefer dispatching to it via the \`task\` tool over \`general\` when the
task is one of:
  - A clear, unambiguous mechanical edit (rename symbol, apply known formatting)
  - Running a test suite and reporting results
  - Writing a small new file from a complete spec or template
  - A simple refactor with all decisions already made by you

Do NOT route to \`qwen-local\` for tasks that need architectural judgment,
multi-file design, debugging without a known cause, or interpretation of
vague requirements — those should go to \`general\` or stay in the primary agent.

If a \`qwen-local\` dispatch fails with a connection error, fall back to
\`general\` (or do it yourself for trivial work). Do not retry indefinitely.`

async function isLocalGlmAvailable(): Promise<boolean> {
  try {
    const res = await fetch(LOCAL_GLM_URL, {
      signal: AbortSignal.timeout(PROBE_TIMEOUT_MS),
    })
    return res.ok
  } catch {
    return false
  }
}

export const LocalGlmFallback: Plugin = async () => {
  const localAvailable = await isLocalGlmAvailable()

  return {
    config: async (cfg) => {
      // Cast: the typed schema doesn't expose these specific fields in
      // older plugin d.ts, but they're valid in the runtime config.
      const c = cfg as unknown as {
        small_model?: string
        model?: string
      }

      if (localAvailable) {
        // Set small_model to local GLM only if not already configured.
        // This means: opencode.json wins if it sets something else,
        // but a missing entry still gets a sensible default.
        if (!c.small_model) {
          c.small_model = LOCAL_GLM_MODEL
        }
      } else if (c.small_model === LOCAL_GLM_MODEL) {
        // Local server is down — fall back to the primary model so
        // small_model work (titles, summaries, compaction) still works.
        // Don't touch user-customized small_model values.
        c.small_model = c.model
      }
    },

    "experimental.chat.system.transform": async (_input, output) => {
      // Only inject the routing hint when local GLM is actually available.
      // Injecting otherwise would mislead the agent into dispatching work
      // that will fail with a connection error.
      if (!localAvailable) return

      if (output.system.length > 0) {
        // Append to the last system block — some local chat templates
        // (Qwen3.5, GLM via llama.cpp) only accept a single system
        // message at the start. Concatenating avoids breaking them.
        output.system[output.system.length - 1] += "\n\n" + ROUTING_HINT
      } else {
        output.system.push(ROUTING_HINT)
      }
    },
  }
}

export default LocalGlmFallback