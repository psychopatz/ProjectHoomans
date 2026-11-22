-- Agnostic threat target normalization and per-ally engagement legitimacy.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception, Internal = PNC.Perception, PNC.Perception.Internal
local Core, Const = PNC.Core, PNC.Const or {}
local Registry, Relationships = PNC.Registry, PNC.Relationships
if not Internal.ExtractThreatMeta then require "PNC/Core/Perception/PNC_Perception/AllyThreatMeta" end

local function resolveTargetWorld(kind, spec)
    local coord, bodyAlive = Internal.AllyWarningCoord, Internal.AllyWarningBodyAlive
    if kind == "zombie" then
        if spec.zombieId == nil then return nil end
        local zb = spec.zombie or (Perception.FindZombieByID and Perception.FindZombieByID(spec.zombieId))
        if zb and not bodyAlive(zb) then return nil end
        return { object = zb, semanticClass = "zombie", key = "zombie:" .. tostring(spec.zombieId) }
    elseif kind == "npc" then
        if spec.id == nil then return nil end
        local rec = Registry and Registry.Get and Registry.Get(spec.id) or nil
        if rec and rec.alive == false then return nil end
        local body = Registry and Registry.GetLiveZombie and Registry.GetLiveZombie(spec.id) or nil
        if body and not bodyAlive(body) then return nil end
        return { object = body, record = rec, semanticClass = "human_hostile", key = "npc:" .. tostring(spec.id) }
    elseif kind == "player" then
        local p = spec.player
            or (Core and Core.ResolvePlayerByOnlineID and spec.onlineID ~= nil and Core.ResolvePlayerByOnlineID(spec.onlineID))
            or (Core and Core.ResolvePlayerByUsername and spec.username ~= nil and Core.ResolvePlayerByUsername(spec.username))
        if p and p.isAlive and not p:isAlive() then return nil end
        local oid = spec.onlineID ~= nil and spec.onlineID or (p and p.getOnlineID and p:getOnlineID() or nil)
        local uname = spec.username or (p and p.getUsername and p:getUsername() or nil)
        local ident = oid ~= nil and tostring(oid) or tostring(uname or "")
        if ident == "" then return nil end
        return { object = p, onlineID = oid, username = uname, semanticClass = "human_hostile", key = "player:" .. ident }
    elseif kind == "foreign_npc" then
        local aid = spec.actorId or spec.id
        if spec.provider == nil or aid == nil then return nil end
        local api = PNC.Compatibility and PNC.Compatibility.API or nil
        local res = spec.worldObject and spec or (api and api.ResolveTarget and api.ResolveTarget(spec)) or nil
        local fb = res and res.worldObject or nil
        if fb and not bodyAlive(fb) then return nil end
        local cls = tostring(spec.threatClass or (res and res.threatClass) or "human_hostile")
        return {
            object = fb, resolved = res,
            semanticClass = cls == "zombie" and "zombie" or "human_hostile",
            key = "foreign_npc:" .. tostring(spec.provider) .. ":" .. tostring(aid),
        }
    end
    return nil
end

function Perception.NormalizeThreatDescriptor(target, at)
    if type(target) ~= "table" or target.kind == nil then return nil end
    local kind, coord = tostring(target.kind), Internal.AllyWarningCoord
    local info = resolveTargetWorld(kind, target)
    if not info then return nil end
    local x = info.object and coord(info.object, "getX", target.x) or (info.record and tonumber(info.record.x)) or tonumber(target.x)
    local y = info.object and coord(info.object, "getY", target.y) or (info.record and tonumber(info.record.y)) or tonumber(target.y)
    local z = tonumber(info.object and coord(info.object, "getZ", target.z) or (info.record and tonumber(info.record.z)) or tonumber(target.z)) or 0
    if x == nil or y == nil or (not info.object and not info.record and target.x == nil) then return nil end
    local now = at ~= nil and (tonumber(at) or 0) or (Core and Core.Now and tonumber(Core.Now()) or 0)
    local m = Internal.ExtractThreatMeta and Internal.ExtractThreatMeta(kind, target, info, x, y, z) or {}
    return {
        kind = kind, key = info.key, id = target.id, zombieId = target.zombieId,
        onlineID = info.onlineID ~= nil and info.onlineID or target.onlineID,
        username = info.username or target.username, provider = target.provider,
        actorId = target.actorId or target.id, generation = target.generation,
        x = x, y = y, z = z, semanticClass = info.semanticClass, observedAt = now,
        displayName = m.displayName, enemyType = m.enemyType, factionName = m.factionName,
        roomName = m.roomName, isIndoors = m.isIndoors, enemyCount = m.enemyCount or 1,
    }
