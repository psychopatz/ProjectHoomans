local ClientState = PNC.Network.ClientState
local Definitions = PNC.NeedsDefinitions

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

function ISPNCNeedsDebugWindow:onAction(button)
    if button.internal == "refresh" then self:requestSnapshot(); return end
    if button.internal == "group_mode" then self.mode = "group"; self:refreshSnapshot(); return end
    if button.internal == "individual_mode" then self.mode = "individual"; self:refreshSnapshot(); return end
    if button.internal == "profile" then
        PNC.Client.SendDebug("needs_debug_action", { operation="profiling", enabled=not (ClientState.needsDebug and ClientState.needsDebug.profiler and ClientState.needsDebug.profiler.enabled), groupID=selected(self.groups) and selected(self.groups).id, npcID=selected(self.individuals) and selected(self.individuals).id })
        return
    end
    if button.internal == "supply_log" then
        PNC.Client.SendDebug("needs_debug_action", { operation="supply_logging", enabled=not (ClientState.needsDebug and ClientState.needsDebug.supplyLoggingEnabled), groupID=selected(self.groups) and selected(self.groups).id, npcID=selected(self.individuals) and selected(self.individuals).id })
        return
    end
    if button.internal == "need" then
        self.needIndex = ((self.needIndex or 1) % #Definitions.TYPES) + 1
        button:setTitle("NEED: " .. Definitions.TYPES[self.needIndex]:upper())
        return
    end
    local group, npc = selected(self.groups), selected(self.individuals)
    local owner, target = self.mode == "group" and group and group.value or nil, self.mode == "group" and "group" or nil
    if self.mode == "individual" and npc then owner, target = npc.value, "individual" end
    if not owner then return end
    local payload = { target=target, ownerID=owner.id, groupID=group and group.id, npcID=npc and npc.id }
    local id = button.internal
    if id == "force_eval" and target == "individual" then payload.operation = "force_supply_evaluation"
    elseif id == "force_food" and target == "individual" then payload.operation = "force_food_supply"
    elseif id == "force_water" and target == "individual" then payload.operation = "force_hydration_supply"
    elseif id == "force_medical" and target == "individual" then payload.operation = "force_medical_supply"
    elseif id == "clear_retry" and target == "individual" then payload.operation = "clear_supply_retry"
    elseif id == "dump_scores" and target == "individual" then payload.operation = "dump_candidate_scores"
    elseif id == "force_provision" and target == "individual" then payload.operation = "force_provision_evaluation"
    elseif id == "provision_dirty" and target == "individual" then payload.operation = "mark_provision_dirty"
    elseif id == "provision_retry" and target == "individual" then payload.operation = "clear_provision_retry"
    elseif id == "dump_provision" and target == "individual" then payload.operation = "dump_effective_provision"
    elseif id == "minus10" or id == "plus10" then payload.operation, payload.needType, payload.amount = "modify", Definitions.TYPES[self.needIndex or 1], id == "minus10" and -10 or 10
    elseif id == "set0" or id == "set25" or id == "set50" or id == "set75" or id == "set100" then payload.operation, payload.needType, payload.value = "set", Definitions.TYPES[self.needIndex or 1], tonumber(id:sub(4))
    elseif id == "reset" then payload.operation = "reset"
    elseif id == "hour" or id == "six_hours" or id == "day" then payload.operation, payload.hours = "simulate", id == "hour" and 1 or id == "six_hours" and 6 or 24
    elseif id == "scavenge" and target == "group" then payload.operation = "scavenge"
    elseif id == "activity" and target == "group" then payload.operation, payload.activity = "activity", owner.activity == "traveling" and "resting" or "traveling"
    else return end
    PNC.Client.SendDebug("needs_debug_action", payload)
end
