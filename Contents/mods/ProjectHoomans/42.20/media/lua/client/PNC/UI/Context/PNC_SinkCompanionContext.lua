-- Sink-side companion command. Selection is client presentation only; source
-- validity, ownership, combat state, and approach geometry are rechecked by
-- the authoritative action handler.

PNC = PNC or {}
PNC.SinkCompanionContext = PNC.SinkCompanionContext or {}

local Context = PNC.SinkCompanionContext

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function listSize(list)
    return list and list.size and list:size() or 0
end

local function listItem(list, index)
    return list and list.get and list:get(index) or nil
end

local function isSink(object)
    local sprite = call(call(object, "getSprite"), "getName")
    local name = string.lower(tostring(sprite or call(object, "getName") or ""))
    return string.find(name, "sink", 1, true) ~= nil
        and (call(object, "isWaterSource") == true
            or call(object, "hasFluid") == true
            or call(object, "getFluidContainer") ~= nil
            or call(object, "getWaterAmount") ~= nil)
end

local function findSink(worldObjects)
    local seenSquares = {}
    for _, clicked in ipairs(worldObjects or {}) do
        if isSink(clicked) then return clicked, call(clicked, "getSquare") end
        local square = call(clicked, "getSquare")
        if square and not seenSquares[square] then
            seenSquares[square] = true
            local objects = call(square, "getObjects")
            for index = 0, listSize(objects) - 1 do
                local object = listItem(objects, index)
                if isSink(object) then return object, square end
            end
        end
    end
    return nil
end

local function companionName(record)
    if PNC.NPCIdentityPresentation
        and PNC.NPCIdentityPresentation.GetName
    then return PNC.NPCIdentityPresentation.GetName(record) end
    return tostring(record and (record.name or record.id) or "Companion")
end

local function commandableCompanions(player)
    local commands = PNC.CompanionCommands
    local snapshots = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots or {}
    local output = {}
    for id, snapshot in pairs(snapshots) do
        if snapshot and commands and commands.CanPlayerCommand
            and commands.CanPlayerCommand(snapshot, player) == true
        then
            output[#output + 1] = {
                id = tostring(snapshot.id or id),
                name = companionName(snapshot),
            }
        end
    end
    table.sort(output, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    return output
end

local function requestDrink(npcId, square)
    if not square or not PNC.Client or not PNC.Client.RequestColonyAction then
        return false
    end
    return PNC.Client.RequestColonyAction("npc_drink_at_water", {
        npcID = npcId,
        sourceX = square:getX(), sourceY = square:getY(),
        sourceZ = square:getZ(),
    })
end

function Context.BuildWorldContext(playerNum, menu, worldObjects, test)
    if test or not menu then return end
    local _, square = findSink(worldObjects)
    if not square then return end
    local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    if not player then return end
    local companions = commandableCompanions(player)
    local submenu = ISContextMenu:getNew(menu)
    local root = menu:addOption(tr(
        "UI_PNC_Sink_CommandDrink", "Send Companion to Drink"))
    menu:addSubMenu(root, submenu)
    if #companions == 0 then
        local unavailable = submenu:addOption(tr(
            "UI_PNC_Sink_NoCompanion", "No commandable companion nearby"))
        if unavailable then unavailable.notAvailable = true end
        return
    end
    for _, companion in ipairs(companions) do
        submenu:addOption(companion.name, companion.id, requestDrink, square)
    end
end

Context.FindSink = findSink
Context.CommandableCompanions = commandableCompanions

return Context
