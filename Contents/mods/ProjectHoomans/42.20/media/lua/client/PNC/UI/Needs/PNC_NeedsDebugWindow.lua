require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.NeedsDebugUI = PNC.NeedsDebugUI or {}

local NeedsUI = PNC.NeedsDebugUI
local UI, Theme, Layout = PsychopatzCore.UI, PsychopatzCore.UI.Theme, PsychopatzCore.UI.Layout
local ClientState = PNC.Network.ClientState
local Definitions = PNC.NeedsDefinitions

local function text(value) return getText and getText(value) or value end
local function selected(list) local entry = list and list:getItem(); return entry and entry.item or nil end
local function drawItem(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(list, y, list.itemheight, list.selected == entry.index, alternate)
    list:drawText(Layout.Ellipsize(item.label, UIFont.Small, list:getWidth() - 14), 7, y + 4,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b, Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(item.detail or "", UIFont.Small, list:getWidth() - 14), 7, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g, Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end
ISPNCNeedsDebugWindow = PsychopatzWindow:derive("ISPNCNeedsDebugWindow")
function ISPNCNeedsDebugWindow:initialise() PsychopatzWindow.initialise(self) end
function ISPNCNeedsDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.groups = UI.CreateList(self, { itemHeight = 40, doDrawItem = drawItem })
    self.individuals = UI.CreateList(self, { itemHeight = 40, doDrawItem = drawItem })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 24,
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = 120,
        valueRightPadding = 10,
    })
    self.controls = {}
    local actions = { "refresh", "group_mode", "individual_mode", "profile", "supply_log", "need", "minus10", "plus10", "set0", "set25", "set50", "set75", "set100", "reset", "hour", "six_hours", "day", "scavenge", "activity", "force_eval", "force_food", "force_water", "force_medical", "clear_retry", "dump_scores", "force_provision", "provision_dirty", "provision_retry", "dump_provision" }
    for _, id in ipairs(actions) do self.controls[#self.controls + 1] = UI.CreateButton(self, { id = id, title = id:gsub("_", " "):upper(), target = self, onclick = ISPNCNeedsDebugWindow.onAction, variant = id == "scavenge" and "success" or "quiet" }) end
    self:requestResponsiveLayout(true)
    self.needIndex = 1
    self.mode = "group"
    self:requestSnapshot()
end
function ISPNCNeedsDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local flow = Layout.Flow(self.controls, { x = rect.x, y = rect.y, width = rect.width }, { scale = self.uiScale, minWidth = 68 })
    local top, gap = flow.bottom + 24, 8
    local width = math.floor((rect.width - gap * 2) * 0.25)
    self.layout = { groups = { x=rect.x,y=top,width=width,height=rect.height-(top-rect.y) }, individuals = { x=rect.x+width+gap,y=top,width=width,height=rect.height-(top-rect.y) }, details = { x=rect.x+width*2+gap*2,y=top,width=rect.width-width*2-gap*2,height=rect.height-(top-rect.y) } }
    for widget, bounds in pairs({ [self.groups]=self.layout.groups, [self.individuals]=self.layout.individuals, [self.details]=self.layout.details }) do Layout.SetBounds(widget, bounds.x,bounds.y,bounds.width,bounds.height) end
end
function ISPNCNeedsDebugWindow:requestSnapshot()
    local group, npc = selected(self.groups), selected(self.individuals)
    PNC.Client.RequestNeedsDebug(group and group.id, npc and npc.id)
    self.lastRequestAt = PNC.Core.Now()
end
function ISPNCNeedsDebugWindow:refreshSnapshot()
    local snapshot = ClientState.needsDebug or {}
    local oldGroup, oldNPC = selected(self.groups), selected(self.individuals)
    self.groups:clear(); self.individuals:clear(); self.details:clear()
    for _, group in ipairs(snapshot.groups or {}) do self.groups:addItem(group.name, { id=group.id, label=group.name, detail=string.format("%s | %d | H %.2f T %.2f F %.2f", group.type, group.members, group.needs.hunger, group.needs.thirst, group.needs.fatigue), value=group }) end
    for _, npc in ipairs(snapshot.individuals or {}) do self.individuals:addItem(npc.name, { id=npc.id, label=npc.name, detail=string.format("H %.2f T %.2f F %.2f | %.0f kcal %.1f kg", npc.needs.hunger, npc.needs.thirst, npc.needs.fatigue, npc.nutrition and npc.nutrition.calories or 0, npc.nutrition and npc.nutrition.weight or 0), value=npc }) end
    local function restore(list, id)
        for index, entry in ipairs(list.items or {}) do
            if entry.item and entry.item.id == id then list.selected = index; return end
        end
        if #list.items > 0 then list.selected = 1 end
    end
    restore(self.groups, snapshot.selectedGroup and snapshot.selectedGroup.id or oldGroup and oldGroup.id)
    restore(self.individuals, snapshot.selectedNPC and snapshot.selectedNPC.id or oldNPC and oldNPC.id)
    local group, npc = selected(self.groups), selected(self.individuals)
    local owner = self.mode == "group" and group and group.value or npc and npc.value
    local profiler = snapshot.profiler or {}
    self.details:addItem("profiler", { label="Profiler", value=profiler.enabled and "enabled" or "disabled" })
    if profiler.enabled and profiler.data then
        self.details:addItem("profile groups", { label="Group updates", value=tostring(profiler.data.groupUpdates or 0) })
        self.details:addItem("profile npc", { label="Individual updates", value=tostring(profiler.data.individualUpdates or 0) })
        self.details:addItem("profile duration", { label="Last pump ms", value=tostring(profiler.data.lastDurationMs or 0) })
    end
    self.details:addItem("supply logging", { label="Supply transaction log", value=snapshot.supplyLoggingEnabled and "enabled" or "disabled" })
    if profiler.supply then
        for _, metric in ipairs({ "supplyRequests", "supplyRequestsSatisfiedFromPersonalInventory", "supplyRequestsSentToStorage", "supplyRequestsSucceeded", "supplyRequestsFailed", "candidateQueries", "candidateItemsEvaluated", "supplyRetriesSuppressed", "reservationsCreated", "reservationFailures", "instantAcquisitions", "acquisitionFailures", "deltaInventoryMutations", "deltaInventoryCompactions", "deltaToFullPromotions", "provisionPolicyRevision", "provisionDirtyNPCs", "provisionEvaluations", "provisionRulesEvaluated", "provisionRulesSatisfied", "provisionRulesDeficient", "provisionRequestsCreated", "provisionRequestsSucceeded", "provisionRequestsFailed", "provisionRequestsSuppressedByIncoming", "provisionRequestsSuppressedByNeedRequest", "provisionSchedulerQueueSize", "provisionSchedulerProcessed", "provisionStorageShortages" }) do
            self.details:addItem(metric, { label=metric, value=tostring(profiler.supply[metric] or 0) })
        end
    end
    if owner then
        for _, line in ipairs({ {"Owner", owner.owner or owner.faction or owner.name}, {"ID", owner.id}, {"Activity", owner.activity or "idle"}, {"Location", owner.location and string.format("%.0f, %.0f, %.0f", owner.location.x or 0, owner.location.y or 0, owner.location.z or 0) or "n/a"}, {"Next destination", owner.destination and tostring(owner.destination) or "n/a"}, {"Last update", tostring(owner.needs.lastUpdateWorldAge)}, {"Elapsed hours", string.format("%.2f", owner.elapsed or 0)} }) do self.details:addItem(line[1], { label=line[1], value=line[2] }) end
        for _, needType in ipairs(Definitions.TYPES) do self.details:addItem(needType, { label=needType:upper() .. " / condition", value=string.format("%.2f / 1  %s%s", owner.needs[needType], Definitions.GetLevel(needType, owner.needs[needType]), owner.rates and string.format("  rate %+.4f/h", owner.rates[needType]) or "") }) end
        if self.mode == "individual" then
            for _, statType in ipairs(PNC.ConditionStats
                and PNC.ConditionStats.TYPES or {})
            do
                local definition = PNC.ConditionStats.DEFINITIONS[statType]
                local amount = tonumber(owner.conditionStats
                    and owner.conditionStats[statType]) or definition.default
                self.details:addItem("condition " .. statType, {
                    label = statType:upper() .. " / condition",
                    value = string.format("%.2f / %.2f  %s  rate %+.3f/h",
                        amount, definition.maximum,
                        PNC.ConditionStats.GetLevel(statType, amount),
                        tonumber(owner.conditionRates
                            and owner.conditionRates[statType]) or 0),
                })
            end
            self.details:addItem("inventory mode", { label="Inventory mode", value=tostring(owner.inventoryMode or "UNKNOWN") })
            self.details:addItem("delta records", { label="Delta record count", value=tostring(owner.deltaRecordCount or 0) })
            self.details:addItem("promotion", { label="FULL promotion reason", value=tostring(owner.fullPromotionReason or "none") })
            local supply = owner.supply or {}
            self.details:addItem("supply current", { label="Current supply kind", value=tostring(supply.currentKind or "none") })
            for _, kind in ipairs({ "FOOD", "HYDRATION", "MEDICAL" }) do
                local lane = supply.byKind and supply.byKind[kind] or {}
                self.details:addItem("supply " .. kind, { label=kind .. " state", value=string.format("%s | %s | retry %.2f", tostring(lane.phase or "IDLE"), tostring(lane.lastResult or lane.lastFailureReason or "none"), tonumber(lane.nextRetry) or 0) })
                self.details:addItem("candidates " .. kind, { label=kind .. " candidates", value=string.format("personal %d | storage %d | selected %d", tonumber(lane.personalCandidateCount) or 0, tonumber(lane.storageCandidateCount) or 0, #(lane.selected or {})) })
                for _, selectedItem in ipairs(lane.selected or {}) do
                    self.details:addItem("selected", { label="  selected", value=string.format("%s x%d score %.1f", tostring(selectedItem.fullType), tonumber(selectedItem.quantity) or 0, tonumber(selectedItem.score) or 0) })
                end
            end
            local provision = owner.provision or {}
            self.details:addItem("provision last", { label="Provision last evaluation", value=tostring(provision.lastEvaluation or "none") })
            for _, definition in ipairs(PNC.ProvisionRuleRegistry.List()) do
                local value = provision.evaluations
                    and provision.evaluations[definition.id] or {}
                self.details:addItem("provision " .. definition.id, {
                    label = "Provision " .. definition.id,
                    value = string.format("on %.1f + in %.1f | < %.1f -> %.1f | %s | %s",
                        tonumber(value.onHand) or 0,
                        tonumber(value.incoming) or 0,
                        tonumber(value.refillBelow) or 0,
                        tonumber(value.target) or 0,
                        value.satisfied and "satisfied" or "deficient",
                        tostring(value.policySource or "unknown")),
                })
            end
        end
        for _, entry in ipairs(owner.history or {}) do self.details:addItem("history", { label=tostring(entry.reason), value=tostring(entry.needType) .. " " .. tostring(entry.before) .. " -> " .. tostring(entry.after) }) end
    end
    self.lastReceiveAt = ClientState.lastNeedsDebugReceiveAt or PNC.Core.Now()
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
function ISPNCNeedsDebugWindow:prerender()
    local received = ClientState.lastNeedsDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then self:refreshSnapshot() end
    if PNC.Core.Now() - (self.lastRequestAt or 0) > 3000 then self:requestSnapshot() end
    PsychopatzWindow.prerender(self)
end
function ISPNCNeedsDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then UI.DrawSectionTitle(self, (self.mode == "group" and "[ACTIVE] " or "") .. "GROUP NEEDS", self.layout.groups.x, self.layout.groups.y - 20, self.layout.groups.width); UI.DrawSectionTitle(self, (self.mode == "individual" and "[ACTIVE] " or "") .. "INDIVIDUAL NPC", self.layout.individuals.x, self.layout.individuals.y - 20, self.layout.individuals.width); UI.DrawSectionTitle(self, "DETAIL / HISTORY", self.layout.details.x, self.layout.details.y - 20, self.layout.details.width) end
end
function ISPNCNeedsDebugWindow:close() self:setVisible(false); self:removeFromUIManager(); NeedsUI.instance=nil end
function ISPNCNeedsDebugWindow:new(x,y,w,h,options) local object=PsychopatzWindow:new(x,y,w,h,options); setmetatable(object,self); self.__index=self; return object end
function NeedsUI.Open()
    if not PNC.Client.CanUseDebug() then return nil end
    local window=NeedsUI.instance
    if not window then window=UI.NewWindow(ISPNCNeedsDebugWindow,{ title="NPC NEEDS DEBUG",resizable=true,responsiveSpec={width=1100,height=680,minWidth=760,minHeight=480,maxWidth=1500,maxHeight=960} }); window:initialise(); window:instantiate(); NeedsUI.instance=window end
    window:addToUIManager(); window:setVisible(true); window:bringToTop(); window:requestSnapshot(); return window
end
function NeedsUI.Toggle() if NeedsUI.instance and NeedsUI.instance:getIsVisible() then NeedsUI.instance:close(); return false end return NeedsUI.Open() ~= nil end
return NeedsUI
