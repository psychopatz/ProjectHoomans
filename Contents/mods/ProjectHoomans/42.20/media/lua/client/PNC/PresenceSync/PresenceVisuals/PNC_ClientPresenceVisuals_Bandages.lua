--[[
    PNC Client Presence Visuals: persistent wound bandages

    Hoomans owns wound state in its NPC record. Project Zomboid's zombie
    presentation path owns the visible wrap through HumanVisual body visuals,
    so this module reconciles the two without mutating BodyDamage, inventory,
    worn items, or persistent ModData.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal

-- Java userdata is a suitable weak-table key. This keeps presentation state
-- attached to the live body only and prevents a save-data cache from growing.
local StateByBody = setmetatable({}, { __mode = "k" })

local FALLBACK_PART_ORDER = {
    "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R",
    "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R",
    "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

local function woundDefinitions()
    local wounds = PNC.NPCWounds
    return wounds and wounds.Parts or nil
end

local function woundPartOrder()
    local wounds = PNC.NPCWounds
    return wounds and wounds.PartOrder or FALLBACK_PART_ORDER
end

local function resolveEngineBodyPart(partID)
    local parts = woundDefinitions()
    local definition = parts and parts[partID] or nil
    local engineName = definition and definition.engine or partID
    local bodyPart
    if not BodyPartType or not engineName then
        return nil
    end
    bodyPart = BodyPartType.FromString(tostring(engineName))
    return bodyPart
end

local function partInfo(partID)
    local bodyPart = resolveEngineBodyPart(partID)
    local model
    if not bodyPart or not bodyPart.getBandageModel then
        return nil
    end
    model = bodyPart:getBandageModel()
    if model == nil or tostring(model) == "" then
        return nil
    end
    return {
        bodyPart = bodyPart,
        model = tostring(model),
        bloodModel = tostring(model) .. "_Blood",
    }
end

local function getHumanVisual(zombie)
    return zombie and zombie.getHumanVisual
        and zombie:getHumanVisual() or nil
end

local function hasBodyVisual(humanVisual, fullType)
    if not humanVisual or not fullType then
        return false
    end
    return humanVisual:hasBodyVisualFromItemType(fullType) == true
end

local function removeBodyVisual(humanVisual, fullType)
    if not humanVisual or not fullType then
        return false
    end
    return humanVisual:removeBodyVisualFromItemType(fullType) ~= nil
end

local function addBodyVisual(zombie, info, bloody)
    if not zombie or not info then
        return false
    end
    zombie:addVisualBandage(info.bodyPart, bloody == true)
    return true
end

local function refreshModel(zombie)
    if not zombie then
        return
    end
    zombie:resetModelNextFrame()
end

local function identityKey(snapshot)
    return table.concat({
        tostring(snapshot and snapshot.id or ""),
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(snapshot and snapshot.liveBodyInstanceID or ""),
        tostring(snapshot and snapshot.liveBodyOnlineID or ""),
    }, "|")
end

local function captureBaseline(state, partID, info, humanVisual)
    if state.baseline[partID] ~= nil then
        return
    end
    state.baseline[partID] = {
        clean = hasBodyVisual(humanVisual, info.model),
        blood = hasBodyVisual(humanVisual, info.bloodModel),
    }
end

local function restoreBaseline(info, baseline, humanVisual, zombie)
    local changed = false
    if not baseline then
        return false
    end
    if baseline.clean and not hasBodyVisual(humanVisual, info.model) then
        if addBodyVisual(zombie, info, false) then
            changed = true
        end
    end
    if baseline.blood and not hasBodyVisual(humanVisual, info.bloodModel) then
        if addBodyVisual(zombie, info, true) then
            changed = true
        end
    end
    return changed
end

local function clearStateVisuals(state, zombie)
    local humanVisual = getHumanVisual(zombie)
    local partID
    local entry
    local info
    local changed = false
    if not humanVisual then
        return false
    end
    for partID, entry in pairs(state.active or {}) do
        info = partInfo(partID)
        if info and entry and entry.owned then
            if removeBodyVisual(humanVisual, entry.fullType) then
                changed = true
            end
        end
    end
    for partID, baseline in pairs(state.baseline or {}) do
        info = partInfo(partID)
        if info and restoreBaseline(info, baseline, humanVisual, zombie) then
            changed = true
        end
    end
    return changed
end

local function reconcilePart(state, zombie, humanVisual, partID, wound)
    local info = partInfo(partID)
    local baseline
    local active
    local desiredType
    local changed = false
    local added = false
    local owned = false
    if not info then
        return false
    end
    captureBaseline(state, partID, info, humanVisual)
    baseline = state.baseline[partID]
    active = state.active[partID]

    if not wound or wound.bandaged ~= true then
        if active and active.owned
            and removeBodyVisual(humanVisual, active.fullType)
        then
            changed = true
        end
        state.active[partID] = nil
        if restoreBaseline(info, baseline, humanVisual, zombie) then
            changed = true
        end
        return changed
    end

    desiredType = wound.bandageDirty == true
        and info.bloodModel or info.model
    if active and active.fullType ~= desiredType and active.owned
        and removeBodyVisual(humanVisual, active.fullType)
    then
        changed = true
        active = nil
    elseif active and active.fullType ~= desiredType then
        active = nil
    end

    -- A managed wound takes precedence over a natural zombie wrap on the
    -- same body part. The baseline is restored when the wound disappears.
    if desiredType ~= info.model
        and baseline.clean
        and removeBodyVisual(humanVisual, info.model)
    then
        changed = true
    elseif desiredType ~= info.bloodModel
        and baseline.blood
        and removeBodyVisual(humanVisual, info.bloodModel)
    then
        changed = true
    end

    if not hasBodyVisual(humanVisual, desiredType) then
        added = addBodyVisual(
            zombie,
            info,
            wound.bandageDirty == true
        )
        changed = added or changed
    end
    owned = added or (
        active
        and active.fullType == desiredType
        and active.owned == true
    ) or false
    state.active[partID] = {
        fullType = desiredType,
        owned = owned,
    }
    return changed
end

local function releaseState(state, zombie)
    if clearStateVisuals(state, zombie) then
        refreshModel(zombie)
    end
end

local function syncBandageVisuals(zombie, snapshot)
    local bodyHealth = snapshot and snapshot.bodyHealth or nil
    local wounds = bodyHealth and bodyHealth.wounds or nil
    local order = woundPartOrder()
    local bodyState
    local humanVisual
    local key
    local partID
    local wound
    local info
    local changed = false
    local i

    -- A missing bodyHealth block means the snapshot is not authoritative for
    -- wounds yet. Never erase a visible wrap because of incomplete data.
    if type(bodyHealth) ~= "table" or type(wounds) ~= "table" then
        return false, nil
    end
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return false, nil
    end
    humanVisual = getHumanVisual(zombie)
    if not humanVisual then
        return false, nil
    end

    key = identityKey(snapshot)
    bodyState = StateByBody[zombie]
    if bodyState and bodyState.identity ~= key then
        releaseState(bodyState, zombie)
        bodyState = nil
    end
    if not bodyState then
        bodyState = {
            identity = key,
            baseline = {},
            active = {},
        }
        StateByBody[zombie] = bodyState
    end

    for i = 1, #order do
        partID = tostring(order[i])
        wound = wounds[partID]
        info = partInfo(partID)
        if info and reconcilePart(
            bodyState,
            zombie,
            humanVisual,
            partID,
            wound
        ) then
            changed = true
        end
    end
    if changed then
        refreshModel(zombie)
    end
    return changed
end

function Internal.SyncBandageVisuals(zombie, snapshot)
    return syncBandageVisuals(zombie, snapshot)
end

function Internal.ResetClientBandageVisuals()
    local zombie
    local state
    for zombie, state in pairs(StateByBody) do
        if state then
            releaseState(state, zombie)
        end
        StateByBody[zombie] = nil
    end
end

return Sync
