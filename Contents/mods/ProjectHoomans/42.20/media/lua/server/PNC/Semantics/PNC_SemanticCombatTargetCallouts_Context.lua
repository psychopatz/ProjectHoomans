if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

local function tr(key, fallback)
    local t = PNC.Translation
    if t and type(t.GetKey) == "function" then
        local v = t.GetKey(key, fallback)
        if type(v) == "string" and v ~= "" then return v end
    end
    if type(getTextOrNull) == "function" then
        local v = getTextOrNull(key)
        if type(v) == "string" and v ~= "" then return v end
    end
    return fallback
end

local function fmtKey(key, fallback, ...)
    return string.format(tr(key, fallback), ...)
end

local function firstTokenName(raw)
    if type(raw) ~= "string" then return nil end
    local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then return nil end
    return string.match(trimmed, "^(%S+)") or trimmed
end

local function cleanText(v)
    if v == nil then return nil end
    local s = tostring(v):gsub("^%s+", ""):gsub("%s+$", "")
    return s ~= "" and s or nil
end

local function kindLabel(enemyType, plural)
    local suffix = plural and "_Pl" or "_Sg"
    local et = tostring(enemyType or "hostile")
    if et == "zombie" then
        return tr("UI_PNC_AllyWarn_Type_Zombie" .. suffix, plural and "walkers" or "walker")
    elseif et == "bandit" then
        return tr("UI_PNC_AllyWarn_Type_Bandit" .. suffix, plural and "bandits" or "bandit")
    elseif et == "raider" then
        return tr("UI_PNC_AllyWarn_Type_Raider" .. suffix, plural and "raiders" or "raider")
    end
    return tr("UI_PNC_AllyWarn_Type_Hostile" .. suffix, plural and "hostiles" or "hostile")
end

local function isSpeakerIndoors(speaker)
    if type(getCell) ~= "function" then return false end
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return false end
    local sq = cell:getGridSquare(
        math.floor(tonumber(speaker and speaker.x) or 0),
        math.floor(tonumber(speaker and speaker.y) or 0),
        math.floor(tonumber(speaker and speaker.z) or 0)
    )
    return sq ~= nil and type(sq.getRoom) == "function" and sq:getRoom() ~= nil
end

local function resolveLocationLabel(speaker, desc, now, tone, preSpatial)
    local sx = tonumber(speaker and speaker.x) or tonumber(desc.x) or 0
    local sy = tonumber(speaker and speaker.y) or tonumber(desc.y) or 0
    local sz = tonumber(speaker and speaker.z) or 0
    local tx = tonumber(desc.x) or sx
    local ty = tonumber(desc.y) or sy
    local tz = tonumber(desc.z) or sz
    local dz = tz - sz
    if dz >= 1 then return tr("UI_PNC_AllyWarn_Loc_Upstairs", "upstairs") end
    if dz <= -1 then return tr("UI_PNC_AllyWarn_Loc_Downstairs", "downstairs") end

    local roomName = cleanText(desc.roomName)
    if roomName and string.lower(roomName) ~= "room" then
        return fmtKey("UI_PNC_AllyWarn_Loc_InRoom", "in the %s", roomName)
    end
    local dx, dy = tx - sx, ty - sy
    if (dx * dx + dy * dy) <= 2.25 then
        return tr("UI_PNC_AllyWarn_Loc_RightHere", "right on us")
    end

    local proj = PNC.TacticalSpatialProjection
    local relMod = PsychopatzCore and PsychopatzCore.SpatialRelation or nil
    local bearing = nil
    local spatial = preSpatial
    if not spatial and proj and type(proj.Project) == "function" and relMod then
        spatial = proj.Project(speaker, {
            kind = desc.semanticClass or "human_hostile",
            id = desc.id or desc.zombieId or desc.actorId or "threat",
            x = tx, y = ty, z = tz, observedAt = now,
        }, {
            now = now, sameAreaThreshold = 0.5, maxThreatAgeMs = 4000,
            allowCachedFacing = true, maxCachedFacingAgeMs = 5000,
        })
    end
    if spatial and relMod then
        if tone == "tactical" and spatial.clockToken and type(relMod.GetClockLabel) == "function" then
            bearing = fmtKey("UI_PNC_AllyWarn_Loc_AtClock", "at %s",
                relMod.GetClockLabel(spatial.clockToken))
        elseif spatial.relativeSector8 and type(relMod.GetRelativeSectorLabel) == "function" then
            bearing = relMod.GetRelativeSectorLabel(spatial.relativeSector8)
        end
    end
    if not bearing and relMod and type(relMod.Between) == "function" then
        local rel = relMod.Between({ x = sx, y = sy, z = sz }, { x = tx, y = ty, z = tz })
        if rel and rel.direction8 and rel.direction8 ~= "SAME_AREA"
            and type(relMod.GetDirectionLabel) == "function"
        then
            bearing = fmtKey("UI_PNC_AllyWarn_Loc_ToDirection", "to the %s",
                relMod.GetDirectionLabel(rel.direction8))
        end
    end
    if bearing then
        if desc.isIndoors == false and isSpeakerIndoors(speaker) then
            return fmtKey("UI_PNC_AllyWarn_Loc_OutsideDir", "outside, %s", bearing)
        end
        return bearing
    end
    return tr("UI_PNC_AllyWarn_Loc_Nearby", "nearby")
