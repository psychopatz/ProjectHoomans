# P1-I worker lifecycle boundary

## Audit result

The Python process lifecycle was already Core-owned. Hoomans
`runtime/process.py` only builds a provider launch specification and delegates
`LuaProcess`, request correlation, bounded messages, shutdown, and diagnostics
to Core. The remaining duplicate was the Lua JSON-lines loop in both worker
entry points.

## Change

Core now owns `worker/WorkerLoop.lua`. It handles the handshake, request
reading, request-ID response correlation, protocol failures, and quit signal.
The Core and Hoomans Lua entry points supply only their bootstrapped hello and
dispatch callbacks.

This keeps the process/loop engine agnostic while preserving Hoomans' provider
bootstrap and the minimal Core profile. No Hoomans module path is imported by
Core.

## Deliberately retained in adopters

- worker bootstrap and package paths;
- provider context construction;
- handler registration and command policy;
- profile-specific hello data and optional-adopter loading.

## Verification note

The Core loop smoke, Core worker handshake, Core Python suite, and Hoomans
worker/dialogue smokes pass. The generic `pz-verify` Kahlua scan still reports
the existing developer-harness `os.*` and `package.*` usage in Hoomans' Lua
entry point; those APIs are used by the headless harness launcher and were not
introduced by this extraction.
