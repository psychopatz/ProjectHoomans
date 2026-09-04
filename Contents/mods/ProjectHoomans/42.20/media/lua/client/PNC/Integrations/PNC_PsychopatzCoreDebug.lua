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
    id = "pnc.communities",
    source = "Project Hoomans",
    order = 230,
    title = getText
        and getText("UI_PNC_CommunityInspectorTitle")
        or "UI_PNC_CommunityInspectorTitle",
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
    title = "NPC Needs Debug",
    description = "Inspect and test server-authoritative individual and mobile-group Need reserves.",
    available = function() return PNC and PNC.NeedsDebugUI and PNC.NeedsDebugUI.Toggle and PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() end,
    action = function() PNC.NeedsDebugUI.Toggle() end,
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
    title = getText
        and getText("UI_PNC_CommunityWorldOverlayTitle")
        or "UI_PNC_CommunityWorldOverlayTitle",
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
    id = "pnc.factions",
    source = "Project Hoomans",
    order = 220,
    title = getText and getText("UI_PNC_FactionInspectorTitle")
        or "UI_PNC_FactionInspectorTitle",
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
    title = getText
        and getText("UI_PNC_FactionWorldOverlayTitle")
        or "UI_PNC_FactionWorldOverlayTitle",
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
