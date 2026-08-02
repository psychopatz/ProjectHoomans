-- Normal dossier access is deliberately separate from the admin laboratory.

PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local Provider = { id = "npc_knowledge" }

function Provider.addOptions(menu, entry)
    menu:addOption("NPC Dossier", nil, function()
        if PNC.CharacterWindow and PNC.CharacterWindow.OpenDossier then
            PNC.CharacterWindow.OpenDossier(entry.id)
        end
    end)
    if PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() then
        menu:addOption("Debug: Knowledge Laboratory", nil, function()
            if PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.Open then
                PNC.KnowledgeDebugUI.Open(entry.id)
            end
        end)
    end
end

PNC.ContextHub.RegisterProvider(Provider)
return Provider
