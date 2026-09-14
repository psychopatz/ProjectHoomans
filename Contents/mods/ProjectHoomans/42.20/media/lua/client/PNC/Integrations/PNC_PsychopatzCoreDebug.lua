-- PsychopatzCore is an external dependency and therefore the only failure
-- boundary here; Project Hoomans debug registration remains direct afterward.
local ok = pcall(require, "PsychopatzCore/UI/PsychopatzDebugHubWindow")
if not ok or not (PsychopatzCore and PsychopatzCore.DebugHub) then
    return
end

if PNC and PNC.ConversationDebugUI and PNC.ConversationDebugUI.Text then
    PsychopatzCore.DebugHub.RegisterTool({
        id = "pnc.conversations",
        source = "Project Hoomans",
        order = 205,
        title = PNC.ConversationDebugUI.Text("hub.title"),
        description = PNC.ConversationDebugUI.Text("hub.description"),
        available = function()
            return PNC.ConversationDebugUI.Toggle
                and PNC.Client and PNC.Client.CanUseDebug
                and PNC.Client.CanUseDebug()
        end,
        action = function() PNC.ConversationDebugUI.Toggle() end,
    })
end

local function resolveText(value, key, fallback)
    if value and value ~= "" and value ~= key then
        return value
    end
    return fallback
