---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "H10R planning checkpoint"
phase_commit_message: "docs: reopen organic injury acceptance repairs"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "H10R1"
chunk: "Selected-wound truth projection and debug/production wound-event parity"
retrieval_tier: "auditor"
---

# Session Handoff

## What became true

- H0–H10 remain a useful accepted foundation, but H11 live runtime evidence reopened developer work.
- Debug `Random Body Part` wounds currently bypass `NotifyWoundCallout`; this is the concrete reason live debug injuries can silently bandage without immediate semantic reaction.
- Fighting-injured wording can overclaim selected-wound treatment (`splint`) and function (`can't run`) because realization uses coarse `patched_up + bodyRegion + severity` buckets rather than exact selected-wound treatment/function facts.
- Current witness policy is ally/squad-focused and cooldown-based, not first-of-day/new-injury observation with non-colonist coverage.
- Existing ConvoEngine responsePlan/branch/Scene and authoritative inventory/treatment systems should be extended rather than replaced.
- Robustness/performance are primary acceptance gates: no new per-NPC tick/poller, no full scans, bounded caches/queries/participants, O(1) clean projection reads.

## Remaining

Execute H10R1 through H10R8, then return the baton to H11 user live acceptance.

## Resume

Start H10R1 from exact current source. Separate selected-wound truth from whole-body summaries, make debug wound injection emit the same normalized production semantic wound event, add negative truth assertions for treatment/function/infection claims, and commit the accepted phase before continuing automatically.

## Blockers / concurrent work

- DynamicTrading currently has unrelated dirty generated ConvoEngine files. Do not touch, stage, reset or incorporate them into this goal.
- psychopatzCore changes are allowed only for genuinely reusable H10R4/H10R7 semantic-composition or Quality Sweep mechanisms; preserve its existing world-event work.

## Acceptance

Parent completion requires H10R1–H10R8 developer gates. H11 remains user-owned and cannot resume until the live false-positive/no-reaction defects are covered by deterministic tests and robustness/performance regression.
