-- Grounded metadata (display name, enemy type, room, count) for ally warnings.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception, Internal = PNC.Perception, PNC.Perception.Internal
local Core = PNC.Core

local function cleanText(v)
    if v == nil then return nil end
    local s = tostring(v):gsub("^%s+", ""):gsub("%s+$", "")
    return s ~= "" and s or nil
end

local function roomInfoAt(obj, x, y, z, hintRoom)
    local sq = obj and obj.getCurrentSquare and obj:getCurrentSquare() or nil
    if not sq and type(getCell) == "function" then
        local cell = getCell()
        if cell and cell.getGridSquare then
            sq = cell:getGridSquare(math.floor(x), math.floor(y), math.floor(z))
        end
    end
    local room = sq and sq.getRoom and sq:getRoom() or nil
    local def = room and room.getRoomDef and room:getRoomDef() or nil
    local raw = cleanText(hintRoom)
        or cleanText((def and def.getName and def:getName()) or (room and room.getName and room:getName()))
    local lbl = raw
    if raw then
        local cs = PNC.Semantics and PNC.Semantics.CampSite
        if cs and cs.DisplayLabel then lbl = cs.DisplayLabel({ roomName = raw }) end
        if lbl == "room" or lbl == "other" or lbl == "unknown" then lbl = raw end
    end
    local indoors = (room ~= nil or lbl ~= nil) and true or (sq ~= nil and false or nil)
    return lbl, indoors
end

function Internal.ExtractThreatMeta(kind, spec, info, x, y, z)
    local obj, rec, res = info.object, info.record, info.resolved
    local dName, fName
    if kind == "npc" and rec then
        dName = cleanText(rec.name or rec.fullName)
        local fid = Internal.AllyWarningFactionIdOf and Internal.AllyWarningFactionIdOf(rec)
        local facs = PNC.Factions
        if fid and facs then
            local f = facs.GetFaction and facs.GetFaction(fid)
            fName = cleanText((facs.GetFactionName and facs.GetFactionName(fid))
                or (type(f) == "table" and f.name))
        end
    elseif kind == "player" then
        local pd = obj and obj.getDescriptor and obj:getDescriptor()
        dName = cleanText(spec.displayName)
            or cleanText(pd and pd.getForename and pd:getForename())
            or cleanText(info.username)
    elseif kind == "foreign_npc" then
        dName = cleanText(spec.displayName or (res and res.displayName) or spec.name or (res and res.name))
        if not dName and obj and obj.getDescriptor then
            local pd = obj:getDescriptor()
            dName = cleanText(pd and pd.getForename and pd:getForename())
        end
    end
    fName = fName or cleanText(spec.factionName or (res and res.factionName))
    local eType = "hostile"
    if info.semanticClass == "zombie" or kind == "zombie" then
        eType = "zombie"
    else
        local hint = string.lower(tostring(spec.provider or "") .. " "
            .. tostring(spec.threatClass or "") .. " "
            .. tostring(rec and (rec.factionID or rec.activeBehavior) or ""))
        if string.find(hint, "bandit", 1, true) then
            eType = "bandit"
        elseif string.find(hint, "raider", 1, true) or string.find(hint, "looter", 1, true) then
            eType = "raider"
        end
    end
    local rName, indoors = roomInfoAt(obj, x, y, z, spec.roomName or (res and res.roomName))
    local posture = nil
    if eType == "zombie" then
        local isCrawl = spec.isCrawler == true
            or (obj and obj.isCrawling and obj:isCrawling() == true)
            or (obj and obj.isProne and obj:isProne() == true)
        local isSprint = spec.isSprinter == true
            or (obj and obj.getSpeedType and tonumber(obj:getSpeedType()) == 1)
        posture = isCrawl and "crawler" or (isSprint and "sprinter" or nil)
    end
    return {
        displayName = dName,
        enemyType = eType,
        enemyPosture = posture,
        factionName = fName,
        roomName = rName,
        isIndoors = indoors,
        enemyCount = math.max(1, math.floor(tonumber(spec.enemyCount or spec.count) or 1)),
    }
end

local function distSq(x1, y1, x2, y2)
    if Core and Core.DistanceSq then return Core.DistanceSq(x1, y1, x2, y2) end
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

function Internal.EstimateThreatCount(caller, desc, raw)
    local base = math.max(1, math.floor(tonumber(desc.enemyCount) or 1))
    if base > 1 then return base end
    local c, dx, dy, dz = 0, desc.x, desc.y, desc.z
    if desc.kind == "zombie" then
        local entries = caller.runtime and caller.runtime.perceptionFrame
            and caller.runtime.perceptionFrame.entries
        if type(entries) == "table" then
            for i = 1, #entries do
                local zb = entries[i].zombie
                if zb and (not zb.isDead or not zb:isDead()) and zb.getX and zb.getY then
                    if distSq(dx, dy, zb:getX(), zb:getY()) <= 64 then
                        c = c + 1
                        if c >= 10 then break end
                    end
                end
            end
        end
        return math.max(1, c)
    end
    local rels = PNC.Relationships
    if rels and rels.AreNPCsEnemies and type(raw) == "table" then
        local callerId = caller and caller.id ~= nil and tostring(caller.id) or ""
        local callerFac = caller and caller.factionID or nil
        for i = 1, #raw do
            local r = raw[i]
            if type(r) == "table" and r ~= caller and r.alive ~= false
                and (callerId == "" or tostring(r.id or "") ~= callerId)
                and (callerFac == nil or r.factionID ~= callerFac)
                and math.abs((tonumber(r.z) or 0) - dz) < 1
                and distSq(dx, dy, r.x or 0, r.y or 0) <= 64
                and rels.AreNPCsEnemies(caller, r, { ignoreAttackNPCPolicy = true })
            then
                c = c + 1
                if c >= 10 then break end
            end
        end
    end
    return math.max(1, c)
end

function Internal.FastTargetKey(t)
    local k = type(t) == "table" and tostring(t.kind or "") or ""
    if k == "zombie" and t.zombieId ~= nil then return "zombie:" .. tostring(t.zombieId)
    elseif k == "npc" and t.id ~= nil then return "npc:" .. tostring(t.id)
    elseif k == "player" then
        if t.onlineID ~= nil then return "player:" .. tostring(t.onlineID) end
        if t.username ~= nil and t.username ~= "" then return "player:" .. tostring(t.username) end
    elseif k == "foreign_npc" and t.provider ~= nil and (t.actorId or t.id) ~= nil then
        return "foreign_npc:" .. tostring(t.provider) .. ":" .. tostring(t.actorId or t.id)
    end
    return nil
end

return Perception
