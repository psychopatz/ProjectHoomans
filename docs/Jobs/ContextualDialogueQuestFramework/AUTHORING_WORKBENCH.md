# Semantic Lab — all-supported automatic flow generation UX

Existing Flow Editor (Tk) has registered flows, node editing, Add action trigger, Compile source…, Generate source…, Simulation, and earlier recorded X11 click-through. It still lists only four legacy conversation flows + one generated FOLLOW terminal flow at audited branch. Its Add action triggers recognition, **not** generation of an executable production flow; source compiler requires selecting an authored JSON file. Keep and improve this SAME application rather than invent another UI.

## Primary actions that must exist

- **Discover Capabilities / Show Coverage:** automatic inventory of registered parser frames, command/task/gift workflows and legacy conversational flows. Show total, template-eligible, generated, unsupported/manual, and detailed missing contract reasons. Do not hide recognition-only actions.
- **Generate Missing Flows:** map supported capabilities to generic workflow templates; show proposed flow graphs, source module/translation/manifest diffs, collision diagnostics. Explicit approve before any write; regenerate only changed fingerprints.
- **Regenerate Selected:** edit template parameters, trigger frames, condition gates, result-to-response mapping, EN/TL and layout from typed canonical spec. Custom edits/overlays survive deterministic regeneration. Never overwrite handwritten legacy modules.
- **Validate All / Test All:** run exact production Lua worker traces for every generated *template class* and focused all-compatible-catalog integrity checks; distinguish real engine mocks from native PZ. Show loaded flow ID, selected node and outcome, binding, outgoing request, denial/timeout and rendered response.
- **Graph/Code/Language/Actions/Simulator/Compiler views:** group functions by meaningful labels; render actual action-capability nodes and outcome edges, clickable handler detail, raw IR/JSON in advanced inspector. Context/quest/personality gates are reusable registered condition descriptors, not free-form scripts.

## Three essential UI invariants

1. Node drag/link/delete/rename and code editing modify **one canonical versioned source definition**, not only a worker-memory copy. Save draft, preview compilation, approved generate/write, fresh worker restart have separately labeled controls and state.
2. A flow's action graph must reflect the **real production route**. Generated FLOW with response-only terminal does not qualify as "Follow command flow" unless authorization/request/result stages are present and executed. Display actual selected branch and reason for noFlow/legacy fallback.
3. All lists and generation are **registry-driven**. The author should not have to remember manually each `PNC_*.lua` source file or edit JSON frames just to add a known game primitive; incomplete metadata is surfaced explicitly.

## Phased UI delivery and acceptance

First G0A exposes coverage and displays the two generated simple-command flows, can inspect exact binding/result traces. Advanced graph/code editing and bulk buttons may follow in G1 only after worker and compiler correctness; a temporary CLI/worker discovery query plus minimal existing UI coverage is acceptable *for the first chunk*, but eventual product requires complete UI generation. Do not declare final acceptance with only a headless generator or a copied source file.

Native PZ/Steam/Workshop are not part of automated developer acceptance. For Codex CLI, use X11/Xvfb/xdotool or other actually available desktop tools; don't spin forever polling `apps=[]`. Actual mouse click evidence stays separate from direct Tk callback tests.
