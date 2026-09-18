/**
 * fff-preferred.ts
 *
 * Auto-prepends an instruction block to every subagent prompt that
 * tells the subagent to use mcp__fff_* tools for file-content and
 * filename searches. Hooks the `before_agent_start` event so this
 * happens transparently without changing caller prompts.
 *
 * Discovery: ~/.omp/agent/extensions/ (auto, per omp://extension-loading.md).
 *
 * Idempotency: re-prepending is skipped if the marker is already present,
 * so calling extensions that also touch before_agent_start do not stack
 * copies of the instruction on every spawn.
 */

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const FFF_INSTRUCTION = [
	"Tool preference: for all file-content and filename searches, use the fff MCP",
	"server tools \u2014 `mcp__fff_grep`, `mcp__fff_find_files`, `mcp__fff_multi_grep`.",
	"They are frecency-ranked and faster than the built-in `grep`/`glob`.",
	"Only fall back to built-in grep/glob if fff returns no results or the",
	"specific capability you need is not exposed by fff.",
].join(" ");

const MARKER = "Tool preference: for all file-content";

type PromptContainer = Record<string, unknown>;

function collectPromptSlots(e: PromptContainer): Array<PromptContainer> {
	const slots: Array<PromptContainer> = [];
	const direct = e.prompt;
	if (typeof direct === "string") slots.push({ owner: e, key: "prompt", value: direct });

	const taskObj = e.task as PromptContainer | undefined;
	if (taskObj && typeof taskObj.prompt === "string") {
		slots.push({ owner: taskObj, key: "prompt", value: taskObj.prompt });
	}

	const agentObj = e.agent as PromptContainer | undefined;
	if (agentObj && typeof agentObj.prompt === "string") {
		slots.push({ owner: agentObj, key: "prompt", value: agentObj.prompt });
	}

	return slots;
}

function alreadyPrepended(value: string): boolean {
	return value.startsWith(FFF_INSTRUCTION) || value.includes(MARKER);
}

export default function fffPreferred(pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event: unknown) => {
		const e = event as PromptContainer | undefined;
		if (!e) return;

		const slots = collectPromptSlots(e);
		if (slots.length === 0) return;

		// Idempotency: bail if any slot already has the marker.
		for (const slot of slots) {
			if (alreadyPrepended(slot.value as string)) return;
		}

		// Pick the first non-empty prompt to use as the base.
		const baseSlot = slots.find((s) => (s.value as string).trim().length > 0);
		if (!baseSlot) return;

		const baseValue = baseSlot.value as string;
		const newPrompt = `${FFF_INSTRUCTION}\n\n${baseValue}`;

		// Write the new prompt back into every string slot we found, so the
		// subagent receives the prepended text regardless of which field
		// its consumer reads.
		for (const slot of slots) {
			if (typeof slot.value === "string" && slot.value === baseValue) {
				(slot.owner as Record<string, unknown>)[slot.key as string] = newPrompt;
			}
		}
	});
}