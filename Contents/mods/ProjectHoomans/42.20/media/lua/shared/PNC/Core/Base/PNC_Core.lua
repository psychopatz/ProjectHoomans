PNC = PNC or {}
PNC.Core = PNC.Core or {}
PNC.Runtime = PNC.Runtime or {}

local Core = PNC.Core
local RuntimeRole = PsychopatzCore and PsychopatzCore.RuntimeRole or nil
if not RuntimeRole then
    local loaded, value = pcall(
        require,
        "PsychopatzCore/Runtime/PC_RuntimeRole"
    )
    if loaded and type(value) == "table" then RuntimeRole = value end
end

local function nowMillis()
    if getTimeInMillis then
        return getTimeInMillis()
    end
    if getTimestampMs then
        return getTimestampMs()
    end
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return math.floor((tonumber(getGameTime():getWorldAgeHours()) or 0) * 3600000)
    end
    return 0
end

function Core.IsClientOnly()
    if RuntimeRole and RuntimeRole.IsPureClient then
        return RuntimeRole.IsPureClient()
    end
    return isClient and isClient()
        and (not isServer or not isServer()) or false
end

function Core.IsAuthority()
    if RuntimeRole and RuntimeRole.AllowsServerCode then
        return RuntimeRole.AllowsServerCode()
    end
    return not Core.IsClientOnly()
end

function Core.IsManagedNPCBody(zombie)
    local modData
    local onlineID
    local clientBodyIDs
    if not zombie or not zombie.getModData then
        return false
    end
    modData = zombie:getModData()
    if modData and (modData.PNC_NPC == true
        or modData.PNC_PersistedShell == true
        or (modData.PNC_UUID ~= nil and modData.PNC_BodyKind == "live"))
    then
        return true
    end
    -- PNCLive is persisted by some older body versions even when their Lua
    -- modData tag was only partially written. Reanimation explicitly clears
    -- this variable before releasing a corpse-created zombie to vanilla.
    if zombie.getVariableBoolean
        and (zombie:getVariableBoolean("PNCLive") == true
            or zombie:getVariableBoolean("PNCActor") == true)
    then
        return true
    end

    -- A native network packet can update an IsoZombie before the presence
    -- presentation writes its modData/variables. The roster-side index is
    -- client-only, O(1), and contains only live NPC body online identities.
    if PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.managedBodyOnlineIDsReady == true
        and zombie.getOnlineID
        and Core.IsClientOnly()
    then
        onlineID = tonumber(zombie:getOnlineID())
        clientBodyIDs = PNC.Network.ClientState.managedBodyOnlineIDs
        if onlineID ~= nil and clientBodyIDs
            and clientBodyIDs[tostring(onlineID)] == true
        then
            return true
        end
    end
    return false
end

-- Live IsoZombie instances use their ItemVisual script definitions when the
-- engine evaluates helmetFall().  The script Item is shared, so keep the
-- original ChanceToFall values and restore them at the end of the tick after
-- the managed NPC update has passed through the engine fall logic.
Core._VisualFallProtection = Core._VisualFallProtection or {}

function Core.ProtectClothingFromFall(item)
    if not item or not item.setChanceToFall then
        return false
    end
    return pcall(item.setChanceToFall, item, 0)
end

function Core.ProtectVisualClothingFromFall(zombie)
    local itemVisuals
    local visual
    local scriptItem
    local fullType
    local chanceToFall
    local state
    local i
    if not zombie or not zombie.getItemVisuals then
        return 0
    end
    itemVisuals = zombie:getItemVisuals()
    if not itemVisuals or not itemVisuals.size then
        return 0
    end
    for i = 0, itemVisuals:size() - 1 do
        visual = itemVisuals:get(i)
        scriptItem = visual and visual.getScriptItem
            and visual:getScriptItem() or nil
        fullType = visual and visual.getItemType
            and tostring(visual:getItemType() or "") or ""
        chanceToFall = scriptItem and scriptItem.getChanceToFall
            and tonumber(scriptItem:getChanceToFall()) or 0
        if scriptItem and fullType ~= "" and chanceToFall > 0
            and scriptItem.DoParam
        then
            state = Core._VisualFallProtection[fullType]
            if not state then
                state = { item = scriptItem, chanceToFall = chanceToFall }
                Core._VisualFallProtection[fullType] = state
            end
            pcall(scriptItem.DoParam, scriptItem, "ChanceToFall", "0")
        end
    end
    return Core.TableSize(Core._VisualFallProtection)
