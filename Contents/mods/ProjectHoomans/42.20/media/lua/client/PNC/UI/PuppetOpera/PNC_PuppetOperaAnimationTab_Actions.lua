-- Preview and scene-assignment actions for the animation catalog tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaAnimationTabInternal
local tr = Internal.tr
local Class = ISPNCPuppetOperaAnimationTab

local function getClient()
    local opera = PNC.PuppetOpera
    return opera and opera.Client
end

local function reportUnavailable(self, reason)
    if self.ownerWindow and self.ownerWindow.setEditorStatus then
        self.ownerWindow:setEditorStatus(reason, true)
    end
    return false
end

function Class:onAction(button)
    local owner = self.ownerWindow
    if not owner then return false end
    local client = getClient()
    if button and button.internal == "loop_preview" then
        if not client or not client.GetPreviewLoopEnabled
            or not client.SetPreviewLoopEnabled
        then
            return reportUnavailable(self, "preview_client_unavailable")
        end
        local enabled = not client.GetPreviewLoopEnabled()
        client.SetPreviewLoopEnabled(enabled)
        if button.setTitle then
            button:setTitle(tr("UI_PNC_PuppetOpera_LoopPreview",
                "Loop preview") .. ": " .. (enabled and "ON" or "OFF"))
        end
        owner:setEditorStatus(
            enabled and "preview_loop_enabled" or "preview_loop_disabled")
        return true
    end
    local entry = self:getSelectedEntry()
    if not entry then return false end
    local model = owner.model
    if not model then
        return reportUnavailable(self, "animation_model_unavailable")
    end
    if button and button.internal == "preview" then
        if not client then
            return reportUnavailable(self, "preview_client_unavailable")
        end
        local target, targetReason = model.GetPreviewTarget(self.catalogName)
        if not target then
            owner:setEditorStatus(targetReason, true)
            return false
        end
        local accepted
        local reason
        if self.catalogName == "player" then
            if not client.PreviewPlayer then
                return reportUnavailable(self, "preview_client_unavailable")
            end
            accepted, reason = client.PreviewPlayer(entry)
        else
            if not client.PreviewNPC then
                return reportUnavailable(self, "preview_client_unavailable")
            end
            if not target.body or not target.record then
                owner:setEditorStatus(
                    "animation_target_npc_not_local", true)
                return false
            end
            accepted, reason = client.PreviewNPC(
                entry,
                target.liveID,
                target.body,
                target.record
            )
        end
        owner:setEditorStatus(
            accepted and "preview_started" or reason,
            not accepted
        )
        owner:refreshViews()
        return accepted == true
    end
    if button and button.internal == "stop_preview" then
        if not client or not client.StopPreview then
            return reportUnavailable(self, "preview_client_unavailable")
        end
        client.StopPreview()
        owner:setEditorStatus("preview_stopped")
        owner:refreshViews()
        return true
    end
    if not model.GetActorForCatalog or not model.AssignAnimation then
        return reportUnavailable(self, "animation_model_unavailable")
    end
    local actorID = model.GetActorForCatalog(self.catalogName)
    if not actorID then
        owner:setEditorStatus("no_matching_scene_actor", true)
        return false
    end
    local accepted, reason = model.AssignAnimation(actorID, entry)
    if not accepted then
        owner:setEditorStatus(reason)
        return false
    end
    owner:setEditorStatus("assigned:" .. actorID)
    owner:refreshViews()
    return true
end

return Class
