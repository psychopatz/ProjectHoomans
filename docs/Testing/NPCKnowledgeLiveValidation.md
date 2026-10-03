# NPC Knowledge Live Validation

1. Enable debug mode and right-click an NPC.
2. Open **NPC Dossier**. It should show only facts already learned; it must not show orientation or raw personality numbers by default.
3. As an admin, open **Debug: Knowledge Laboratory**. Confirm that every registered descriptor is listed and that toggling truth hides/shows the authoritative column only in this admin window.
4. Use **Reveal** or **Force Disclosure** on a descriptor. Refresh the normal dossier and confirm the result appears there without raw provider truth.
5. Trigger a social event where an NPC treats, saves, or protects the player. Refresh the dossier; the observable personality descriptors should gain evidence over repeated observations.
6. Create a new survivor on the same account. Their dossier must start empty while the former character's notes remain intact.
7. Register a temporary test descriptor/provider during bootstrap. It should appear automatically in the laboratory and, once revealed, in the dossier.
8. Test multiplayer with a non-admin client. Requests must only receive the normal dossier snapshot; debug requests must be rejected and contain no truth.

Automated coverage: `lua tests/pnc_knowledge_smoke.lua` validates dynamic registration, duplicate rejection, generic provider/resolver flow, sparse notes, private disclosure, normal snapshot privacy, orphan preservation, and character isolation.
