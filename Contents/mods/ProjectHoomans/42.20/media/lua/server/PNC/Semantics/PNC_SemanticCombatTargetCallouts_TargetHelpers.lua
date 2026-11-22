-- Target position, event ID, and player assault taunt helpers for combat target callouts.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local function finite(v) return S.Finite(v) end

function I.TargetPoint(target, wr)
    if type(target) ~= "table" then return nil end
    local x, y, z = finite(target.x), finite(target.y), finite(target.z)
    if x and y then return x, y, z or 0, "combat_target" end
    local id = tostring(target.id or target.zombieId or target.actorId or "")
    local reg = PNC and PNC.Registry
    local rec = id ~= "" and reg and type(reg.Get) == "function" and reg.Get(id) or nil
    if type(rec) == "table" then
        x, y, z = finite(rec.x), finite(rec.y), finite(rec.z)
        if x and y then return x, y, z or 0, "target_record" end
    end
    local desc = type(wr) == "table" and wr.descriptor or nil
    if type(desc) == "table" and finite(desc.x) and finite(desc.y) then
        return finite(desc.x), finite(desc.y), finite(desc.z) or 0, "ally_warning_descriptor"
    end
    return nil
end

function I.TargetEventID(ev, rec, t)
    return table.concat({
        "combat-target-acquired", tostring(rec and rec.id or ""),
        tostring(t and (t.id or t.zombieId or t.actorId or t.onlineID) or ""),
        tostring(math.floor(finite(ev and ev.at) or 0)),
    }, ":")
end

function I.TryEmitHostilePlayerTaunt(record, target, kind, core, now)
    local hostileClass = PNC and PNC.Const and PNC.Const.TACTICAL_CLASS_HOSTILE or "hostile"
    local assaultReactions = kind == "player"
        and record.tacticalClass == hostileClass
        and PNC and PNC.Semantics and PNC.Semantics.PlayerAssaultReactions or nil
    if not (assaultReactions and type(assaultReactions.OnHostileAcquiredPlayer) == "function") then
        return false
    end
    local hostilePlayer = target.player
        or (core and type(core.ResolvePlayerByOnlineID) == "function"
            and core.ResolvePlayerByOnlineID(target.onlineID or target.id))
        or (core and type(core.ResolvePlayerByUsername) == "function"
            and core.ResolvePlayerByUsername(target.username))
        or (target.playerIndex ~= nil and type(getSpecificPlayer) == "function"
            and getSpecificPlayer(target.playerIndex))
        or nil
    if not hostilePlayer then return false end
    local okTaunt, emittedTaunt = pcall(
        assaultReactions.OnHostileAcquiredPlayer,
        record,
        hostilePlayer,
        { now = now }
    )
    return okTaunt == true and emittedTaunt == true
end

return S
