# SurvivorWorld Authority Migration

This job moves survivor-NPC generation to PsychopatzCore as the canonical
world authority while keeping Project Hoomans as the presentation, lifecycle,
and physical-materialization consumer.

Dynamic Trading remains a provider-specific consumer: `DTAbstract` keeps
traders abstract, while `DTHoomans` may lease the same Core actors into the
physical Hoomans runtime.

See `ROADMAP.md` for gates, `PROGRESS.md` for execution truth, and
`HANDOFF.md` for the next bounded chunk.

The forward expansion and unified source-registration plan now lives in
[`../UnifiedNPCPopulationExpansionArchitecture/`](../UnifiedNPCPopulationExpansionArchitecture/).
