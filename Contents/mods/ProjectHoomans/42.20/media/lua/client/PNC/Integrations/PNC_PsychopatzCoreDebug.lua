-- PsychopatzCore is a required mod dependency. Let load failures surface
-- directly so an animation API or UI regression is diagnosable.
require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
if not (PsychopatzCore and PsychopatzCore.DebugHub) then
    return
end

local function resolveText(value, key, fallback)
    if value and value ~= "" and value ~= key then
        return value
    end
    return fallback
end

local function translateHubText(key, fallback)
    local translation = PNC and PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    return resolveText(value, key, fallback)
end

if PNC and PNC.ConversationDebugUI and PNC.ConversationDebugUI.Toggle then
    PsychopatzCore.DebugHub.RegisterTool({
        id = "pnc.conversations",
        source = "Project Hoomans",
        order = 205,
        title = translateHubText("UI_PNC_DebugHub_ConversationBlocks_Title",
            "Conversation Blocks"),
        description = translateHubText(
            "UI_PNC_DebugHub_ConversationBlocks_Description",
            "Browse registered conversation graphs, gates, translations, deterministic rolls, and sandbox effects."),
        available = function()
            return PNC.ConversationDebugUI.Toggle
                and PNC.Client and PNC.Client.CanUseDebug
                and PNC.Client.CanUseDebug()
        end,
        action = function() PNC.ConversationDebugUI.Toggle() end,
    })
end

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.audio",
    source = "Project Hoomans",
    order = 206,
    title = translateHubText("UI_PNC_DebugHub_Audio_Title", "Audio Debug"),
    description = translateHubText("UI_PNC_DebugHub_Audio_Description",
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
    id = "pnc.playerAnimation",
    source = "Project Hoomans",
    order = 207,
    title = translateHubText("UI_PNC_DebugHub_PlayerAnimation_Title",
        "Player Animation Lab"),
    description = translateHubText(
        "UI_PNC_DebugHub_PlayerAnimation_Description",
        "Preview zombie animation clips on the local ISOPlayer without changing NPC state."),
    available = function()
        return PNC
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        require "PNC/UI/PNC_PlayerAnimationDebugWindow"
        if PNC.PlayerAnimationDebugUI
            and PNC.PlayerAnimationDebugUI.Open
        then
            PNC.PlayerAnimationDebugUI.Open()
        end
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.perception",
    source = "Project Hoomans",
    order = 208,
    title = translateHubText("UI_PNC_DebugHub_Perception_Title",
        "Hoomans Perception Debug"),
    description = translateHubText(
        "UI_PNC_DebugHub_Perception_Description",
        "Inspect client-visible objects, semantic names, usable surfaces, rooms, campfire zones, and camp-site resolution without sending search requests."),
    available = function()
        return PNC
            and PNC.PerceptionDebug
            and PNC.PerceptionDebug.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.PerceptionDebug.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.npcMonitor",
    source = "Project Hoomans",
    order = 200,
    title = translateHubText("UI_PNC_DebugHub_NPCMonitor_Title", "NPC Monitor"),
    description = translateHubText("UI_PNC_DebugHub_NPCMonitor_Description",
        "Inspect NPC lifecycle, authority, presence, combat, and runtime bodies."),
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
    title = translateHubText("UI_PNC_DebugHub_UniqueNPCRegistry_Title",
        "Unique NPC Registry"),
    description = translateHubText(
        "UI_PNC_DebugHub_UniqueNPCRegistry_Description",
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
    title = translateHubText("UI_PNC_DebugHub_UniqueNPCCreator_Title",
        "Unique NPC Creator"),
    description = translateHubText(
        "UI_PNC_DebugHub_UniqueNPCCreator_Description",
        "Create, preview, equip, and produce client-local unique NPC definitions."),
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
    title = translateHubText("UI_PNC_DebugHub_CommunityInspector_Title",
        "Community Inspector"),
    description = translateHubText(
        "UI_PNC_DebugHub_CommunityInspector_Description",
        "Inspect persistent communities, membership, anchors, capacity, and supplies."),
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
    title = translateHubText("UI_PNC_DebugHub_ColonistDebug_Title", "Colonist Debug"),
    description = translateHubText("UI_PNC_DebugHub_ColonistDebug_Description",
        "Inspect provision storage and run targeted colonist debug actions."),
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
    title = translateHubText("UI_PNC_DebugHub_WorldDirector_Title",
        "World Director"),
    description = translateHubText("UI_PNC_DebugHub_WorldDirector_Description",
        "Inspect strategic groups, locations, traversal, occupancy, combat-profile caches, encounters, and scheduled jobs."),
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
    title = translateHubText("UI_PNC_DebugHub_WorldEffects_Title", "World Effects"),
    description = translateHubText("UI_PNC_DebugHub_WorldEffects_Description",
        "Inspect durable world mutations waiting for loaded squares."),
    available = function()
        return PNC and PNC.WorldEffectDebugUI
            and PNC.WorldEffectDebugUI.Toggle
            and PNC.Client and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function() PNC.WorldEffectDebugUI.Toggle() end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.relationships",
    source = "Project Hoomans",
    order = 210,
    title = translateHubText("UI_PNC_DebugHub_RelationshipInspector_Title",
        "Relationship Inspector"),
    description = translateHubText(
        "UI_PNC_DebugHub_RelationshipInspector_Description",
        "Inspect directed social data and trigger guarded test events."),
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
    title = translateHubText("UI_PNC_DebugHub_KnowledgeLab_Title",
        "NPC Knowledge Lab"),
    description = translateHubText("UI_PNC_DebugHub_KnowledgeLab_Description",
        "Compare NPC truth with one character's discovered notes and evidence."),
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
    title = translateHubText("UI_PNC_DebugHub_NPCTraitRegistry_Title",
        "NPC Trait Registry"),
    description = translateHubText(
        "UI_PNC_DebugHub_NPCTraitRegistry_Description",
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
    title = translateHubText("UI_PNC_DebugHub_FactionInspector_Title",
        "Faction Inspector"),
    description = translateHubText(
        "UI_PNC_DebugHub_FactionInspector_Description",
        "Inspect persistent organizations, affiliations, roles, ranks, and leadership."),
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

-- Project Hoomans settings belong to the standard in-game settings registry.
-- Remove old debug-hub launchers as well when this file is hot-reloaded.
PsychopatzCore.DebugHub.UnregisterTool("pnc.settings")
PsychopatzCore.DebugHub.UnregisterTool("pnc.communityOverlay")
PsychopatzCore.DebugHub.UnregisterTool("pnc.factionOverlay")
