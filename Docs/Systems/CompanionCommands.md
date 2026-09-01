# Companion Commands

## Command registry

- `PNC_CompanionCommandRegistry` owns validation and authority-side execution.
- `PNC_CompanionCommandDefinitions` is the only built-in command list. Add a
  future command with one `PNC.CompanionCommands.Register({ ... })` definition;
  both client menus enumerate it automatically.
- `PNC.CompanionCommands.RegisterGroup({ ... })` owns shared menu grouping.
  Setting `nested = true` creates the same second-level group in both the
  context menu and emote radial, without either adapter hardcoding command IDs.
- A definition supplies `id`, translation/fallback labels, a vanilla visual
  emote, icon, and a `group`. Movement commands provide
  `buildOrder(record, player)`; combat-response commands provide `attackType`.
  A future command may instead provide a custom authority-side `apply`
  callback.

Built-in commands are:

- Follow Me
- Wait Here
- Camp Here
- Attack Type: Auto
- Attack Type: Melee
- Attack Type: Ranged
- Attack Type: Don't Attack

Movement and attack type are deliberately independent. A companion can follow
or wait while retaining Auto, Melee, Ranged, or Don't Attack. Don't Attack
clears any committed attack, holsters the weapon, retreats from nearby threats,
and resumes the active movement order after reaching safe spacing.

`attackType` is persisted in schema version 7 and replicated in detailed,
roster, and presence snapshots. Records from older saves migrate to `auto`;
they do not require a new save.

## Flavor text

- `PNC_CompanionCommandFlavor` is the data registry and translation resolver.
- `PNC_CompanionCommandFlavorDefinitions` contains only built-in player lines
  and NPC acknowledgements.
- `PNC_CompanionCommandPresentation` owns client speech, emotes, and one-shot
  acknowledgement playback.
- Accepted commands replicate a transient command/revision token. Only the
  owning player's client presents the NPC acknowledgement, and each body
  consumes a revision once.

Mods can add or replace translated flavor without editing UI code:

```lua
PNC.CompanionCommandFlavor.Register("my_command", {
    player = {
        { key = "UI_MyMod_Command_Player", fallback = "Move out." },
    },
    npc = {
        { key = "UI_MyMod_Command_NPC", fallback = "On it." },
    },
})
```

Normal Project Zomboid translation files provide the referenced keys.
Fallbacks keep extension commands readable when a locale has not translated a
new line yet. Player lines may use `{name}`, `{names}`, `{count}`, and
`{player}` tokens. Project Hoomans resolves these after translation, allowing
natural single-NPC lines such as `"{name}, keep your distance."` and group
lines such as `"{names}, on me."`. Each built-in command has multiple
identity-safe variants selected from a changing local presentation revision,
so repeated orders do not always reuse the same sentence.

## Client adapters

- `PNC_CompanionCommandEmotes` adds two Project Hoomans roots to the vanilla
  emote radial, following the ZedColonies command-emote pattern:
  `Closest Companion: <name>` and `All Nearby Companions`.
- The closest-companion wheel contains Follow, Wait, and the second-level
  Attack Type submenu. The authority independently resolves the closest valid
  owned companion when executing the order.
- Compact roster snapshots replicate owner identity so the closest wheel can
  select and name the correct companion before a detailed presence snapshot
  arrives. During a brief sync gap the personalized wheel remains available;
  it sends no client-trusted target ID and lets the authority resolve the
  closest valid companion.
- Attack Type is personalized and never appears in the group wheel. Its
  submenu icon and the closest-companion root icon reflect the selected NPC's
  current Auto, Melee, Ranged, or Don't Attack setting.
- The group wheel contains only standard movement commands and broadcasts
  those commands to every nearby owned companion.
- Nested command definitions are stored privately by the Project Hoomans
  adapter. They are not registered as vanilla top-level radial menus, which
  prevents Attack Type from appearing twice.
- Choosing either radial command scope plays the command's vanilla signal
  emote and builds randomized player speech from the resolved companion names.
- `PNC_ContextProvider_Commands` exposes the same registry for one NPC under
  its world context menu. Attack types are nested for a compact layout.
- The selected attack type is rendered red and non-clickable through
  `PNC.ContextHub.ApplyOptionPresentation`. That helper also supports reusable
  disabled, unavailable, good, bad, and explicit icon-color variants for
  future providers.
- The adapters contain no command behavior or duplicated order definitions.
- The command-wheel, follow, wait, and protect PNGs were vendored from the
  ZedColonies/DynamicColonies command UI and renamed with `PNC_` identifiers.
  Project Hoomans therefore owns the runtime copies and does not require that
  source mod to be enabled.

## Authority and multiplayer

- `CompanionCommand` is a normal gameplay network command, not a debug command.
- The host/server resolves all targets and caps the radius at
  `COMPANION_COMMAND_RADIUS` (20 tiles).
- `closest` scope is resolved again on the authority and affects exactly one
  companion. `group` scope accepts standard commands only; group attack-type
  requests are rejected as personalized commands.
- Every target must be alive, live/materialized, on the player's floor,
  inside the radius, in the companion faction, recruited/owned, and owned by
  the issuing player's username or online ID.
- Neutral, hostile, abstract, distant, and another player's NPCs are rejected.
  Admin debug order controls remain separate and retain their existing scope.
- Movement commands use `PNC_OrderSystem`. Attack commands update only the
  response preference and equipment presentation. Both paths broadcast the
  updated record to interested clients.
