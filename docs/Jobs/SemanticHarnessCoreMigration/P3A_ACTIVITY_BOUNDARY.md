# P3-A — Activity stream ownership

Status: complete.

`PsychopatzCore.tools.semantic_harness.core.activity` owns the bounded
activity stream used by the Core GUI, CLI, and worker lifecycle, including
in-memory history, JSONL persistence, truncation handling, formatting, and
state-root path derivation.

All Python callers now import the Core module directly. Project Hoomans and
Dynamic Trading contain no activity implementation or compatibility façade.
Gameplay and provider policy remain outside this Core utility.
