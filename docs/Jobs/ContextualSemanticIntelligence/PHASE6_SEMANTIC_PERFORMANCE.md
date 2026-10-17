# Phase 6 — Semantic Lab performance evidence

## Scope

This is a bounded **non-native** measurement of the real production Lua
semantic router through the existing Semantic Lab worker. It does not accept
Project Zomboid engine tick cost, native queue scheduling, SP, MP or server
authority.

Command:

```text
python3 -m tools.semantic_harness.phase6_performance \
  --samples 8 --warmup 2 --serial-turns 24 \
  --output /tmp/contextual-semantic-phase6-performance-final.json
```

The measurement used the reviewed `follow me` command, the reviewed `how are
you doing` wellbeing paraphrase and an unknown sentence, with provider disabled
and enabled. Each timed sample reset the worker outside the timed region and
measured one production turn over the Python/Lua worker protocol.

## Observed result

Median and p95 turn latency were:

| Case | Provider disabled | Provider enabled | Context-after size |
| --- | ---: | ---: | ---: |
| `follow me` | 12.53 / 14.60 ms | 12.21 / 12.74 ms | 1,807 bytes |
| `how are you doing` | 13.36 / 16.68 ms | 12.25 / 14.67 ms | 1,946 bytes |
| unknown fallback | 33.03 / 36.30 ms | 31.79 / 43.50 ms | 1,235 bytes |

The enabled provider mode made zero calls for the two authored deterministic
cases and one rejected-provider call for the unknown fallback. All three cases
retained their expected deterministic branches and no unauthorized action,
transport or tool effect was observed.

A serialized 24-turn worker sequence advanced strictly from semantic sequence
1 through 24. Recent dialogue history reached six turns, recent semantic
events reached the declared bound of 12, and the worker retained 24 queued NPC
messages plus 48 transcript messages. These are worker-level bounded-history
observations, not native game queue/tick measurements.

The focused static boundary guard passed **3/3**: every
`PNC_SemanticDialogueInput*.lua` module remains free of `Events.OnTick`
registration, and the server-side semantic social paths retain their
authority/lease and provider lease-ownership/replay gates. These checks guard
request-driven submission and server-boundary ownership; they do not claim
that surrounding gameplay, presentation or optional-provider systems have no
tick work, nor do they replace live MP evidence.

## Gate interpretation

This evidence advances only the Semantic Lab performance sub-slice. Native SP,
native MP, live provider success and Project Zomboid engine performance remain
open and are recorded in [`PHASE6_NATIVE_STATUS.md`](PHASE6_NATIVE_STATUS.md).
