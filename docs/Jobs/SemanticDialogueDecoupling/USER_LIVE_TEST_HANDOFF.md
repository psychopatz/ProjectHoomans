# READY FOR USER LIVE TEST

This is a user-owned Project Zomboid validation checklist. It is not a request
for Codex to launch the game, poll the native UI, or publish a Workshop item.

## What the development checks established

- Hoomans D4 implementation: `ea414a04`; D4 evidence: `2fff9683`.
- Hoomans D5 translation/domain fix: `1d573706`.
- The real Semantic Lab worker uses the production Lua entrypoint and passes
  the full suite (**104/104**), the D5 integration set (**29/29**), and the
  focused Lua translation/domain smokes.
- EN/TL public Core translation lookup is verified for identity, generated
  wellbeing, the two-turn greeting flow, the `ask_name` tool reply, and the
  observed Trading UI catalog. The worker reports selected keys, rendered
  text, flow nodes/transitions, fallback provenance, transport, and actions.
- GUI click-through was not run because desktop automation exposed `apps=[]`.
  The GUI is source-verified; the real Lua worker is the development evidence
  fallback. Do not treat this as a GUI interaction pass.

## Singleplayer checklist

1. Start a save with the matching local Hoomans/Core pair and fully restart
   Project Zomboid after changing mods or language.
2. Open one NPC conversation and run this short sequence:
   `hello` → `who are you` → `are you okay` → `im fine thanks` →
   `My name is <your actual character name>`.
3. Confirm the visible NPC replies match the selected conversation and that
   the flow facts, if debug output is enabled, show identity `start`,
   wellbeing `interrupt_start`, wellbeing `match`, then identity `match` and
   retirement. A valid name should produce the authoritative identity result;
   the preceding safe questions should not send commands or mutate inventory.
4. Test the modular greeting flow with `hello` followed by `thanks`. Confirm
   its opening and follow-up are the greeting flow’s replies and the flow
   retires after the follow-up.
5. Switch to TL, restart, and repeat at least the greeting, identity, and
   wellbeing turns. Confirm rendered Tagalog text, expected translation keys,
   and no English-fallback marker for those catalog-backed replies. Repeat in
   EN and confirm the English values and placeholders remain intact.
6. Spot-check one Trading UI window, one gossip/news question, one inventory or
   gift interaction, and one task/action request. Trading labels should come
   from the registered catalog; gossip must not become an inventory query;
   action requests must show their normal authority/result boundary.

## Multiplayer checklist

With the same source pair on the server and client, repeat one safe identity /
wellbeing conversation and one explicit action request.

- Safe dialogue must not create duplicate transport or action events.
- Identity changes and action admission must be server-authoritative.
- Two nearby NPCs must keep speaker and flow state isolated.
- After reconnect/rejoin, the conversation context must not duplicate queued
  replies or resurrect a retired flow.
- If PBrainZ is enabled, compare its authored/provider path with the
  deterministic fallback. If it is disabled, deterministic semantic replies
  and the safety boundary must remain available.

## Performance and evidence

Observe the console and debug facts during a normal few-minute NPC session:
there should be no semantic work registered as a per-tick full-NPC scan and no
new repeated translation/action spam while idle. If a result differs, record
the language, exact input, NPC/player pair, selected candidate, flow
transition/node, rendered text, fallback flag/key, transport, actions, and
whether the issue is SP or MP. Attach the relevant console line or screenshot.

This handoff does not authorize Workshop publication. The user owns the final
live-test decision and any later publication decision.
