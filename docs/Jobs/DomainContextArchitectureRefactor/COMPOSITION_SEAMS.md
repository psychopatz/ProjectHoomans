# Ordered domain registrations

P3 introduces 47 plain ordered-require entries around 265 existing provider
imports. Providers stay in place, retain independent callers and have unchanged
source hashes. A registration owns startup assembly only, never mutable state,
gameplay policy or an alternate runtime owner.

`REGISTRATIONS.json` is the machine-readable navigation/validation manifest.
`DOMAIN_CONTRACTS.json` references it instead of duplicating its provider lists.
Behavioral public APIs remain distinct from these initialization entries.

## Boundaries chosen

- Shared: compatibility adapters; semantic foundation; farming and production
  catalogs; needs schema/model; identity/traits; gift/social/conduct/relationship
  models; factions/communities; provision rules; perception/pathing; animation;
  equipment; map/companion commands; combat/attack; jobs; simulation; PuppetOpera.
- Server: individual/group needs; facility jobs; resources/camp; medical care;
  quests/task providers; semantic task/event/item adapters; scavenge/lumber;
  director visits; social events. Each uses the existing server-role early return.
- Client: map layers/tracking; context surfaces and early NPC providers;
  character-window assembly; voice presentation.

These are contiguous initialization boundaries with one logical owner. They
are not a prescription to split every domain into identical directories.
Independent services and management/debug windows retain explicit entries.
Interleaved domain assembly stays separated: combat and attack have a spatial
initialization barrier; semantic item tasks still load after server Inventory.

Presence/BodyLifecycle/binding/Networking entry order is unchanged. The event
marker assignment, profiler installation and conditional/lazy conversation
startup stay explicit. The inspected M12 identity/lease, loaded-envelope,
restart and visual-authority contracts remain intact.

## Evidence

| Root | Direct imports before → after | Source bytes before → after |
| --- | ---: | ---: |
| Client | 118 → 77 | 6,041 → 3,951 |
| Server | 125 → 82 | 6,550 → 4,275 |
| Shared Foundation | 76 → 28 | 4,055 → 1,448 |
| Shared Identity/Social | 67 → 23 | 3,499 → 1,187 |
| Shared Inventory/World | 44 → 27 | 2,117 → 1,296 |
| Shared Combat/Runtime | 42 → 23 | 2,123 → 1,190 |
| Shared Final | 16 → 10 | 1,005 → 664 |

Combined roots: 488 → 270 imports; 503 → 285 lines; 25,390 → 14,011 bytes.
`tools/domain_bootstrap.py` expands every new entry and compares the complete
ordered import/code-barrier trace with `P3_BOOTSTRAP_BASELINE.json`. Changed
order, registration policy, missing server guard or recursive assembly fails.
Lua bootstrap assertions still observe actual providers through a small test
helper; their behavioral/order expectations were not replaced with wrapper names.

For a character-window startup edit, the relevant assembly surface is now its
617-byte / 10-line registration rather than the 6,041-byte / 120-line client
root. Identity profile startup is 619 bytes / 12 lines versus 3,499 / 68;
semantic task assembly is 781 / 11 versus 6,550 / 131. Each selected registration
has one provider owner. Entry-to-provider traversal adds one explicit hop.
Complete expanded bootstrap source grows with registration headers and guards;
the improvement is bounded domain assembly retrieval and reduced root policy
knowledge, not a claim that all startup source or file count shrank.

The seven fixed gameplay probes remain at P2: 36 files / 5,269 lines / 198,850
bytes, 10,672 bytes below P0. Assembly probes supplement that fixed set.

## Validation and remaining work

- Full isolated Lua: **978/978**; diagnostic Python guards: **20/20**.
- Actual installed PZ Kahlua compilation: **54/54**; static Kahlua: zero errors.
- No provider body changed; no new boundary debt; four prior composition issues
  resolved, 189 existing issues remain. Debt was not rebaselined.
- No new file-import SCC. Existing three-file UI/debug SCC remains for P6.
- Exact pre-change import callers/dependencies: `P3_ARCHITECTURE_PRE.json`.
  Retained lazy conversation imports and the server's shared backstory source
  remain independently callable; registrations do not make all providers private.
- MCP Tier 2: 272 candidate paths checked (QuestDefinitions correctly resolves
  shared); 62 changed/test/tool paths checked after refresh. Exact source and
  fresh literal imports supplement missing statement-form IMPORTS and heuristic
  fixture resolution. Sample queries/snippets: `P3_MCP_TRACES.json`.
- `P3_VALIDATION.json`, `P3_RETRIEVAL.json` hold bounded machine evidence.
  No native PZ launched or Workshop content published.

P4 now owns persistence responsibility/schema classification and cycle inversion.
The pre-existing semantic-tooling baseline failures/timeouts remain final gates.
