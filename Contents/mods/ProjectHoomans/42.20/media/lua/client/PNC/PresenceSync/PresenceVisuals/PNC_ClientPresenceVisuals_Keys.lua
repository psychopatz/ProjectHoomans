--[[
    PNC Client Presence Visuals: stable presentation keys
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal

local function stableValueSignature(value, seen)
    local valueType = type(value)
    local entries
    local key
    local entry
    local i
    if valueType ~= "table" then
        return valueType .. ":" .. tostring(value)
    end
    if seen[value] then
        return "table:<cycle>"
    end
    seen[value] = true
    entries = {}
    for key, _ in pairs(value) do
        entries[#entries + 1] = {
            key = key,
            keySignature = type(key) .. ":" .. tostring(key),
        }
    end
    table.sort(entries, function(left, right)
        return left.keySignature < right.keySignature
    end)
    for i = 1, #entries do
        entry = entries[i]
        entries[i] = entry.keySignature
            .. "="
            .. stableValueSignature(value[entry.key], seen)
    end
    seen[value] = nil
    return "table:{" .. table.concat(entries, ";") .. "}"
end

local function stableTableSignature(tbl)
    if type(tbl) ~= "table" then
        return ""
    end
    return stableValueSignature(tbl, {})
end

local function buildVisualKey(snapshot)
    local appearance = snapshot and snapshot.appearance or {}
    local equipment = snapshot and snapshot.equipmentSummary or {}
    return table.concat({
        tostring(snapshot and snapshot.liveBodyInstanceID or ""),
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(snapshot and snapshot.liveBodyOnlineID or ""),
        tostring(snapshot and snapshot.visualProfile or ""),
        tostring(snapshot and snapshot.isFemale == true),
        tostring(appearance.outfit or ""),
        tostring(appearance.skinTexture or ""),
        stableTableSignature(appearance.skinColor),
        tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""),
        stableTableSignature(equipment.worn),
        stableTableSignature(equipment.wornVisuals),
        stableTableSignature(equipment.attached),
    }, "|")
end

local function buildHandsKey(snapshot)
    local equipment = snapshot and snapshot.equipmentSummary or {}
    return table.concat({
        tostring(snapshot and snapshot.liveBodyInstanceID or ""),
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(snapshot and snapshot.liveBodyOnlineID or ""),
        tostring(snapshot and snapshot.attackMode == true),
        tostring(equipment.primaryFullType or ""),
        stableTableSignature(equipment.primaryVisual),
        tostring(equipment.secondaryFullType or ""),
    }, "|")
end

Sync.Internal.BuildVisualKey = buildVisualKey
Sync.Internal.BuildHandsKey = buildHandsKey

local function buildMotionKey(snapshot)
    local visualState = snapshot and snapshot.visualState or {}
    local treatment = snapshot and snapshot.treatmentState or {}
    return table.concat({
        tostring(snapshot and snapshot.presenceRevision or 0),
        tostring(snapshot and snapshot.healthState or "normal"),
        tostring(visualState.anim or "Idle"),
        tostring(visualState.moveAnim or ""),
        tostring(visualState.walkType or ""),
        tostring(visualState.engineWalkType or ""),
        tostring(visualState.mode or ""),
        tostring(visualState.moving == true),
        tostring(visualState.attackActive == true),
        tostring(visualState.attackAnim or ""),
        tostring(visualState.attackFinishAt or 0),
        tostring(tonumber(visualState.animSpeed) or 1.0),
        tostring(visualState.isRunning == true),
        tostring(visualState.isCrawling == true),
        tostring(visualState.profileKey or ""),
        tostring(visualState.specialActive == true),
        tostring(visualState.specialAnim or ""),
        tostring(visualState.specialFinishAt or 0),
        tostring(visualState.nativeMoveActive == true),
        tostring(visualState.nativeMoveRevision or 0),
        tostring(treatment.phase or "idle"),
        tostring(treatment.partId or ""),
        tostring(treatment.startedAt or 0),
        tostring(treatment.finishAt or 0),
        tostring(visualState.sceneActive == true),
        tostring(visualState.sceneId or ""),
        tostring(visualState.sceneBump or ""),
        tostring(visualState.sceneRevision or 0),
        tostring(visualState.scenePlaybackRevision or 0),
        tostring(visualState.sceneFinishAt or 0),
        tostring(visualState.sceneNextStepAt or 0),
        tostring(visualState.sceneLoop == true),
        tostring(visualState.sceneRepeatMode or "once"),
    }, "|")
end


Internal.BuildMotionKey = buildMotionKey