end

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.audio",
    source = "Project Hoomans",
    order = 206,
    title = resolveText(getText and getText("UI_PNC_AudioDebug_Title"),
        "UI_PNC_AudioDebug_Title", "AUDIO DEBUG"),
    description = resolveText(getText and getText("UI_PNC_AudioDebug_Description"),
        "UI_PNC_AudioDebug_Description",
        "Preview player voice aliases and registered game sound effects."),
    available = function()
        return PNC
            and PNC.AudioDebugUI
            and PNC.AudioDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.AudioDebugUI.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.npcMonitor",
    source = "Project Hoomans",
    order = 200,
    title = "PNC NPC Monitor",
    description = "Inspect NPC lifecycle, authority, presence, combat, and runtime bodies.",
    available = function()
        return PNC
            and PNC.NPCMonitor
            and PNC.NPCMonitor.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.NPCMonitor.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.uniqueNPCs",
    source = "Project Hoomans",
    order = 201,
    title = resolveText(
        getText and getText("UI_PNC_UniqueNPCDebug_Title"),
        "UI_PNC_UniqueNPCDebug_Title", "UNIQUE NPC REGISTRY"),
    description = resolveText(
        getText and getText("UI_PNC_UniqueNPCDebug_Description"),
        "UI_PNC_UniqueNPCDebug_Description",
        "Inspect one-time unique NPC definitions, lifecycle state, and location."),
    available = function()
        return PNC
            and PNC.UniqueNPCDebugUI
            and PNC.UniqueNPCDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.UniqueNPCDebugUI.Toggle() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.uniqueNPCEditor",
    source = "Project Hoomans",
    order = 202,
    title = resolveText(
        getText and getText("UI_PNC_UniqueNPCEditor_Title"),
        "UI_PNC_UniqueNPCEditor_Title", "UNIQUE NPC CREATOR"),
    description = "Create, preview, equip, and produce client-local unique NPC definitions.",
    available = function()
        return PNC
            and PNC.UniqueNPCEditorUI
            and PNC.UniqueNPCEditorUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.UniqueNPCEditorUI.Toggle() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.communities",
    source = "Project Hoomans",
    order = 230,
    title = resolveText(getText and getText("UI_PNC_CommunityInspectorTitle"),
        "UI_PNC_CommunityInspectorTitle", "COMMUNITY INSPECTOR"),
    description =
        "Inspect persistent communities, membership, anchors, capacity, and supplies.",
    available = function()
        return PNC
            and PNC.CommunityDebugUI
            and PNC.CommunityDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.CommunityDebugUI.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.needs",
    source = "Project Hoomans",
    order = 225,
    title = "COLONIST DEBUG",
    description = "Inspect provision storage and run targeted colonist debug actions.",
    available = function()
        return PNC and PNC.ColonistUI and PNC.ColonistUI.OpenDebug
            and PNC.Client and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.ColonistUI.OpenDebug() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.abstractDirector",
    source = "Project Hoomans",
    order = 226,
    title = "Abstract World Director",
    description = "Inspect strategic groups, locations, traversal, occupancy, combat-profile caches, encounters, and scheduled jobs.",
    available = function()
        return PNC and PNC.DirectorDebugUI and PNC.DirectorDebugUI.Toggle
            and PNC.Client and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.DirectorDebugUI.Toggle() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.worldEffects",
    source = "Project Hoomans",
    order = 227,
    title = "World Effects",
    description = "Inspect durable world mutations waiting for loaded squares.",
    available = function()
        return PNC and PNC.WorldEffectDebugUI
            and PNC.WorldEffectDebugUI.Toggle
            and PNC.Client and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.WorldEffectDebugUI.Toggle() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.communityOverlay",
    source = "Project Hoomans",
    order = 231,
    title = resolveText(getText
        and getText("UI_PNC_CommunityWorldOverlayTitle"),
        "UI_PNC_CommunityWorldOverlayTitle", "COMMUNITY WORLD OVERLAY"),
    description =
        "Toggle server-resolved community diagnostics above visible NPCs.",
    available = function()
        return PNC
            and PNC.CommunityDebugOverlay
            and PNC.CommunityDebugOverlay.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.CommunityDebugOverlay.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.relationships",
    source = "Project Hoomans",
    order = 210,
    title = "PNC Relationship Inspector",
    description = "Inspect directed social data and trigger guarded test events.",
    available = function()
        return PNC
            and PNC.RelationshipDebugUI
            and PNC.RelationshipDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.RelationshipDebugUI.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.knowledge",
    source = "Project Hoomans",
    order = 211,
    title = "NPC Knowledge Lab",
    description = "Compare NPC truth with one character's discovered notes and evidence.",
    available = function()
        return PNC and PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.Open
            and PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug()
    end,
    action = function()
        local roster = PNC.Network and PNC.Network.ClientState and PNC.Network.ClientState.debugRoster or {}
        local npcID = roster[1] and roster[1].id or nil
        if not npcID then
            for id in pairs(PNC.Network and PNC.Network.ClientState
                and PNC.Network.ClientState.snapshots or {}) do
                npcID = id
                break
            end
        end
        if npcID then PNC.KnowledgeDebugUI.Open(npcID) end
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.npcTraits",
    source = "Project Hoomans",
    order = 212,
    title = resolveText(getText and getText("UI_PNC_NPCTraitDebug_Title"),
        "UI_PNC_NPCTraitDebug_Title", "NPC TRAIT REGISTRY"),
    description = resolveText(
        getText and getText("UI_PNC_NPCTraitDebug_Description"),
        "UI_PNC_NPCTraitDebug_Description",
        "Inspect every registered NPC trait and its composed effects."),
    available = function()
        return PNC and PNC.NPCTraitDebugUI
            and PNC.NPCTraitDebugUI.Toggle
            and PNC.Client and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.NPCTraitDebugUI.Toggle() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.factions",
    source = "Project Hoomans",
    order = 220,
    title = resolveText(getText and getText("UI_PNC_FactionInspectorTitle"),
        "UI_PNC_FactionInspectorTitle", "FACTION INSPECTOR"),
    description = "Inspect persistent organizations, affiliations, roles, ranks, and leadership.",
    available = function()
        return PNC
            and PNC.FactionDebugUI
            and PNC.FactionDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.FactionDebugUI.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.factionOverlay",
    source = "Project Hoomans",
    order = 221,
    title = resolveText(getText
        and getText("UI_PNC_FactionWorldOverlayTitle"),
        "UI_PNC_FactionWorldOverlayTitle", "FACTION WORLD OVERLAY"),
    description =
        "Toggle server-resolved faction diagnostics above visible NPCs.",
    available = function()
        return PNC
            and PNC.FactionDebugOverlay
            and PNC.FactionDebugOverlay.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.FactionDebugOverlay.Toggle()
    end,
})

-- Project Hoomans settings belong to the standard in-game settings registry.
-- Remove the old debug-hub launcher as well when this file is hot-reloaded.
PsychopatzCore.DebugHub.UnregisterTool("pnc.settings")
