PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

local Provider = {
    id = "revive",
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then
        return fallback
    end
    return value
end

local function snapshotFor(entry)
    return entry and (entry.snapshot
        or (ClientState.snapshots and ClientState.snapshots[entry.id])) or nil
end

function Provider.isEnabled(entry)
    local snapshot = snapshotFor(entry)
    local record = entry and entry.record or nil
    return snapshot and snapshot.healthState == "incapacitated" and snapshot.canRevive == true
        or record and record.health and PNC.Health and PNC.Health.CanRevive and PNC.Health.CanRevive(record)
end

function Provider.addOptions(menu, entry, player)
    local count = PNC.Revive and PNC.Revive.CountBandages and PNC.Revive.CountBandages(player) or 0
    local dx = (tonumber(entry and entry.x) or 0) - (tonumber(player and player:getX()) or 0)
    local dy = (tonumber(entry and entry.y) or 0) - (tonumber(player and player:getY()) or 0)
    local sameLevel = math.abs((tonumber(entry and entry.z) or 0) - (tonumber(player and player:getZ()) or 0)) < 1
    local inRange = sameLevel and ((dx * dx) + (dy * dy)) <= (Const.REVIVE_RANGE * Const.REVIVE_RANGE)
    local label = tr("UI_PNC_Revive", "Revive")
        .. " (" .. tostring(Const.REVIVE_BANDAGE_COUNT) .. " "
        .. tr("UI_PNC_Bandages", "Bandages") .. ")"
    local option = menu:addOption(label, nil, function()
        if PNC.Client and PNC.Client.SendRevive then
            PNC.Client.SendRevive(entry.id)
        end
    end)
    if count < Const.REVIVE_BANDAGE_COUNT or not inRange then
        option.notAvailable = true
    end
end

ContextHub.RegisterProvider(Provider)
