local Registry = PNC.Registry

function Registry.RefreshLivePositions(markDirty)
    local zombie
    local record
    local id
    for id, zombie in pairs(Registry.LiveByID) do
        record = Registry.Data[id]
        if record and zombie then
            Registry.RefreshLivePosition(record, zombie, markDirty)
        end
    end
end

function Registry.RefreshLivePosition(record, zombie, markDirty)
    local x
    local y
    local z
    local onlineID
    if not record or not zombie then return false end
    if zombie.isDead and zombie:isDead() then
        Registry.LiveByID[record.id] = nil
        return false
    end
    x = zombie:getX()
    y = zombie:getY()
    z = zombie:getZ()
    if record.x ~= x or record.y ~= y or record.z ~= z then
        record.x = x
        record.y = y
        record.z = z
        if markDirty == true then
            Registry.MarkDirty(record, "position")
        end
        if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
            PNC.SpatialIndex.UpdateNPC(record)
        end
    end
    if zombie.getOnlineID then
        onlineID = tonumber(zombie:getOnlineID())
        if onlineID and onlineID >= 0
            and record.liveBodyOnlineID ~= onlineID
        then
            record.liveBodyOnlineID = onlineID
            if isServer and isServer() then
                record.runtime = record.runtime or {}
                record.runtime.forceSyncEvent = "body_online_id"
            end
        end
    end
    return true
end

local function onInitGlobalModData()
    Registry.Load()
end

Events.OnInitGlobalModData.Add(onInitGlobalModData)
