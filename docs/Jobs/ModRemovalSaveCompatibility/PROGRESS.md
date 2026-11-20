# Progress — Mod Removal & Save Compatibility

**Status:** PLANNED / ROOT CAUSE UNVERIFIED.
**Current phase:** P0 — Save-safe reproduction and baseline.
**Reference repo checkpoint:** inspected source at 8575f20e24d716efc52142376c50a2bd22d706f0; main advanced to c156ed21e due to a concurrent firearm-effects commit during planning. Revalidate HEAD on startup.
**User-observed symptom:** carrying capacity shows a maximum of 8 after disabling Project Hoomans.
**Evidence:** reference save is configured with zero mods, retains PNC-related global data, and has two non-dead local-player records of the same displayed name.
**Completed this planning pass:** read-only save metadata inspection and scoped source searches; no fix, game execution, binary decode, save modification or gameplay regression run.
**Unknown:** whether 8 is mechanically enforced, which local-player record is loaded, which code/state caused it and whether any mod is responsible.
**Preserve:** unrelated firearm-effects work, now committed separately at c156ed21e, and any future concurrent changes.

## Next Chunk (exactly one)

P0: build a read-only, reproducible reference-save diagnostic and matched-control matrix. Determine the active player record and source of displayed vs effective carrying capacity. Capture evidence and label uncertainty. Do not attempt a repair until the offending field or runtime mechanism is identified.

## Execution policy

After each accepted phase, update PROGRESS/HANDOFF, commit only owned paths locally, then continue through mandatory phases automatically. Full parent objective is the completion boundary. No push or Workshop publication; no original-save mutation. Native gameplay is not authorized merely by this documentation task.
