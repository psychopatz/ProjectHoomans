-- Attack permission and damage delivery for the Project A-Life adapter.
--
-- Owns the two directions of the cross-provider combat contract:
--   Hoomans -> A-Life : CanHoomansAttack + applyDamage
--   A-Life  -> Hoomans: CanProjectALifeAttack (consumed by the runtime bridges)
-- Stances live in PNC_ProjectALife_Policy; identity lives in _Internal.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeAdapter =
    PNC.Compatibility.ProjectALifeAdapter or {}

local Adapter = PNC.Compatibility.ProjectALifeAdapter
local Internal = Adapter.Internal
local Policy = PNC.Compatibility.ProjectALifePolicy

-- A-Life's own authoritative answer to "is this actor at war with that player?".
-- Managed actors follow their owner, so this -- not a faction table -- is the
-- signal that lets them answer an actor which has turned on the player while
-- leaving a neutral patrol alone.
local function projectALifeHostileToOwner(actorRecord, record)
    local relations = ProjectALife and ProjectALife.Relations
    if relations == nil or type(actorRecord) ~= "table" then return false end
    local player = Internal.OwnerPlayer(record)
    if player == nil then return false end
    if type(relations.hostileToPlayer) == "function" then
        local ok, hostile = pcall(
            relations.hostileToPlayer, actorRecord, player)
        if ok and hostile == true then return true end
    end
    return false
end

function Adapter.RecordConflict(sourceProvider, sourceFaction,
        targetProvider, targetFaction, context)
    return Policy.RecordConflict(
        sourceProvider,
        sourceFaction,
        targetProvider,
        targetFaction,
        context
    )
end

function Adapter.CanHoomansAttack(context)
    context = type(context) == "table" and context or {}
    local attacker = context.attacker
    local target = context.target or {}
    local actorId = target.actorId or target.id

    -- Self defence always wins: this A-Life actor already hurt this Hoomans NPC.
    if context.target and context.target.immediateSelfDefense
        or Internal.RecentThreat(attacker, actorId)
    then
        return true, "self_defense", "hostile"
    end

    -- Owner defence: the A-Life actor is at war with this NPC's owner player.
    if projectALifeHostileToOwner(Internal.TargetActorRecord(target), attacker) then
        return true, "owner_defense", "hostile"
    end

    -- Everything else has to be an explicit stance for the directed pair. The
    -- default is neutral, and a neutral A-Life patrol is never a valid target.
    local stance, reason = Policy.Resolve(
        "ProjectHoomans", Internal.FactionID(attacker),
        "ProjectALifeNPCs", Internal.TargetFactionID(target),
        { targetBody = target.worldObject }
    )
    if stance == "hostile" or stance == "careful" then
        return true, reason, stance
    end
    return false, reason or "not_hostile", stance
end

-- Direction A-Life -> Hoomans. The body here is by definition a managed Hoomans
-- actor, so requiring it to be A-Life-owned rejected every call site and
-- silently disabled all A-Life damage onto managed NPCs.
function Adapter.CanProjectALifeAttack(actor, body, context)
    if not Internal.IsHoomansBody(body) then
        return false, "hoomans_body_required"
    end
    if type(actor) ~= "table" then return false, "alife_actor_required" end
    context = type(context) == "table" and context or {}

    if projectALifeHostileToOwner(actor, Internal.HoomansRecord(body)) then
        return true, "owner_hostility", "hostile"
    end

    local stance, reason = Policy.Resolve(
        "ProjectALifeNPCs", actor.factionId,
        "ProjectHoomans", Internal.BodyFactionID(body),
        { targetBody = body, actor = actor, phase = context.phase }
    )
    if stance == "hostile" or stance == "careful" then
        return true, reason, stance
    end
    return false, reason or "not_hostile", stance
end

function Adapter.applyDamage(context)
    context = type(context) == "table" and context or {}
    local target = context.target or {}
    local details = context.context or {}
    local body = target.worldObject
    local hit = details.hit or {}
    local attackerBody = details.attackerBody
    local weapon = hit.weaponItem or details.weaponItem
    local alife = ProjectALife
    local humanDamage = alife and alife.HumanDamage
    if not body or not attackerBody
        or not humanDamage or type(humanDamage.apply) ~= "function"
    then
        return false, "alife_damage_unavailable"
    end
    local allowed = Adapter.CanHoomansAttack({
        attacker = details.attackerRecord,
        target = target,
        context = details,
    })
    if allowed ~= true then return false, "foreign_target_not_allowed" end
    -- A missing weapon is A-Life's own unarmed melee case; HumanDamage.points
    -- and Combat.isRanged both tolerate nil, so bare-handed Hoomans can still
    -- land A-Life damage instead of being silently rejected here.
    local ok, applied = pcall(
        humanDamage.apply, attackerBody, body, weapon, 1)
    if ok and applied == true then
        local targetFaction = Internal.TargetFactionID(target)
        Policy.RecordConflict(
            "ProjectHoomans",
            Internal.FactionID(details.attackerRecord),
            "ProjectALifeNPCs",
            targetFaction,
            {
                reason = "hoomans_confirmed_damage",
                direction = "outgoing",
                x = target.x,
                y = target.y,
                z = target.z,
                factionName = targetFaction,
                damage = hit.amount,
            }
        )
    end
    return ok and applied == true, ok and "applied" or "alife_damage_failed"
end

return Adapter