end

function Core.RestoreVisualClothingFallProtection()
    local fullType
    local state
    for fullType, state in pairs(Core._VisualFallProtection) do
        if state.item and state.item.DoParam then
            pcall(
                state.item.DoParam,
                state.item,
                "ChanceToFall",
                tostring(state.chanceToFall)
            )
        end
        Core._VisualFallProtection[fullType] = nil
    end
end

function Core.Now()
    return nowMillis()
end

function Core.Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function Core.Round(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function Core.DistanceSq(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return (dx * dx) + (dy * dy)
end

function Core.Distance(x1, y1, x2, y2)
    return math.sqrt(Core.DistanceSq(x1, y1, x2, y2))
end

function Core.TableSize(tbl)
    local count = 0
    if type(tbl) ~= "table" then
        return 0
    end
    for _, _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function Core.ShallowCopy(tbl)
    local copy = {}
    if type(tbl) ~= "table" then
        return copy
    end
    for key, value in pairs(tbl) do
        copy[key] = value
    end
    return copy
end

function Core.DeepCopy(tbl)
    local copy = {}
    local key
    local value
    if type(tbl) ~= "table" then
        return tbl
    end
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            copy[key] = Core.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function Core.GenerateID(prefix)
    local id = tostring(prefix or "pnc")
        .. "_"
        .. tostring(nowMillis())
        .. "_"
        .. tostring(ZombRand(1000000))
    return id
end

function Core.ResolvePlayerByOnlineID(onlineID)
    local players
    local i
    local player
    if onlineID == nil then
        return nil
    end
    if PNC.SpatialIndex and PNC.SpatialIndex.FindPlayerByOnlineID then
        player = PNC.SpatialIndex.FindPlayerByOnlineID(onlineID)
        if player then return player end
    end
    if isServer and isServer() and getOnlinePlayers then
        players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                player = players:get(i)
                if player and player:getOnlineID() == onlineID then
                    return player
                end
            end
        end
    end
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            player = getSpecificPlayer(i)
            if player and player:getOnlineID() == onlineID then
                return player
            end
        end
    end
    return nil
end

function Core.ResolvePlayerByUsername(username)
    local players
    local i
    local player
    if not username then
        return nil
    end
    if PNC.SpatialIndex and PNC.SpatialIndex.FindPlayerByUsername then
        player = PNC.SpatialIndex.FindPlayerByUsername(username)
        if player then return player end
    end
    if isServer and isServer() and getOnlinePlayers then
        players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                player = players:get(i)
                if player and player.getUsername and player:getUsername() == username then
                    return player
                end
            end
        end
    end
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            player = getSpecificPlayer(i)
            if player and player.getUsername and player:getUsername() == username then
                return player
            end
        end
    end
    return nil
end

function Core.ForEachPlayer(callback)
    local players
    local i
    local player
    if type(callback) ~= "function" then
        return
    end
    if isServer and isServer() and getOnlinePlayers then
        players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                player = players:get(i)
                if player then
                    callback(player)
                end
            end
            return
        end
    end
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            player = getSpecificPlayer(i)
            if player then
                callback(player)
            end
        end
    end
end

function Core.GetNearestPlayerPosition(x, y)
    local bestDistSq = math.huge
    local best = nil
    Core.ForEachPlayer(function(player)
        local distSq = Core.DistanceSq(x, y, player:getX(), player:getY())
        if distSq < bestDistSq then
            bestDistSq = distSq
            best = {
                player = player,
                x = player:getX(),
                y = player:getY(),
                z = player:getZ(),
                distSq = distSq,
            }
        end
    end)
    return best
end

function Core.Log(level, message)
    print("[PNC][" .. tostring(level or "INFO") .. "] " .. tostring(message or ""))
end

function Core.LogInfo(message)
    Core.Log("INFO", message)
end

function Core.LogWarn(message)
    Core.Log("WARN", message)
end

function Core.LogDebug(message)
    if PNC.Runtime and PNC.Runtime.debugEnabled then
        Core.Log("DEBUG", message)
    end
end

function Core.IsRecordDebugEnabled(record)
    -- Global debug controls global diagnostics and overlays. Record logs are
    -- intentionally opt-in so enabling the developer UI does not make every
    -- active NPC flood the same console stream.
    return record and record.runtime and record.runtime.debug == true or false
end

function Core.LogRecordDebug(record, message)
    if Core.IsRecordDebugEnabled(record) then
        Core.Log("DEBUG", message)
    end
end
