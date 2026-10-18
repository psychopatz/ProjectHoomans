# Acceptance — automatic semantic flow generation and real production behavior

**Primary contract:** one registered capability descriptor can generate a complete first-class production dialogue/action flow with typed parameter/permission/result lifecycle; then the SAME generator handles other registered capabilities of that template class WITHOUT manual per-action flow source or duplicated domain dispatch. Tests must exercise real Hoomans + PsychopatzCore Lua, not a stand-alone Python replica or JSON parser.

## Required coverage and evidence

Record repository HEAD, Core checkout, catalog identity/revision, `totalCapabilities`, generated counts per workflow template, legacy/manual and unsupported counts + exact reasons, flow ID, load status, source file paths/translation/manifest, template fingerprint, actual selected parser IR/pattern, flow node+gate sequence, capability binding, transport/authority request/response, NPC text, language, preview side effects, and any action completion/rejection. Always distinguish mock server boundary from actual PZ.

## G0A mandatory acceptance matrix

| Case | Expected proof |
| --- | --- |
| Metadata inventory | Source-registered simple command capabilities enumerated, including FOLLOW and STAY; statuses, missing descriptors, unsupported GIFT/WAIT_AT template families explicit; denominator matches live catalog |
| Generic generation | FOLLOW+STAY production flow modules from **one reusable simple_command template**, with permission+request+queued/rejected/failure outcome nodes; same generator discovers all other compatible simple commands without per-name `if` logic |
| Fresh worker load | Restart actual production Lua worker, registry lists generated stable flow IDs and transitions; current legacy flows still load, no duplicate IDs or flow-limit boot break |
| Authorized FOLLOW/STAY | Real Core IR and selected **generated flow**; exactly one corresponding command via existing dispatcher and mocked authority; actual node/result and truthful queued reply |
| Permission rejection | Generated flow takes real denied result branch; no affirmative "I will follow" reply; no authorization bypass |
| Negated/question/ambiguous | "Don't follow me", "Are you following me?", unresolved target and low-confidence variants must NOT run unintended FOLLOW/STAY; prove transport/side-effect facts |
| Preview vs committed | Two previews effect-free; one committed request triggers at most one dispatch; replay/late result respects request correlation and idempotency |
| Compiler quality | Kahlua-safe deterministic modular Lua/EN+TL, stable manifest, no conflict with manual identity/wellbeing/weather, repeated generate byte-identical, source diff correct |
| Inspector/coverage | Existing Semantic Lab shows newly registered action flows (not just Add action trigger), source/owner/template/binding, outcome trace and unsupported capability list |

## Later acceptance

G0B WAIT_AT plus another eligible parameterized task, G0C full OFFER/GIFT multi-stage, G1 all-compatible-catalog generation and graph/code regen, G2 contextual/weather/personality/memory responses and precision report, G3 quest state/locks/events, G4 representative SP/MP authority contracts, performance and persistence. No generated feature is accepted solely from a static catalog count or synthetic screenshot.

Run focused production Lua worker tests, existing command/gift/task/identity/weather/wellbeing regressions, harness doctor, compiler deterministic checks, `git diff --check`, Kahlua/luac, EN/TL resolution; test actual Tk clicks via available X11 if a UI gate is in scope. The earlier ledger recorded **123 Python tests with four social reaction failures**; new acceptance must explicitly account for and investigate current failing tests instead of copying older pass counts or claiming full-suite green.

Do NOT turn Codex CLI CUA `apps=[]` into a blocker; X11/xdotool/worker fallback is allowed. Native Project Zomboid SP/MP remains user-owned; never publish Steam Workshop or use absent native PZ runtime to block source development.
