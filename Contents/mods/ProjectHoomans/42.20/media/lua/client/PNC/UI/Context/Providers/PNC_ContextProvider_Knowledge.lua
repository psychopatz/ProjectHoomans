-- Normal dossier access is deliberately separate from the admin laboratory.

PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local Provider = { id = "npc_knowledge" }

local function text(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        return PNC.Translation.GetKey(key, fallback)
    end
    return fallback
end

local function canUseDebug()
    return PNC.Client
        and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

function Provider.addOptions(menu, entry)
    menu:addOption(text("UI_PNC_Context_NPCDossier", "NPC Dossier"), nil, function()
        if PNC.CharacterWindow and PNC.CharacterWindow.OpenDossier then
            PNC.CharacterWindow.OpenDossier(entry.id)
        end
    end)
    if canUseDebug() then
        menu:addOption(text(
            "UI_PNC_Context_KnowledgeLaboratory",
            "Debug: Knowledge Laboratory"
        ), nil, function()
            if canUseDebug()
                and PNC.KnowledgeDebugUI
                and PNC.KnowledgeDebugUI.Open
            then
                PNC.KnowledgeDebugUI.Open(entry.id)
            end
        end)
    end
end

PNC.ContextHub.RegisterProvider(Provider)
return Provider
