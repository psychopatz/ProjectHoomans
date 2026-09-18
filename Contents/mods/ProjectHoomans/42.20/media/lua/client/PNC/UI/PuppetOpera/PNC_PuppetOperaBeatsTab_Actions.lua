-- Mutation routing for the Puppet Opera beat tab.

PNC = PNC or {}

local Class = ISPNCPuppetOperaBeatsTab

local function hasMethod(target, name)
    return target and type(target[name]) == "function"
end

local function reportUnavailable(self, reason)
    local owner = self.ownerWindow
    if owner and type(owner.setEditorStatus) == "function" then
        owner:setEditorStatus(reason, true)
    end
    return false
end

function Class:onAction(button)
    local model = self.model
    if not model then return reportUnavailable(self, "beat_model_unavailable") end
    local id = button and button.internal or ""
    local method
    local argument
    if id == "add" or id == "duplicate" then
        method = "AddBeat"
    elseif id == "remove" then
        method = "RemoveBeat"
    elseif id == "up" then
        method = "MoveBeat"
        argument = -1
    elseif id == "down" then
        method = "MoveBeat"
        argument = 1
    elseif id == "apply_duration" then
        method = "SetBeatDuration"
        if not self.durationEntry
            or type(self.durationEntry.getText) ~= "function"
        then
            return reportUnavailable(self, "duration_input_unavailable")
        end
        argument = self.durationEntry:getText()
    else
        local owner = self.ownerWindow
        if owner and type(owner.setEditorStatus) == "function" then
            owner:setEditorStatus("unknown_beat_action", true)
        end
        return false
    end
    if not hasMethod(model, method) then
        return reportUnavailable(self, "beat_model_unavailable")
    end
    local accepted
    local reason
    if argument == nil then
        accepted, reason = model[method]()
    else
        accepted, reason = model[method](argument)
    end
    if not accepted then
        local owner = self.ownerWindow
        if owner and type(owner.setEditorStatus) == "function" then
            owner:setEditorStatus(reason)
        end
        return false
    end
    local owner = self.ownerWindow
    if owner then
        if type(owner.setEditorStatus) == "function" then
            owner:setEditorStatus("beat_updated")
        end
        if type(owner.refreshViews) == "function" then
            owner:refreshViews()
        end
    end
    return true
end

return Class
