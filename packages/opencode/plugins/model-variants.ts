/**
 * model-variants
 * Exports per-model variant (effort level) data for gentle-ai.
 *
 * On OpenCode startup, lists models via the 2.x `ctx.model.list()`, extracts
 * variant ids per model, and writes a minimal JSON cache to
 * ~/.gentle-ai/cache/model-variants.json. gentle-ai reads this file to populate
 * the effort level picker without needing a live API connection.
 *
 * Output shape is unchanged from 1.x — { providerID: { modelID: [variantID] } } —
 * because gentle-ai consumes it directly, independent of the opencode version.
 *
 * 2.x port notes:
 *  - Default export is now `Plugin.define({ id, setup })` via @opencode/plugin.
 *    opencode validates plugin modules against the *promise* contract, which
 *    wants `setup: (ctx) => Promise<Cleanup | void>`; the Effect-flavoured
 *    `@opencode/plugin/effect` variant (which wants `effect`) is rejected with
 *    "Plugin must export a default definition with an id and an effect or
 *    setup function".
 *  - `input.client.provider.list()` became `ctx.model.list()`, which returns a
 *    flat array of models. Each entry carries `providerID`, `id` and `variants`
 *    (an array of `{ id, ... }`), so the old nested `prov.models` walk collapses
 *    into a single pass.
 *  - setup() may return a Cleanup, but the refresh is one-shot fire-and-forget:
 *    it must not block plugin load, and it has nothing to tear down.
 */

import { Plugin } from "@opencode/plugin"
import { writeFile, mkdir, rename, rm } from "fs/promises"
import { randomBytes } from "crypto"
import { homedir } from "os"
import path from "path"

const MODEL_VARIANTS_CACHE_FILE = "model-variants.json"

// The model catalogue is not populated the instant a plugin loads, so re-list
// a few times before giving up. ~4s of attempts in total.
const LIST_RETRY_INTERVAL_MS = 500
const LIST_RETRY_ATTEMPTS = 8

function sleep(ms: number) {
  const { promise, resolve } = Promise.withResolvers<void>()
  setTimeout(resolve, ms)
  return promise
}

async function removeOwnTempFile(tmpPath: string) {
  try {
    await rm(tmpPath, { force: true })
  } catch (err) {
    // Another concurrent load already removed it — nothing to report.
    const benign = typeof err === "object" && err !== null && "code" in err && (err as { code?: string }).code === "ENOENT"
    if (!benign) console.error("[model-variants] temp cleanup failed:", err)
  }
}

async function listModelsWithVariants(ctx: Plugin.Context) {
  for (let attempt = 0; attempt < LIST_RETRY_ATTEMPTS; attempt++) {
    const models = (await ctx.model.list()).data
    if (models.some((m) => (m.variants ?? []).length > 0)) return models
    await sleep(LIST_RETRY_INTERVAL_MS)
  }
  return (await ctx.model.list()).data
}

async function refreshVariantsCache(ctx: Plugin.Context) {
  let tmpPath: string | undefined
  try {
    const models = await listModelsWithVariants(ctx)

    const variants: Record<string, Record<string, string[]>> = {}
    for (const model of models) {
      const variantIds = (model.variants ?? []).map((v) => v.id).sort()
      if (variantIds.length === 0) continue
      variants[model.providerID] = variants[model.providerID] || {}
      variants[model.providerID][model.id] = variantIds
    }

    const cacheDir = path.join(homedir(), ".gentle-ai", "cache")
    await mkdir(cacheDir, { recursive: true })

    // Always write through a per-invocation tmp file before renaming, so
    // readers never see partial JSON and concurrent plugin loads do not
    // race over the same tmp path. See issues #766 and #786.
    const finalPath = path.join(cacheDir, MODEL_VARIANTS_CACHE_FILE)
    const stagingPath = path.join(cacheDir, `${MODEL_VARIANTS_CACHE_FILE}.${randomBytes(3).toString("hex")}.tmp`)
    await writeFile(stagingPath, JSON.stringify(variants, null, 2))
    tmpPath = stagingPath
    await rename(stagingPath, finalPath)
    tmpPath = undefined
  } catch (err) {
    console.error("[model-variants] cache refresh failed:", err)
  } finally {
    const orphan = tmpPath
    if (orphan) await removeOwnTempFile(orphan)
  }
}

export default Plugin.define({
  id: "model-variants",
  // Fire and forget: do not await the refresh, so plugin load stays fast.
  setup: (ctx) => {
    void refreshVariantsCache(ctx)
  },
})
