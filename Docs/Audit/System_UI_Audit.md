# UI System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P1`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 53.2 |
| Architecture pressure | 100 |
| Graph coverage score | 72.2 |
| Evidence confidence | 59.3 |
| Production files | 120 |
| Production LOC | 29727 |
| Rule findings | 30 (3 high, 27 medium, 0 low) |
| Fan-in / fan-out | 4 / 7 |

## Next-phase disposition

Highest-priority hotspot: 30 findings, zero module-boundary score, and cycles with Conversation, Scavenge, and Composition. Separate view construction, debug models, and event wiring from domain mutation; point UI dependencies toward read models and command interfaces.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-060441219D` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: Scavenge -> UI -> Scavenge |
| `ARC-5B5A1F6495` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: Conversation -> UI -> Conversation |
| `ARC-9E545CAFA6` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Conversation -> UI -> (composition) |
| `ARC-242C416095` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugModel.lua has 964 code lines; review responsibility density. |
| `ARC-4B10856D07` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugWindow.lua has 834 code lines; review responsibility density. |
| `ARC-72BF9C9C45` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Inventory/PNC_InventoryWindow.lua has 949 code lines; review responsibility density. |
| `ARC-B00B5BB860` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Nameplates/PNC_NameplateRenderer.lua has 1586 code lines; review responsibility density. |
| `ARC-DEB8064271` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugWindow.lua has 842 code lines; review responsibility density. |
| `ARC-215F3CD02D` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCRelationshipGraphPanel:render spans 184 lines. |
| `ARC-2F02D3836D` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Provider.addOptions spans 215 lines. |
| `ARC-40E3EECFBA` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | TravelLayer.Render spans 139 lines. |
| `ARC-430E0A83A6` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | drawDebugText spans 155 lines. |
| `ARC-6AEE5B1B3B` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | cacheMetrics spans 123 lines. |
| `ARC-6DE577C1B5` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCFactionDebugWindow:onAction spans 220 lines. |
| `ARC-726DD3084A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCScavengeWindow:rebuildStatus spans 131 lines. |
| `ARC-7B8F8AF746` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCAnimationSceneDebugWindow:refreshDetails spans 200 lines. |
| `ARC-7D08E940C3` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Tabs.RenderHealth spans 142 lines. |
| `ARC-7DB70EA83F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | DebugTab.BuildRows spans 124 lines. |
| `ARC-8C2546CD65` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Model.BuildRows spans 411 lines. |
| `ARC-9C860B2BD2` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Model.BuildGUIRows spans 302 lines. |
| `ARC-A597FE6AF6` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCFactionDebugOverlay:render spans 293 lines. |
| `ARC-A87CE0D401` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Model.BuildRows spans 161 lines. |
| `ARC-B0B9DAE587` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCInventoryWindow:refreshInventory spans 145 lines. |
| `ARC-B47DF86C18` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Renderer.BuildCombatDebugLines spans 299 lines. |
| `ARC-D1E4BBE234` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCFactionDebugWindow:prerender spans 138 lines. |
| `ARC-D61AACE3A9` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | ISPNCRelationshipDebugWindow:createChildren spans 177 lines. |
| `ARC-DF28BC4007` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Model.DetailRows spans 297 lines. |
| `ARC-E091F04D73` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Model.BuildRows spans 380 lines. |
| `ARC-EC6D44D204` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | drawCombatDebug spans 243 lines. |
| `ARC-F97CE753E4` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | drawPathGoal spans 143 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-B00B5BB860` | 1586 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Nameplates/PNC_NameplateRenderer.lua | — |
| Large module | `ARC-242C416095` | 964 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugModel.lua | — |
| Large module | `ARC-72BF9C9C45` | 949 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Inventory/PNC_InventoryWindow.lua | — |
| Large module | `ARC-DEB8064271` | 842 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugWindow.lua | — |
| Large module | `ARC-4B10856D07` | 834 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugWindow.lua | — |
| Large function | `ARC-8C2546CD65` | 411 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugModel.lua:103 | Model.BuildRows |
| Large function | `ARC-E091F04D73` | 380 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugModel.lua:320 | Model.BuildRows |
| Large function | `ARC-9C860B2BD2` | 302 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugModel.lua:690 | Model.BuildGUIRows |
| Large function | `ARC-B47DF86C18` | 299 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Nameplates/PNC_NameplateRenderer.lua:444 | Renderer.BuildCombatDebugLines |
| Large function | `ARC-DF28BC4007` | 297 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Director/PNC_DirectorDebugModel.lua:48 | Model.DetailRows |
| Large function | `ARC-A597FE6AF6` | 293 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugOverlay.lua:206 | ISPNCFactionDebugOverlay:render |
| Large function | `ARC-EC6D44D204` | 243 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Nameplates/PNC_NameplateRenderer.lua:1213 | drawCombatDebug |
| Large function | `ARC-6DE577C1B5` | 220 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugWindow.lua:400 | ISPNCFactionDebugWindow:onAction |
| Large function | `ARC-2F02D3836D` | 215 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Context/Providers/PNC_ContextProvider_Debug.lua:39 | Provider.addOptions |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 11689 | 1642 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Nameplates/PNC_NameplateRenderer.lua |
| 9041 | 1003 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Inventory/PNC_InventoryWindow.lua |
| 8188 | 803 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Scavenge/PNC_ScavengeWindow.lua |
| 7706 | 872 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugWindow.lua |
| 7321 | 994 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugModel.lua |
| 6171 | 875 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugWindow.lua |
| 6074 | 776 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugModel.lua |
| 6042 | 548 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/CharacterWindow/PNC_CharacterWindow_Health.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


