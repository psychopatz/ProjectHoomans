# Semantic Observatory — harness and safety acceptance gates

**No phase is accepted on static schema or JSON-only checks.** This checklist uses the existing production Core+Hoomans Lua worker; Project Zomboid native SP/MP is a separate user-only final acceptance gate.

## Required evidence per relevant phase

| Gate | Real assertion |
| --- | --- |
| A. Registry correctness | New bounded pool detail equals registered Lua Catalog.POOLS entries (IDs/variants/conditions/priority/plan/template), handles unknown pool and cap, no source loading or gameplay mutation from query. |
| B. Source mapping | Authored Lua pool points to verified file or UNKNOWN; generated pool points to real reviewed CodeBuilder source and actual translation manifest or UNKNOWN. Source path cannot be invented by grep. |
| C. Selector parity | Same context, salt, history and registry selects same variant with/without diagnostics; explain lists rule-by-rule ineligibility, score, tie/hash, repeat-avoidance and final selection. Explain cannot consume the next variant. |
| D. Grounded behavior | Real Lua worker scenario includes greeting (rain/friendly/default), wellbeing/health known vs unknown, farewell with close, companion Follow/Wait and refusal, unknown-name privacy, action/no-action cases, and Leave Group for both unowned rejection **and a production-rehydrated player-owned faction warning→confirm→departure path**. Verify chosen variant/visible text plus actual authority outcome, not just plan ID. |
| E. Effects and persistence | Preview and read-only inspection create zero durable facts/commands/saves. Legitimate actions retain single authoritative execution, no extra relationship/Knowledge/ModData delta and no double transport; sourceKind SAVE remains read-only. |
| F. Languages and variants | EN/TL both resolve actual catalogs. Placeholders and formatting preserved; no fallback leak, fabricated job/identity/world facts, duplicated equivalent text or mixed-language bleed. Verify negative and ambiguous cases. |
| G. Studio/CLI parity | UI and CLI retrieve identical catalog revisions/variant IDs, actual response and outcome; GUI tests exercise real widgets/worker, headless is enough for agent mode but GUI is not considered accepted by synthetic-only tests. |
| H. Safe proposal | Before/after candidate in isolated worker differs in expected rendered response (both EN/TL), uses proper source owner, has reviewable diff and cannot alter response plan/authority accidentally; rejected proposal leaves working source unchanged. |
| I. Scale | Compare measured worker startup, catalog payload/query latency, bounded JSON output, matrix throughput/memory vs P0 baseline; paging/truncation flagged, no per-NPC tick scans or persistent debug history. |
| J. End-to-end | Focused and relevant broad Python tests, production Lua smoke, Kahlua syntax, CodeBuilder deterministic artifacts, Git cleanliness of unrelated paths, log of actual PASS/FAIL/SKIP and clear user-owned live gate. |

## Minimum reusable scenario matrix

- Conversation: greeting opening + two turns; rainy vs clear, friendly vs guarded, resumed flow, goodbye/farewell close.
- NPC truth: healthy/unknown/injured, needs urgency, different social style and relationship attitude, identity-known vs hidden, unfamiliar stranger; no fabricated state.
- Semantics/actions: typed player request, NPC reply/suggestion, valid companion follow, mutually exclusive wait, invalid/stale/unauthorized action; verified authority and effect delta.
- Leave Group: unowned/other-owner rejection plus a disposable save-backed player-owned faction that reaches the real production warning, confirmation and ColonistDeparture transition; source save bytes remain unchanged.
- Language: EN and TL for each proposed variant family; placeholder/value and translation fallback reason.
- Selection: empty/missing pool, 1-variant, equal-score multiple variants, higher-priority overshadowing, repeat consecutive turns, bounded history pressure, load/restart state isolation.
- Performance: large registry within current caps and paginated queries; huge/untrusted requested detail rejected or truncated explicitly.

Test fixtures must use existing scenario conventions and source-backed PZ engine facts (through production fixture adapters) where the real engine is unavailable; mark those assertions ENGINE-FIXTURE, not native.

## Evidence categories

- **CODE:** verified source ownership/contract.
- **WORKER:** observed production Lua and active Core code, isolated runtime.
- **GUI:** observed actual Tk widget/surface against worker.
- **NATIVE:** user-run PZ SP/MP only.
- **SKIP/BLOCKED:** dependency or capability unavailable, with reason.

Historical passing tests are a starting baseline, not a pass for newly implemented gates. Explicitly report failed assertions and missing cells; a truncation marker or no produced trace cannot count as zero errors.

## User-owned final live checklist

After developer-side acceptance: user verifies in native PZ SP (and MP as applicable) opening/greeting, EN/TL, real selected phrases, farewell/closing, contextual suggestions and Follow/Wait/camp, gameplay effects, hidden names, and no GUI/persistence/performance regression. Do not require Steam Workshop republishing to make the developer-side goal complete.