end

function Service.ResolveAllyWarnTone(record, profile)
    local b = tostring(record and (record.activeBehavior or record.behavior) or "")
    if b == "hostile" or (record and record.isHostile == true)
        or tostring(profile and profile.combatTone or "") == "aggressive"
    then return "hostile" end
    local role = tostring(record and (record.tacticalRole or record.role) or "")
    if (profile and profile.tactical == true) or (record and record.tactical == true)
        or role == "guard" or role == "soldier" or role == "scout"
    then return "tactical" end
    local policy = tostring(record and record.combatPolicy or "")
    local attackType = tostring(record and record.attackType or "")
    if (profile and profile.nervous == true) or policy == "passive" or attackType == "none" then
        return "shaken"
    end
    return "neutral"
end

function Service.BuildRichSpeechTokens(speakerRecord, callerRecord, desc, now, tone, opts)
    desc = type(desc) == "table" and desc or {}
    opts = type(opts) == "table" and opts or nil
    local count = math.max(1, math.floor(tonumber(desc.enemyCount) or 1))
    local kSg = kindLabel(desc.enemyType, false)
    local kPl = kindLabel(desc.enemyType, true)
    local callerRaw = (callerRecord and (callerRecord.name or callerRecord.fullName)) or desc.callerName
    local callerName = firstTokenName(callerRaw) or tr("UI_PNC_AllyWarn_FallbackCaller", "friend")
    local dName = firstTokenName(desc.displayName) or cleanText(desc.displayName)
    local facName = cleanText(desc.factionName)
    local targetLabel
    if dName then
        if count > 1 then
            targetLabel = fmtKey("UI_PNC_AllyWarn_NamedWithCrew", "%s and their crew", dName)
        else
            targetLabel = dName
        end
    elseif facName then
        if count == 1 then
            targetLabel = fmtKey("UI_PNC_AllyWarn_SinglePrefix", "a %s", facName .. " " .. kSg)
        else
            targetLabel = fmtKey("UI_PNC_AllyWarn_CountType", "%d %s", count, facName .. " " .. kPl)
        end
    elseif count >= 10 then
        targetLabel = fmtKey("UI_PNC_AllyWarn_PackOf", "a pack of %s", kPl)
    elseif count >= 2 then
        targetLabel = fmtKey("UI_PNC_AllyWarn_CountType", "%d %s", count, kPl)
    else
        targetLabel = fmtKey("UI_PNC_AllyWarn_SinglePrefix", "a %s", kSg)
    end
    local locLabel = ""
    if not (opts and opts.skipLocation == true) then
        locLabel = resolveLocationLabel(speakerRecord, desc, now, tone, opts and opts.spatial or nil)
    end
    return {
        ["addressee.name"] = callerName,
        ["target.name"] = targetLabel,
        ["target.count"] = tostring(count),
        ["target.kind"] = count > 1 and kPl or kSg,
        ["scene.location"] = locLabel,
    }
end

return Service
