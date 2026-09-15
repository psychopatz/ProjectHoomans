-- Faction debug window action payload construction.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local ClientState = Internal.ClientState
local function nextValue(values, current)
    local ordered = {}
    for key, enabled in pairs(values or {}) do
        if enabled == true then ordered[#ordered + 1] = key end
    end
    table.sort(ordered)
    if #ordered == 0 then return nil end
    for index, value in ipairs(ordered) do
        if value == current then
            return ordered[(index % #ordered) + 1]
        end
    end
    return ordered[1]
end

local function readGroupSize(self)
    local enteredGroupSize = tonumber(
        self.groupSizeEntry
            and self.groupSizeEntry:getText()
            or self.groupSize
    )
    enteredGroupSize = math.max(
        1,
        math.min(24, math.floor(enteredGroupSize or 4))
    )
    self.groupSize = enteredGroupSize
    if self.groupSizeEntry then
        self.groupSizeEntry:setText(
            tostring(enteredGroupSize)
        )
    end
    return enteredGroupSize
end

local function applyCreationPayload(payload, internal)
    if internal == "create_player_faction" then
        payload.factionAction = internal
    elseif internal == "create_looter_group" then
        payload.factionAction = "create"
        payload.archetypeID = "looter"
        payload.creationKind = "mobile_group"
        payload.refreshMobileObjective = true
    elseif internal == "create_ambient_looter_group" then
        payload.factionAction = "create"
        payload.archetypeID = "looter"
        payload.creationKind = "mobile_group"
        payload.mobilePathMode = "random"
        payload.mobileControlMode = "ambient"
        payload.refreshMobileObjective = true
    elseif internal == "create_strategic_looter_group" then
        payload.factionAction = "create"
        payload.archetypeID = "looter"
        payload.creationKind = "mobile_group"
        payload.mobilePathMode = "player"
        payload.mobileControlMode = "strategic"
        payload.refreshMobileObjective = true
    elseif internal == "create_trader" then
        payload.factionAction = "create"
        payload.archetypeID = "trader"
        payload.creationKind = "mobile_group"
        payload.refreshMobileObjective = true
    elseif internal == "create_refugee" then
        payload.factionAction = "create"
        payload.archetypeID = "refugee"
        payload.creationKind = "mobile_group"
        payload.refreshMobileObjective = true
    elseif internal == "create_mobile_road_group" then
        payload.factionAction = internal
        payload.archetypeID = "looter"
        payload.creationKind = "mobile_group"
        payload.mobilePathMode = "random"
        payload.mobileControlMode = "ambient"
        payload.refreshMobileObjective = false
    elseif internal == "create_mobile_player_route_group" then
        payload.factionAction = internal
        payload.archetypeID = "looter"
        payload.creationKind = "mobile_group"
        payload.mobilePathMode = "player"
        payload.mobileControlMode = "strategic"
        payload.presenceMode = "abstract"
        payload.refreshMobileObjective = false
    elseif internal == "create_mobile_ai_route_group" then
        payload.factionAction = internal
        payload.archetypeID = "refugee"
        payload.creationKind = "mobile_group"
        payload.mobilePathMode = "random"
        payload.mobileControlMode = "ambient"
        payload.presenceMode = "abstract"
        payload.refreshMobileObjective = false
    elseif internal == "mobile_relocate" then
        payload.factionAction = "mobile_relocate"
    elseif internal == "generate_group" then
        payload.factionAction = "generate_group"
    elseif internal == "mobile_path_mode" then
        payload.factionAction = "mobile_path_mode"
        payload.refreshMobileObjective = true
    elseif internal == "mobile_control_mode" then
        payload.factionAction = "mobile_control_mode"
        payload.refreshMobileObjective = true
    elseif internal == "mobile_refresh" then
        payload.factionAction = "mobile_refresh"
    elseif internal == "force_mobile_road"
        or internal == "force_mobile_departure"
        or internal == "force_mobile_arrival"
        or internal == "repair_mobile_travel"
    then
        payload.factionAction = internal
    elseif internal == "roll_mobile_departures" then
        payload.factionAction = internal
        payload.departureBudget = 12
    elseif string.sub(internal, 1, 7) == "create_" then
        payload.factionAction = "create"
        payload.archetypeID = string.sub(internal, 8)
    else
        payload.factionAction = internal
    end
end

local function applyScenarioPayload(self, payload, internal)
    if internal ~= "run_scenario" then return end
    local names = ClientState.factionDebug
        and ClientState.factionDebug.scenarioNames or {}
    payload.scenarioName = self.scenarioName
        or names[self.scenarioIndex or 1]
        or "single_minor_attack"
end

local function applyMemberPayload(payload, internal, faction, npc)
    if internal == "role" and faction and npc then
        local archetype = PNC.FactionArchetypes.Get(
            faction.faction.archetypeID
        )
        payload.role = nextValue(
            archetype and archetype.allowedRoles,
            npc.npc.affiliation and npc.npc.affiliation.role
        )
    elseif internal == "rank" and npc then
        payload.rank = nextValue(
            PNC.FactionConstants.VALID_RANKS,
            npc.npc.affiliation and npc.npc.affiliation.rank
        )
    end
end

function Internal.SendAction(self, internal, faction, npc, target)
    local enteredGroupSize = readGroupSize(self)
    local payload = {
        factionID = faction and faction.id,
        npcID = npc and npc.id,
        targetFactionID = target and target.id,
        groupSize = enteredGroupSize,
        presenceMode = self.presenceMode,
        mobilePathMode = self.mobilePathMode,
        mobileControlMode = self.mobileControlMode,
    }
    applyCreationPayload(payload, internal)
    applyScenarioPayload(self, payload, internal)
    applyMemberPayload(payload, internal, faction, npc)
    PNC.Client.SendDebug("faction_debug_action", payload)
end
