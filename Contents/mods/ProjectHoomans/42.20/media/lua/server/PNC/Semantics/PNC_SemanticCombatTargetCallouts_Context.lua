if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

local function tr(key, fallback)
    local t = PNC.Translation
    local v = t and type(t.GetKey) == "function" and t.GetKey(key, fallback)
        or (type(getTextOrNull) == "function" and getTextOrNull(key) or nil)
    return (type(v) == "string" and v ~= "") and v or fallback
end

local function fmtKey(k, fb, ...) return string.format(tr(k, fb), ...) end

local function cleanText(v)
    if v == nil then return nil end
    local s = tostring(v):gsub("^%s+", ""):gsub("%s+$", "")
    return s ~= "" and s or nil
end

function S.FirstTokenName(raw)
    local s = type(raw) == "string" and cleanText(raw) or nil
    return s and (string.match(s, "^(%S+)") or s) or nil
end

local KIND_KEYS = {
    zombie = { "UI_PNC_AllyWarn_Type_Zombie", "walker", "walkers" },
    crawler = { "UI_PNC_AllyWarn_Type_Crawler", "crawler", "crawlers" },
    sprinter = { "UI_PNC_AllyWarn_Type_Sprinter", "runner", "runners" },
    bandit = { "UI_PNC_AllyWarn_Type_Bandit", "bandit", "bandits" },
    raider = { "UI_PNC_AllyWarn_Type_Raider", "raider", "raiders" },
    hostile = { "UI_PNC_AllyWarn_Type_Hostile", "hostile", "hostiles" },
}

local function kindLabel(et, pl, pos)
    local key = (tostring(et or "hostile") == "zombie" and (pos == "crawler" or pos == "sprinter")) and pos or tostring(et or "hostile")
    local sp = KIND_KEYS[key] or KIND_KEYS.hostile
    return tr(sp[1] .. (pl and "_Pl" or "_Sg"), sp[pl and 3 or 2])
end

local function isSpeakerIndoors(sp)
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell or not cell.getGridSquare then return false end
    local sq = cell:getGridSquare(math.floor(tonumber(sp and sp.x) or 0), math.floor(tonumber(sp and sp.y) or 0), math.floor(tonumber(sp and sp.z) or 0))
    return sq ~= nil and sq.getRoom and sq:getRoom() ~= nil
end

local function resolveLocationLabel(speaker, desc, now, tone, preSp)
    local sx, sy, sz = tonumber(speaker and speaker.x) or tonumber(desc.x) or 0, tonumber(speaker and speaker.y) or tonumber(desc.y) or 0, tonumber(speaker and speaker.z) or 0
    local tx, ty, tz = tonumber(desc.x) or sx, tonumber(desc.y) or sy, tonumber(desc.z) or sz
    if tz - sz >= 1 then return tr("UI_PNC_AllyWarn_Loc_Upstairs", "upstairs") end
    if tz - sz <= -1 then return tr("UI_PNC_AllyWarn_Loc_Downstairs", "downstairs") end
    local rm = cleanText(desc.roomName)
    if rm and string.lower(rm) ~= "room" then return fmtKey("UI_PNC_AllyWarn_Loc_InRoom", "in the %s", rm) end
    local dx, dy = tx - sx, ty - sy
    if (dx * dx + dy * dy) <= 2.25 then return tr("UI_PNC_AllyWarn_Loc_RightHere", "right on us") end
    local proj, relMod, bearing, sp = PNC.TacticalSpatialProjection, PsychopatzCore and PsychopatzCore.SpatialRelation or nil, nil, preSp
    if not sp and proj and type(proj.Project) == "function" and relMod then
        sp = proj.Project(speaker, {
            kind = desc.semanticClass or "human_hostile", id = desc.id or desc.zombieId or desc.actorId or "threat",
            x = tx, y = ty, z = tz, observedAt = now,
        }, { now = now, sameAreaThreshold = 0.5, maxThreatAgeMs = 4000, allowCachedFacing = true, maxCachedFacingAgeMs = 5000 })
    end
    if sp and relMod then
        if tone == "tactical" and sp.clockToken and relMod.GetClockLabel then
            bearing = fmtKey("UI_PNC_AllyWarn_Loc_AtClock", "at %s", relMod.GetClockLabel(sp.clockToken))
        elseif sp.relativeSector8 and relMod.GetRelativeSectorLabel then
            bearing = relMod.GetRelativeSectorLabel(sp.relativeSector8)
        end
    end
    if not bearing and relMod and relMod.Between then
        local rel = relMod.Between({ x = sx, y = sy, z = sz }, { x = tx, y = ty, z = tz })
        if rel and rel.direction8 and rel.direction8 ~= "SAME_AREA" and relMod.GetDirectionLabel then
            bearing = fmtKey("UI_PNC_AllyWarn_Loc_ToDirection", "to the %s", relMod.GetDirectionLabel(rel.direction8))
        end
    end
    if bearing then
        if desc.isIndoors == false and isSpeakerIndoors(speaker) then return fmtKey("UI_PNC_AllyWarn_Loc_OutsideDir", "outside, %s", bearing) end
        return bearing
    end
    return tr("UI_PNC_AllyWarn_Loc_Nearby", "nearby")
