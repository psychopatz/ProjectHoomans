# Acceptance — Domain & Context Architecture Refactor

## Purpose

This document defines what counts as successful developer-side completion.

The objective is not cosmetic organization. Acceptance requires preserved behavior plus measurably clearer ownership and smaller change-local reasoning graphs.

## 1. Behavioral parity

For every migrated slice:

- existing public runtime behavior remains unchanged unless an explicit bug fix is separately evidenced;
- server/client/shared authority remains correct;
- persistence/save compatibility remains intact;
- network payload/command contracts remain intact or have an explicit compatible migration;
- no gameplay feature is removed merely to simplify architecture.

Focused tests must pass after each coherent migration.

The current full-suite baseline must be freshly established in P0. Historical test counts are evidence only, not the new baseline.

## 2. Public domain contracts

For every mandatory migrated domain:

- one obvious public entry/facade or documented public subdomain surface exists;
- mutable state has one authoritative owner;
- public commands/queries/events are distinguishable where applicable;
- foreign consumers do not import private `Internal` implementation paths;
- runtime layer (`client/server/shared`) does not become a duplicate domain owner.

## 3. Decomposition quality

A successful split must demonstrate at least one of:

- clearer responsibility;
- independent caller/test/reuse boundary;
- authority/runtime/persistence/engine boundary;
- materially better MCP retrieval precision.

A successful merge must demonstrate that the merged files were artificial fragments with one owner/change reason and no useful independent retrieval seam.

Neither “file became smaller” nor “file count decreased” is sufficient evidence.

## 4. MCP context-locality

P0 establishes representative retrieval probes.

For each final probe record:

- minimal maintained-source file set;
- approximate lines/bytes;
- foreign domain dependencies;
- dependency hops/cycles;
- affected tests.

Final acceptance requires:

- the aggregate fixed-probe evidence set is smaller/more local than the P0 baseline;
- no individual probe has a material unexplained regression in files/bytes/dependency depth;
- the Inventory pilot demonstrably improves or preserves its retrieval set while removing foreign implementation coupling;
- Conversation/Semantics probes no longer require broad unrelated UI/Persistence traversal;
- agents can discover the public domain entry before reading implementation.

Exact token counts are optional because MCP clients may chunk differently; source bytes/lines and graph hops are the durable proxy.

## 5. Dependency direction

Required:

- no foreign import into another migrated domain's private `Internal` tree;
- UI does not own persistence or authoritative domain mutation;
- persistence does not depend on UI behavior;
- transport/network handlers hand off to owning domains;
- composition roots do not become gameplay owners;
- PsychopatzCore does not absorb Project Hoomans policy to make dependency graphs look cleaner.

No unresolved high-confidence cross-domain dependency cycle may remain in mandatory migrated production code without explicit documented justification.

A retained cycle must be proven to be either:

- an analyzer classification artifact;
- intra-domain implementation detail;
- or a required runtime composition relation with no safer inversion.

## 6. Composition

Final composition acceptance requires:

- stable bootstrap paths remain;
- proven PZ load order is preserved;
- migrated domains expose bounded composition/registration seams where useful;
- composition roots depend primarily on domain entries rather than leaf providers;
- no reflection/service-locator magic replaces readable load order solely to reduce require counts.

Raw require count is evidence, not the goal.

## 7. Persistence

Required:

- domain repositories/adapters own schema meaning;
- persistence lifecycle coordinates when to save/load;
- no UI/presentation dependency is needed to deserialize authoritative state;
- no duplicate shadow state is introduced merely to break a cycle;
- legacy migrations are bounded and classified.

## 8. UI

Required:

- windows/panels own presentation, local interaction state and formatting;
- domain rules exist outside UI;
- UI requests mutations through command/application seams;
- UI obtains state through queries/view models/snapshots;
- the existing UI/persistence mix finding is resolved or proved false-positive.

## 9. Performance

The refactor must not introduce:

- per-frame repository/global scans;
- unbounded queues/tables;
- broad event fanout in hot paths where direct intra-domain calls were cheaper;
- repeated reconstruction of static contracts;
- persistence duplication;
- excessive dynamic lookup/service-locator overhead.

Existing bounded scheduler, interest-routing and cache/revision strategies must be preserved unless independently improved with evidence.

## 10. Documentation/token hygiene

Required:

- root `AGENTS.md` remains durable repository-wide policy only;
- active phase/progress lives only in this job's `PROGRESS.md`;
- the two giant historical refactor logs are not in the required read order;
- new phase history is not appended to them;
- domain contracts are concise orientation aids rather than essays;
- checked-in `GOAL_PROMPT.md` is not created unless repository policy changes;
- current architecture can be understood without reading historical migration archaeology.

## 11. Validation

After each coherent slice:

- Codebase MCP/graph caller and dependency review;
- affected/focused tests;
- architecture/dependency checks;
- changed-file syntax/Kahlua checks as appropriate;
- `git diff --check`.

Before parent completion:

- current full isolated Lua suite;
- mandatory focused domain suites;
- refreshed architecture/dependency report;
- final retrieval-probe comparison;
- changed runtime Lua installed-PZ/Kahlua validation according to repository practice;
- static performance/persistence review;
- final Git status/diff review.

Do not launch native Project Zomboid or publish Workshop content unless explicitly assigned.

## 12. Completion statement

The goal is developer-complete only when:

> A coding agent can start from a domain's public contract, use Codebase MCP to retrieve a bounded coherent implementation/test slice, make a normal change without traversing unrelated domains, and the resulting architecture preserves Project Hoomans behavior and authority.

If mandatory architecture work remains, the job remains in progress regardless of file size, analyzer health score or individual phase success.
