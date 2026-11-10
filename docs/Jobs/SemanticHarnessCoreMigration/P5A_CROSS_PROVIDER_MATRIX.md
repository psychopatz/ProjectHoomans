# P5-A — cross-provider developer matrix

## Result

The provider-agnostic Core boundary loads and composes independently for the
four intended modes:

- Core-only: `PsychopatzCore`, materialization `none`;
- Project Hoomans with optional Dynamic Trading disabled;
- Project Hoomans with optional `DTCommon`/`DTHoomans`, materialization
  `physical`; and
- Dynamic Trading `DTAbstract`, materialization `abstract`.

DynamicTrading's declarative adapters resolve both abstract and physical
profile metadata through Core without starting a second worker engine. The
Hoomans real-Lua worker path continues to use the Core transport/session/state
contracts and discovers Dynamic Trading only when its modules are available.

## Developer-side evidence

- Core profile/worker/process/registry/layout checks: 15 passed.
- Hoomans Core/profile/optional-provider/semantic parity checks: 8 passed.
- DynamicTrading provider-adapter checks: 4 passed.
- DynamicTrading Lua semantic-execution adapter smoke: passed.
- No native Project Zomboid process was launched.

## User-owned acceptance handoff

The remaining acceptance must be performed in native SP and MP saves:

1. restart persistence for player-owned companions and Core actor/faction
   adoption;
2. enable/disable Project Hoomans and Dynamic Trading independently;
3. nearby DTHoomans trader materialization and traversal;
4. DTAbstract abstract traversal without physical NPC creation; and
5. shared conversation/trade interaction across guards, traders, colonists,
   companions, and hostile NPCs.

The goal remains open until that matrix is observed in the running game or the
user explicitly accepts the remaining native gate.
