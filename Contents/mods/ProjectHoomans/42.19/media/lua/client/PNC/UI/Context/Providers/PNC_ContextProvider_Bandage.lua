PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local ClientState = PNC.Network.ClientState
local Provider = { id = "bandage" }

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function snapshotFor(entry)
    return entry and (entry.snapshot
        or ClientState.snapshots and ClientState.snapshots[entry.id]) or nil
end

local function woundsFor(entry)
    local snapshot = snapshotFor(entry)
    local payload = entry and ClientState.characterPayloads and ClientState.characterPayloads[entry.id] or nil
    local body = snapshot and snapshot.bodyHealth
        or payload and payload.health and payload.health.body
        or entry and entry.record and entry.record.health and entry.record.health.body
    return body and body.wounds or {}
end

local function openWounds(entry)
    local output = {}
    local partId
    local wound
    local parts = PNC.NPCWounds and PNC.NPCWounds.Parts or {}
    for partId, wound in pairs(woundsFor(entry)) do
        if wound and wound.bandaged ~= true then
            output[#output + 1] = {
                partId = tostring(partId),
                wound = wound,
                label = parts[partId] and parts[partId].label or tostring(partId),
            }
        end
    end
    table.sort(output, function(left, right) return left.label < right.label end)
    return output
end

function Provider.isEnabled(entry)
    return #openWounds(entry) > 0
end

function Provider.addOptions(menu, entry, player)
    local wounds = openWounds(entry)
    local bandageCount = PNC.Treatment and PNC.Treatment.CountBandages
        and PNC.Treatment.CountBandages(player) or 0
    local dx = (tonumber(entry and entry.x) or 0) - (tonumber(player and player:getX()) or 0)
    local dy = (tonumber(entry and entry.y) or 0) - (tonumber(player and player:getY()) or 0)
    local sameLevel = math.abs((tonumber(entry and entry.z) or 0) - (tonumber(player and player:getZ()) or 0)) < 1
    local range = tonumber(PNC.Const.BANDAGE_RANGE) or 3
    local inRange = sameLevel and ((dx * dx) + (dy * dy)) <= (range * range)
    local i
    for i = 1, #wounds do
        local row = wounds[i]
        local typeLabel = tr("UI_PNC_Wound_" .. tostring(row.wound.type), tostring(row.wound.type or "Wound"))
        local option = menu:addOption(
            tr("UI_PNC_Bandage", "Bandage") .. " " .. row.label .. " (" .. typeLabel .. ")",
            nil,
            function()
                if PNC.Client and PNC.Client.SendBandage then
                    PNC.Client.SendBandage(entry.id, row.partId)
                end
            end
        )
        if bandageCount <= 0 or not inRange then option.notAvailable = true end
    end
end

ContextHub.RegisterProvider(Provider)

return Provider
