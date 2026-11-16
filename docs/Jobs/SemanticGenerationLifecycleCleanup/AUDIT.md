# Final Audit — Semantic Generation Lifecycle / G9R

**Evidence:** CODE_VERIFIED, TEST_VERIFIED, GENERATED_OUTPUT_VERIFIED.

## Final implementation findings

- 577 compact production PSDL families compile through the Portable Dialogue Plan production seam.
- Backend selection is descriptor-driven.
- Reference VM ↔ Lua ConvoProbe semantic conformance is tested.
- Core behavior source is decomposed into `social/{acknowledgement,conflict,context,repair,world_events}`.
- Core beats are decomposed into `social/{conflict,first_contact,repair}`.
- ProjectHoomans scene behavior is decomposed into `scene/{excursion,horde,news,post_combat,task_work}`.
- Runtime-plan and director surfaces mirror the same semantic decomposition.
- Core generated behavior payloads contain no Hoomans scene behaviors.
- Avoidable hash-named generated Lua files are zero across PsychopatzCore, ProjectHoomans and DTCommon.
- Retired `Social__d6475647` and `CoreKnowledgeFacts__d73c98cf` artifacts/references are absent.
- `domainPath` is derived generically from source hierarchy rather than a hard-coded per-family partition list.

## Source-level growth regression

A permanent regression now adds temporary real compact PSDL source files through the normal loader and proves:

```text
new social/conflict variant
→ Behavior/Social/Conflict changes
→ Behaviors/Director/Social/Conflict changes
→ Repair/Acknowledgement/Context remain unchanged

new social subdomain
→ new local Behavior module
→ new local Behaviors/Director module
→ existing Conflict/Repair modules remain unchanged
→ no hash fallback
```

This closes the earlier model-only test weakness.

## Final closure criteria

The final committed-vector acceptance must keep:
- canonical reconcile clean before apply;
- G9R/G9/G8R7/G8/G7 regression suites green;
- naming/sharding determinism clean;
- isolated generated-output deletion/rebuild successful;
- second pass a no-op;
- final active docs consistent with COMPLETE.

No additional developer-side semantic-generation phase remains.
