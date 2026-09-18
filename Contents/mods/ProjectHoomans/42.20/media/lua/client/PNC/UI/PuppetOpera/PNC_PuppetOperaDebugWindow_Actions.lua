-- Editor and runtime actions for the Puppet Opera scene builder.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
local Model = Internal.Model
local Client = Internal.Client
local tr = Internal.tr
local Class = ISPNCPuppetOperaDebugWindow

function Class:setEditorStatus(message, isError)
    self.editorStatus = message and tostring(message) or nil
    Model.State.editorError = isError and self.editorStatus or nil
end

function Class:clearEditorStatus()
    self.editorStatus = nil
    Model.State.editorError = nil
end

function Class:onBlueprintChanged()
    self:clearEditorStatus()
    local index = tonumber(self.blueprintCombo.selected) or 1
    local blueprint = self.blueprints and self.blueprints[index]
    if blueprint then
        local accepted, reason = Model.SetBlueprintID(blueprint.id)
        if not accepted then self:setEditorStatus(reason, true) end
    end
    self:refreshViews()
end

function Class:onActorChanged()
    self:clearEditorStatus()
    local index = tonumber(self.actorCombo.selected) or 1
    local actor = index > 1 and self.actorSlots and self.actorSlots[index - 1]
        or nil
    if actor then
        Model.SelectActor(actor.id)
    else
        Model.SelectActor(nil)
    end
    self:refreshViews()
end

function Class:onTopAction(button)
    local id = button and button.internal or ""
    local accepted
    local reason
    if id == "create" then
        accepted, reason = Model.CreateNew()
    elseif id == "duplicate" then
        accepted, reason = Model.DuplicateBlueprint()
    elseif id == "save" then
        accepted, reason = Model.SaveDraft()
    elseif id == "reset" then
        accepted, reason = Model.ResetDraft()
    end
    if not accepted then
        self:setEditorStatus(reason, true)
    else
        self:setEditorStatus(id .. "_complete")
    end
    self:refreshViews()
    local snapshot = Client.GetSnapshot and Client.GetSnapshot() or nil
    if accepted and snapshot and snapshot.preview == true then
        self:requestPlacementPreview()
    end
end

function Class:prepareRuntime()
    local saved, saveReason = Model.SaveDraft()
    if not saved then
        self:setEditorStatus(saveReason, true)
        return nil
    end
    local schemaOK, runtimeReason, normalized = Model.GetValidation()
    if not schemaOK then
        self:setEditorStatus(runtimeReason, true)
        return nil
    end
    if runtimeReason then
        self:setEditorStatus(
            "not_server_approved:" .. tostring(runtimeReason),
            true
        )
        return nil
    end
    return normalized
end

function Class:requestPlacementPreview(force)
    if not Client.StartPlacementPreview then
        self:setEditorStatus("placement_preview_unavailable", true)
        return false
    end
    local schemaOK, runtimeReason, normalized = Model.GetValidation()
    if not schemaOK then
        self:setEditorStatus(runtimeReason, true)
        return false
    end
    if runtimeReason then
        self:setEditorStatus(
            "not_server_approved:" .. tostring(runtimeReason),
            true
        )
        return false
    end
    local bindings, bindingReason = Model.GetRuntimeActorBindings()
    if not bindings then
        self:setEditorStatus(
            "placement_preview_blocked:" .. tostring(bindingReason),
            true
        )
        return false
    end
    local key = Model.GetBlueprintID() .. ":"
        .. tostring(Model.GetChangeSerial())
    local accepted, reason = Client.StartPlacementPreview(
        Model.GetBlueprintID(),
        normalized,
        bindings,
        key,
        force == true
    )
    if not accepted then self:setEditorStatus(reason, true) end
    return accepted == true
end

function Class:onControl(button)
    local id = button and button.internal or ""
    local blueprintID = Model.GetBlueprintID()
    local definition
    if id == "play" or id == "replay" then
        self:clearEditorStatus()
        definition = self:prepareRuntime()
        if definition then
            local bindings, bindingReason = Model.GetRuntimeActorBindings()
            if not bindings then
                self:setEditorStatus(bindingReason, true)
            elseif id == "play" then
                local accepted, reason = Client.Start(blueprintID, nil,
                    self.loopEnabled, definition, bindings)
                if not accepted then self:setEditorStatus(reason, true) end
            else
                local accepted, reason = Client.Replay(blueprintID, nil,
                    self.loopEnabled, definition, bindings)
                if not accepted then self:setEditorStatus(reason, true) end
            end
        end
    elseif id == "loop" then
        self.loopEnabled = not self.loopEnabled
        button:setTitle(
            tr("UI_PNC_PuppetOpera_Loop", "Loop")
                .. ": " .. (self.loopEnabled and "ON" or "OFF")
        )
    elseif id == "stop" then
        Client.Stop()
    elseif id == "trace" then
        Client.DumpTrace()
    elseif id == "clear" then
        Client.ClearStatus()
        self:clearEditorStatus()
    end
    self:refreshViews()
end

function Class:prerender()
    PsychopatzWindow.prerender(self)
    self.refreshCounter = self.refreshCounter + 1
    if self.refreshCounter % 10 == 0
        and not (self.layoutTab and self.layoutTab.liveDragPending)
    then
        self:refreshViews()
        if Client.RefreshPlacementPreview then
            Client.RefreshPlacementPreview(false)
        end
    end
end

return Class