end

function Perception.CanAllyEngageThreat(ally, descriptor)
    if type(ally) ~= "table" or ally.alive == false or type(descriptor) ~= "table" then
        return false, nil, "invalid_context"
    end
    local kind = tostring(descriptor.kind or "")
    local info = resolveTargetWorld(kind, descriptor)
    if not info or not info.object then return false, nil, "target_unavailable" end
    if kind == "zombie" and Perception.IsActualZombieBody and not Perception.IsActualZombieBody(info.object) then
        return false, nil, "not_actual_zombie"
    end
    if tostring(ally.attackType or Const.ATTACK_TYPE_AUTO or "auto") == tostring(Const.ATTACK_TYPE_NONE or "none") then
        return false, info.object, "passive_attack_none"
    end
    if kind == "zombie" then return true, info.object, "zombie_valid"
    elseif kind == "npc" then
        local tr = info.record
        if not tr or tostring(ally.id or "") == tostring(tr.id or "") then return false, nil, "cannot_target_self" end
        local enemy = Relationships and Relationships.AreNPCsEnemies and Relationships.AreNPCsEnemies(ally, tr, { ignoreAttackNPCPolicy = false })
        if not enemy and (not ally.hostility or ally.hostility.attackNPCs ~= false) and Relationships and Relationships.AreNPCsEnemies then
            local tt = tr.runtime and tr.runtime.target or nil
            if type(tt) == "table" and tt.kind == "npc"
                and (tostring(tt.id or "") == tostring(descriptor.callerId or "") or tostring(tt.id or "") == tostring(ally.id or ""))
            then
                enemy = Relationships.AreNPCsEnemies(ally, tr, { ignoreAttackNPCPolicy = true })
            end
        end
        return enemy == true, info.object, enemy and "npc_enemy_valid" or "not_enemy"
    elseif kind == "player" then
        local ownerField, factionOf = Internal.AllyWarningOwnerField, Internal.AllyWarningFactionIdOf
        local owned = (descriptor.onlineID ~= nil and tostring(ownerField(ally, "ownerOnlineID") or "") == tostring(descriptor.onlineID))
            or (descriptor.username ~= nil and descriptor.username ~= "" and tostring(ownerField(ally, "ownerUsername") or "") == tostring(descriptor.username))
        if owned then return false, info.object, "cannot_attack_owner" end
        local ok = PNC.Factions and PNC.Factions.CanNPCTargetPlayer and PNC.Factions.CanNPCTargetPlayer(ally, info.object) == true
        if not ok and factionOf(ally) == nil then
            ok = Internal.AllyWarningIsHostile(ally) or (ally.hostility and ally.hostility.attackPlayers == true)
        end
        return ok == true, info.object, ok and "player_enemy_valid" or "player_not_enemy"
    elseif kind == "foreign_npc" then
        local api = PNC.Compatibility and PNC.Compatibility.API or nil
        if not api or not info.resolved then return false, nil, "foreign_unavailable" end
        local ok, reason = api.CanAttack(ally, info.resolved, { source = ally })
        if not ok then return false, info.object, tostring(reason or "foreign_cannot_attack") end
        return true, info.resolved, "foreign_valid"
    end
    return false, nil, "unsupported_target_kind"
end

return Perception
