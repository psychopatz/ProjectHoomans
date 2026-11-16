# Semantic Generation Lifecycle / Portable PSDL

**Status:** COMPLETE.

## Final result

The Semantic CodeBuilder/ConvoEngine pipeline is now a compact, portable, package-owned dialogue toolchain with deterministic generated ownership.

Production authority:

```text
compact PSDL package
→ canonical Semantic Dialogue IR
→ Portable Dialogue Plan
→ descriptor-selected backend
→ owner-isolated generated runtime
→ typed game capability adapter
```

Semantic source and generated output are organized by meaning before safety sharding:

```text
package
→ kind
→ broad runtime domain
→ semantic domainPath
→ variants
→ generated modules
→ byte/record safety split only if still required
```

Examples now include:

```text
behavior/social/conflict/
→ Behavior/Social/Conflict.lua
→ Behaviors/Director/Social/Conflict.lua

behavior/scene/horde/
→ PNC/ConvoEngine/Behavior/Scene/Horde.lua
→ PNC/ConvoEngine/Behaviors/Director/Scene/Horde.lua
```

## Accepted properties

- Core, ProjectHoomans and DTCommon own self-contained PSDL packages.
- Core contains reusable compiler/runtime/semantic stdlib; adopters own domain semantics.
- Compact source preserves explicit canonical IR and Portable Dialogue Plan semantics.
- Project Zomboid is selected through backend descriptors; a portable reference backend exists.
- Reference VM ↔ Lua ConvoProbe conformance is tested.
- Generated behavior/beat surfaces mirror package ownership and semantic domainPath.
- Adding a real source variant changes only its semantic group.
- Adding a new real semantic subdomain creates new local runtime/director modules without renaming unrelated groups.
- Avoidable `__<8hex>.lua` generated modules are zero across Core, ProjectHoomans and DTCommon.
- Generated reconciliation, clean rebuild, second-pass no-op and naming determinism are enforced.

Git history is the archive for G0–G9R implementation details.
