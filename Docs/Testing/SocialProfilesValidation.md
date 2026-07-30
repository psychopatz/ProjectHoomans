# Social Profiles Live Validation

Automated Lua tests validate deterministic logic and persistence shape. They
cannot prove Build 42.20 trait-screen presentation or callback behavior.

**Status:** these scenarios have not been run in live Project Zomboid during
Phase 3B implementation. Phase 3A single-player, hosted, and dedicated-server
UUID persistence/reconnect/death/new-survivor validation also remains unrun
and is a release blocker.

Optional diagnostics:

```lua
PNC.Config.Relationships.DebugSocialProfiles = true
PNC.Config.Relationships.DebugSocialEvents = true
PNC.Config.Relationships.DebugPlayerIdentity = true
```

## Relationship Inspector

This is the quickest in-game validation path for the persistent relationship
foundation.

1. Start single-player with Project Zomboid debug mode enabled, or join a
   multiplayer server as an admin.
2. Spawn or load at least two Project Hoomans NPCs.
3. Open the PsychopatzCore Debug Hub and choose **PNC Relationship
   Inspector**. Alternatively, open **PNC NPC Monitor**, select an NPC, and
   click **Relationships**.
4. Select an observer NPC in the first column.
5. Select **Current player character** or another NPC in the second column.
6. Confirm the initial row says `no (preview defaults)` when that directed
   relationship has never been stored.
7. Click **Treat Wound**, **Save**, **Protect**, **Survive Together**, or
   **Abandon**. The panel should refresh with the real event result, memory,
   personality-adjusted effects, scores, state, cooldown/saturation values,
   conduct evidence, and revisions.
8. Switch observer and target for an NPC pair. Confirm the reverse direction
   is independent. **Survive Together** intentionally creates both directions;
   the other buttons create only the selected observer's direction.
9. Click **Treat Wound** twice without advancing 12 world-age hours. Confirm
   the second result is `cooldown_active` and no relationship, social, or
   record revision advances.
10. Confirm every accepted mutation advances relationship, social, and record
    revisions while the displayed presence revision stays unchanged.
11. Close/reload the save and confirm memories and values remain visible.

Conduct-specific checks:

1. With an NPC observer and current-player target, trigger **Treat Wound**.
   Confirm the relationship memory and player conduct evidence appear;
   compassion rises by 2 and generosity by 1 before decay.
2. Trigger it again during cooldown. Confirm neither a memory nor evidence is
   added and no revisions advance.
3. Trigger **Save** and confirm player compassion +8, courage +5, group
   loyalty +4, and reliability +3 evidence.
4. Select two NPCs and trigger **Survive Together** once. Confirm reciprocal
   relationship memories and exactly one participant evidence entry on each
   NPC. If two memories appear, record whether the button was deliberately
   pressed twice; one trigger must not finalize twice.
5. Trigger **Abandon** and confirm the selected target/actor receives the
   documented negative actor evidence.
6. Save/reload, then verify evidence persists and `presenceRevision` remains
   unchanged.
7. Kill the player and create a new survivor. Confirm the new UUID starts
   neutral while the dead UUID's conduct remains intact.

Selection and **Refresh** are read-only. The window never sends scores or
memory payloads; the server derives the stable player-character key and routes
the selected named event through the production social-event service. A
missing inspector entry normally means debug/admin authorization failed or
the PsychopatzCore Debug Hub dependency did not load.

## Trait Screen

Build 42.20's vanilla trait lists normally filter out cost-zero definitions.
Phase 3B includes a narrow standard-screen adapter for PNC's zero-point
traits, but its actual load timing and presentation still require this live
test.

1. Open standard Build 42 character creation.
2. Verify all ten PNC traits appear.
3. Verify Gay, Bisexual, Bland Palate, Spice Lover, Flirty, Reserved, Jealous,
   and Unpossessive show zero cost.
4. Verify Friendly costs 2 points.
5. Verify Withdrawn grants 2 points.
6. Verify each documented pair is mutually exclusive.
7. Verify traits from unrelated groups can coexist.
8. Create a survivor with Gay, Spice Lover, Reserved, Jealous, and Friendly.
9. Inspect the UUID through `PNC.SocialProfileDebug.FormatPlayer(uuid)` and
   verify the five exact resolved values and canonical source traits.
10. Save/reload and verify UUID, profile values, profile revision, and source
    traits are unchanged.

The generic trait icon is intentional for this phase. Confirm that zero-cost
entries remain visible and selectable in the active Build 42 UI.

## Default Resolution

Create a survivor with none of the PNC social traits and verify straight,
neutral food, neutral romance, normal jealousy, and neutral social style.

## Death and New Survivor

1. Create survivor A with Gay and Friendly; record UUID and profile.
2. Die and verify A becomes dead exactly once.
3. Create survivor B on the same account with Bisexual and Withdrawn.
4. Verify B has a different UUID and its own exact profile.
5. Verify A's record/profile is unchanged and NPC relationships to A were not
   moved to B.

Run this in single player, hosted multiplayer, and dedicated server alongside
`PlayerCharacterIdentityValidation.md`.

## NPC Determinism

1. Inspect an NPC formatter output, identity seed, archetype, social revision,
   record revision, and presence revision.
2. Save/reload; verify the personality is byte-for-byte equivalent and does
   not advance revisions.
3. Dematerialize/rematerialize; verify the profile is unchanged.
4. Inspect two NPCs with the same archetype and different seeds; confirm their
   numeric profiles can differ.
5. Inspect an authored override NPC; verify valid overrides win without
   invalid values entering persistence.

## Event Interpretation

1. Choose two NPCs with meaningfully different compassion.
2. Perform equivalent successful treatment after cooldown on each.
3. Verify both get valid new memories and the higher-compassion NPC has the
   documented stronger interpretation.
4. Verify the actor player's own social profile does not change either
   observer's modifier.
5. For two NPCs surviving the same encounter, verify each reciprocal memory
   uses its own observer profile.
6. Verify dedupe, cooldown, saturation, memory limits, and revision behavior.
7. Change/inspect a profile after a memory exists and verify the old memory is
   not rewritten.
8. Verify no profile action changes `presenceRevision`.

## Recording Results

For each mode record game build, server type, trait costs/visibility,
exclusion behavior, UUIDs, formatter output, revision values, reconnect/death
callbacks, event multiplier output, and failures. Do not mark a scenario
passed from static inspection or Lua smoke tests alone.
