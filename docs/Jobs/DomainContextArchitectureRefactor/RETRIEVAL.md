# Fixed retrieval probes

Baseline: `15cadee70be11b790ce4c48bfb7bd51badd8233b`.
Definitions: `RETRIEVAL_PROBES.json`; measured source: `P0_RETRIEVAL.json`;
both-direction, depth-one MCP traces with tests and confidence:
`P0_MCP_TRACES.json`. All seven traces fit one page; none were truncated.
The exact 37 runtime files and 16 distinct test paths were coverage checked;
metadata matches, with no recorded gaps (best-effort signal).

| Behavior | Source files | Lines | Bytes | Reviewed hops |
|---|---:|---:|---:|---:|
| Transfer authority / revision validation | 5 | 966 | 38,241 | 3 |
| Single active task lease eligibility | 5 | 367 | 15,364 | 3 |
| Conversation close outcome / cleanup | 7 | 1,311 | 46,385 | 3 |
| Persisted inventory revision | 7 | 1,121 | 44,618 | 3 |
| NPC inventory result rows | 4 | 659 | 24,086 | 2 |
| Materialization eligibility | 5 | 925 | 34,190 | 2 |
| Inventory command / payload route | 5 | 204 | 7,668 | 2 |

**Aggregate unique:** 37 files / 5,530 lines / 209,522 bytes. Overlapping files
are counted once. Tests are listed separately, not added to source bytes.

## Interpretation

These are bounded, source-reviewed working sets for the precise changes in the
definitions. They are not full import closures or claims of mathematically
minimal context. Full files are counted even when MCP can retrieve a narrower
symbol. Engine and PsychopatzCore public contracts are stopping boundaries;
their implementations need inspection only when that boundary changes.

Hops count source-reviewed provider/call handoffs from the public entry to the
behavior, not every heuristic edge returned by MCP. Foreign lists include lazy
namespace interactions, so literal imports alone cannot reduce them. Known MCP
resolution errors are documented in `P0_BASELINE.md`; raw traces preserve them
for reproducibility rather than silently treating them as authoritative edges.

The seven entry paths and explicit test lists are in the definitions. Entry
does not imply `require` returns a table: several existing hubs populate `PNC`
and return Lua's default `true`. Follow the actual namespace contract.

## Cycle participation

- Inventory transfer and lease creation: no literal cross-domain SCC for their
  owners. Transfer reaches conversation leases, networking, medical assistance
  and task notifications through lazy namespace calls; these remain in review.
- Conversation close: belongs to the large dialogue/persistence/UI folder SCC.
  The selected close slice itself does not need a UI window or Persistence
  implementation. P5 must retain this locality while clarifying the domain seam.
- Inventory field persistence: crosses Persistence -> Inventory; the coordinator
  additionally imports Conversation memory even when changing an inventory field.
  P4 must disentangle that ownership without duplicating record state.
- UI rows: UI belongs to the large folder SCC, while this query projection is
  already local. Retain its fine-grained grouping/native metadata seam.
- Presence eligibility: no literal SCC for Presence. BodyLifecycle startup and
  Travel handoff contracts are necessary safety boundaries, not fragmentation.
- Network route: Networking's folder SCC with PresenceSync is in the adjacent
  body-binding lane, not in the inventory command route. Do not merge their
  policy because both live under transport folders.

## Rerun after every affected migration

Refresh MCP and architecture-audit first. Keep probe behavior and IDs fixed.
If ownership moves, update the reviewed file list and explain why each removed
file is no longer needed; do not simply delete entries to improve the metric.

```sh
python3 tools/domain_context_audit.py \
  --probes docs/Jobs/DomainContextArchitectureRefactor/RETRIEVAL_PROBES.json \
  --compare docs/Jobs/DomainContextArchitectureRefactor/P0_RETRIEVAL.json \
  --output /tmp/hoomans-domain-current-probes.json
```

Repeat the saved symbol queries (search first if a symbol moves), both trace
directions, relevant pages and exact-path coverage. Recheck owned tests using
the listed focused filters plus fresh MCP callers; the lists are relevant
regressions, not exhaustive affected-test claims.
