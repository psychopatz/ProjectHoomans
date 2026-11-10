# P4-C — native Project Zomboid acceptance matrix

This is the user-owned final gate. Run each applicable row with a fresh test save, or a copy of an existing save. Record `console.txt`, the active mod list, and the observed map/debug state.

| Case | Mods | Required evidence |
| --- | --- | --- |
| Core-only bootstrap | PsychopatzCore | The game loads without adopter imports or missing-module errors; Core diagnostics remain available. |
| Hoomans physical | PsychopatzCore + ProjectHoomans | A nearby Hoomans NPC materializes, can be selected and talked to, and survives restart with owner, faction, and identity intact. |
| Hoomans + DTHoomans | Core + Hoomans + DTCommon + DTHoomans | A nearby trader materializes physically, uses the same conversation landing page, trades through DTCommon authority, and traverses between map points. |
| DTAbstract | Core + DTCommon + DTAbstract, without Hoomans/DTHoomans | Abstract trader/group signals and traversal continue without a physical NPC; abstract conversation and trade remain usable. |
| Optional toggle | Repeat Hoomans and DTAbstract saves with the other adopter disabled | No stale import, nil callback, or profile mismatch; the enabled profile remains loadable. |
| Restart/persistence | Repeat each applicable case after save, quit, and reload | Provider identity, ownership/faction, route/group state, trade state, and discovery state are restored rather than becoming `Unknown`. |

For each case, capture:

- `console.txt` errors and warnings around profile loading, semantic execution, conversation, traversal, and persistence;
- map-marker/debug state before and after moving near a signal;
- whether a physical NPC exists for Hoomans/DTHoomans and does not exist for DTAbstract;
- whether conversation opens and returns a structured response;
- whether the same actor identity, ownership, faction, and trade state remain stable after reload.

Passing this matrix confirms the intended distinction: Hoomans/DTHoomans materialize nearby actors, while DTAbstract operates the same Core/DTCommon actor and conversation contracts abstractly.
