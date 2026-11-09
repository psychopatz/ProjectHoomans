# P2-C — Dynamic Trading adapter boundary

## Contract

PsychopatzCore owns the execution descriptor schema:

- schema: `semantic.harness_execution.v1`;
- callbacks: `buildContext`, `submitText`, `previewText`, `submitFrame`, and
  `snapshot`, with `interaction` remaining an optional Core callback;
- materialization mode is selected by the profile, not by a second worker.

Dynamic Trading contributes only the optional adapter manifest:

- `DTCommon` owns merchant/trader conversation, identity, interaction, and
  trade policy and supports both abstract and physical composition;
- `DTAbstract` depends on `DTCommon` and resolves the abstract profile;
- `DTHoomans` depends on `DTCommon` and resolves the physical profile;
- merchant stock, budgets, quotes, and trade authority remain in DTCommon;
- physical NPC materialization remains DTHoomans-only;
- DTAbstract never acquires an in-provider physical body.

The manifest is declarative and does not start a worker or import Project
Hoomans. Core repository layout discovery remains the authority for whether an
optional adopter is available.

## Gates

- Core provider-registry suite passes with execution callback validation.
- Dynamic Trading adapter tests resolve `dtabstract` without DTHoomans and
  `dthoomans` with the physical mode.
- Both profiles expose the same callback declaration and schema.
- No legacy worker files are deleted in P2-C; deletion waits for the P3
  adapter bootstrap and P4 import/behavior gates.
