# Handoff

## State

The first authority-repair slice is implemented and locally verified. Core is
the canonical owner for new server bootstrap and generated community/group
records. Project Hoomans hydrates Core-affiliated actors into PNC before its
world view is consumed.

## Next chunk

Run the user-owned live validation on a fresh save and a restart:

1. verify Core bootstrap actors appear in the Hoomans NPC monitor;
2. verify map hover identity/knowledge resolves through the same actor ID;
3. verify a generated settlement/group commits once in Core;
4. verify `DTAbstract` to `DTHoomans` hotswap leases the existing actor and
   materializes it without a second PNC/Core record.

No native Project Zomboid session was launched by this developer-side phase.