end

function S.ResolveAllyWarnTone(record, profile)
    local b = tostring(record and (record.activeBehavior or record.behavior) or "")
    if b == "hostile" or (record and record.isHostile == true) or tostring(profile and profile.combatTone or "") == "aggressive" then return "hostile" end
    local pol, at = tostring(record and record.combatPolicy or ""), tostring(record and record.attackType or "")
    if (profile and profile.nervous == true) or pol == "passive" or at == "none" then return "shaken" end
    local bc, prof = PNC.Semantics and PNC.Semantics.BeatContext or nil, PNC.Semantics and PNC.Semantics.CombatReactionProfile or nil
    if bc and type(bc.Build) == "function" and type(record) == "table" then
        local ctx = bc.Build(record, nil, { inCombat = true })
        local st = ctx and ctx.actor and ctx.actor.style or nil
        if st and st ~= "neutral" then return st end
    elseif prof and type(prof.Build) == "function" and type(record) == "table" then
        local pr = prof.Build(record, "", { role = "witness", actorKind = "npc", inCombat = true })
        if pr and pr.allyWarnStyle and pr.allyWarnStyle ~= "neutral" then return pr.allyWarnStyle end
    end
    local role = tostring(record and (record.tacticalRole or record.role) or "")
    if (profile and profile.tactical == true) or (record and record.tactical == true) or role == "guard" or role == "soldier" or role == "scout" then return "tactical" end
    return "neutral"
end

function S.BuildRichSpeechTokens(speaker, caller, desc, now, tone, opts)
    desc = type(desc) == "table" and desc or {}
    opts = type(opts) == "table" and opts or nil
    local count = math.max(1, math.floor(tonumber(desc.enemyCount) or 1))
    local pos, et = desc.enemyPosture, tostring(desc.enemyType or "hostile")
    local kSg, kPl = kindLabel(et, false, pos), kindLabel(et, true, pos)
    local cRaw = (caller and (caller.name or caller.fullName)) or desc.callerName
    local cName = S.FirstTokenName(cRaw) or tr("UI_PNC_AllyWarn_FallbackCaller", "friend")
    local dName, facName = S.FirstTokenName(desc.displayName) or cleanText(desc.displayName), cleanText(desc.factionName)
    local tLabel
    if dName then
        tLabel = count > 1 and fmtKey("UI_PNC_AllyWarn_NamedWithCrew", "%s and their crew", dName) or dName
    else
        local sg, pl = facName and (facName .. " " .. kSg) or kSg, facName and (facName .. " " .. kPl) or kPl
        if count >= 10 then tLabel = fmtKey("UI_PNC_AllyWarn_PackOf", "a pack of %s", pl)
        elseif count >= 6 then tLabel = fmtKey("UI_PNC_AllyWarn_GroupOf", "a group of %s", pl)
        elseif count >= 3 then tLabel = fmtKey("UI_PNC_AllyWarn_FewOf", "a few %s", pl)
        elseif count == 2 then
            tLabel = (not facName and et == "zombie" and pos == nil)
                and tr("UI_PNC_AllyWarn_CoupleStragglers", "a couple of stragglers")
                or fmtKey("UI_PNC_AllyWarn_CoupleOf", "a couple of %s", pl)
        else
            tLabel = fmtKey("UI_PNC_AllyWarn_SinglePrefix", "a %s", sg)
        end
    end
    local loc = ""
    if not (opts and opts.skipLocation == true) then loc = resolveLocationLabel(speaker, desc, now, tone, opts and opts.spatial or nil) end
    local aud = opts and opts.audience or nil
    local addresseeLabel = (aud and aud.label) or cName
    local tokens = {
        ["addressee.name"] = addresseeLabel,
        ["audience.label"] = addresseeLabel,
        ["audience.count"] = tostring(aud and aud.count or 1),
        ["audience.pronoun"] = (aud and aud.isPlural) and "you all" or "you",
        ["target.name"] = tLabel,
        ["target.count"] = tostring(count),
        ["target.kind"] = count > 1 and kPl or kSg,
        ["target.pronoun"] = count > 1 and "them" or "it",
        ["target.verb_be"] = count > 1 and "are" or "is",
        ["scene.location"] = loc,
    }
    if aud and aud.playerName then
        tokens["player.name"] = aud.playerName
    end
    return tokens
end

return S
