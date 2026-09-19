-- Adapt conversation relationship presentation controls to the active panel.
local Relationship = PNC.Conversation.Relationship

function Relationship.SetPreviewRequirement(npcID, requirement, context)
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if not view or not view.spec
        or tostring(view.spec.npcID or "") ~= tostring(npcID or "")
    then
        return false, "conversation_unavailable"
    end
    local panel = view.extensionParts
        and view.extensionParts.relationship or nil
    if not panel or not panel.setRequirement then
        return false, "relationship_panel_unavailable"
    end
    if tostring(requirement or "") == "recruit"
        and type(context) ~= "table"
    then
        local presentation = Relationship.GetPresentation(npcID)
        local preview = presentation
            and presentation.recruitmentPreview or nil
        context = preview and preview.graphContext or {}
    end
    local ok, reason = panel:setRequirement(requirement, context)
    if ok == false then return false, reason end
    return true
end

function Relationship.ClearPreviewRequirement(npcID)
    return Relationship.SetPreviewRequirement(npcID, "inspect")
end

function Relationship.IsPresentationVisible()
    return Relationship.presentationVisible ~= false
end

function Relationship.SetPresentationVisible(visible)
    Relationship.presentationVisible = visible == true
    local view = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local panel = view and view.extensionParts
        and view.extensionParts.relationship or nil
    if panel and panel.setVisible then
        panel:setVisible(Relationship.IsPresentationVisible())
    end
end

function Relationship.OpenDossier(npcID)
    if PNC.NPCDossierUI and PNC.NPCDossierUI.Open then
        return PNC.NPCDossierUI.Open(npcID)
    end
    return nil
end

