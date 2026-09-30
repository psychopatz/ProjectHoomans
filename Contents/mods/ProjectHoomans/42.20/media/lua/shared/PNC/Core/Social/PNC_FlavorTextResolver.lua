--[[
    PNC Flavor Text Resolver
    Pure, deterministic mapping from "downed NPC context" to a bounded set of
    flavor variant keys.  It owns no state, performs no world scans, and never
    touches the presentation queue, so it is safe to share between client and
    server and cheap enough to call on every state transition.

    The resolver answers three questions in a fixed precedence order:

        1. WHO put this NPC down?      -> threat: zombie, npc, player,
                                          foreign_npc, unknown
        2. WHAT is our standing with
           the listener/observer?      -> audience: self, ally, friendly,
                                          neutral, stranger, hostile
        3. WHAT does the NPC need?     -> need: bandage, bleedout, rescue,
                                          mercy, help, faint, none

    Faction standing (same faction, allied, at war) is the primary audience
    signal; the per-NPC relationship state/tier refines it.  Variant keys are
    composed as "<audience>__<need>" so definitions can either target the
    exact combination or fall back to the audience-only key.
]]

require "PNC/Core/Social/PNC_FlavorTextResolver_Constants"

PNC = PNC or {}
PNC.FlavorText = PNC.FlavorText or {}

local FlavorText = PNC.FlavorText
local Const = PNC.FlavorTextConst

local function clean(value, fallback)
    if value == nil then return fallback end
    return tostring(value) ~= "" and tostring(value) or fallback
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function inList(value, list)
    local i
    for i = 1, #list do
        if value == list[i] then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Threat classification
-- ---------------------------------------------------------------------------

-- Normalizes every attacker representation the mod produces into one of
-- Const.Threat.*.  Accepts a Perception recentThreat table, a damage event, or
-- a pre-normalized string, so callers never have to agree on a shape.
function FlavorText.ClassifyThreat(source)
    local kind
    local provider
    if source == nil then return Const.Threat.UNKNOWN end
    if type(source) == "string" then
        kind = lower(source)
    elseif type(source) == "table" then
        kind = lower(source.kind
            or source.attackerKind
            or source.threatKind
            or source.type)
        provider = lower(source.provider or source.attackerProvider)
    else
        return Const.Threat.UNKNOWN
    end
    -- Bandits and ProjectALife threats arrive as "foreign_npc" with a
    -- provider tag; keep the provider so definitions can special-case them.
    if kind == "bandit" or provider == "bandits" then
        return Const.Threat.FOREIGN_NPC, "Bandits"
    end
    if kind == "zombie" or kind == "zombies" then
        return Const.Threat.ZOMBIE
    end
    if kind == "player" then
        return Const.Threat.PLAYER
    end
    if kind == "foreign_npc" or kind == "bandit_npc" then
        return Const.Threat.FOREIGN_NPC
    end
    if kind == "npc" or kind == "managed_npc" or kind == "hooman" then
        return Const.Threat.NPC
    end
    if kind == "environment" or kind == "fall" or kind == "unknown" then
        return Const.Threat.UNKNOWN
    end
    return Const.Threat.UNKNOWN
end

-- True when the threat was actually a survivor rather than the dead.  Hostile
-- NPC/player attackers are the only case that can plausibly accept a plea.
function FlavorText.IsHumanThreat(threat)
    return threat == Const.Threat.NPC
        or threat == Const.Threat.PLAYER
        or threat == Const.Threat.FOREIGN_NPC
end

-- ---------------------------------------------------------------------------
-- Audience classification (faction first, relationship second)
-- ---------------------------------------------------------------------------

local function relationshipBand(state, tier)
    state = lower(state)
    tier = lower(tier)
    if inList(state, Const.HostileStates) then return Const.Audience.HOSTILE end
    if inList(tier, Const.FriendlyTiers) then return Const.Audience.FRIENDLY end
    if inList(state, Const.FriendlyStates) then return Const.Audience.FRIENDLY end
    if state == "unknown" and tier == "reserved" then return nil end
    if inList(tier, Const.NeutralTiers) then return Const.Audience.NEUTRAL end
    if inList(state, Const.NeutralStates) then return Const.Audience.NEUTRAL end
    return nil
end

-- Audience precedence is deliberate and must stay in this order:
--   1. relationship enemy/rival  -> hostile (a faction ally can still hate you)
--   2. same faction / owned follower -> ally
--   3. at-war faction -> hostile
--   4. allied faction -> ally
--   5. relationship friend/familiar -> friendly
--   6. different non-belligerent faction -> stranger
--   7. everything else -> neutral
-- War outranks friendship-tier and stranger standing; a personal enemy always
-- outranks the faction view.
function FlavorText.ClassifyAudience(input)
    local factionID
    local otherFactionID
    local band
    if type(input) ~= "table" then return Const.Audience.NEUTRAL end
    band = relationshipBand(input.relationshipState, input.relationshipTier)
    if band == Const.Audience.HOSTILE then return band end
    if input.isSelf == true or input.isOwner == true then
        return Const.Audience.SELF
    end
    factionID = clean(input.factionID, nil)
    otherFactionID = clean(input.otherFactionID, nil)
    if input.sameFaction == true then return Const.Audience.ALLY end
    if input.isCompanion == true or input.isFollower == true then
        return Const.Audience.ALLY
    end
    if factionID and otherFactionID and factionID == otherFactionID then
        return Const.Audience.ALLY
    end
    -- Faction-level war/alliance is consulted before the neutral relationship
    -- fallback: an unknown personal history does not soften an active war.
    if input.factionBand == Const.Audience.HOSTILE then
        return Const.Audience.HOSTILE
    end
    if input.factionBand == Const.Audience.ALLY then
        return Const.Audience.ALLY
    end
    if band then return band end
    if otherFactionID and otherFactionID ~= ""
        and not (factionID and factionID == otherFactionID)
    then
        -- A different, non-belligerent faction is a true stranger: someone the
        -- downed NPC can address without hostility or intimacy.
        return Const.Audience.STRANGER
    end
    return Const.Audience.NEUTRAL
end

-- ---------------------------------------------------------------------------
-- Need classification (what the downed NPC is asking for)
-- ---------------------------------------------------------------------------

-- `input.factionBand` is the authoritative cross-faction answer
-- (Const.Audience.HOSTILE for war, Const.Audience.ALLY for allied) computed by
-- whichever faction service the caller has.  Keeping it as an input rather
-- than a dependency keeps this module pure and testable.
local function resolveAudience(input)
    if type(input) ~= "table" then return Const.Audience.NEUTRAL end
    return FlavorText.ClassifyAudience({
        factionID = input.factionID,
        otherFactionID = input.otherFactionID,
        factionBand = input.factionBand,
        relationshipState = input.relationshipState,
        relationshipTier = input.relationshipTier,
        isSelf = input.isSelf,
        isOwner = input.isOwner,
        isCompanion = input.isCompanion,
        isFollower = input.isFollower,
        sameFaction = input.sameFaction,
    })
end

-- Wound families are resolved by the caller (they own the wound model); this
-- function only turns a compact description into a need bucket.
function FlavorText.ClassifyNeed(input)
    if type(input) ~= "table" then return Const.Need.HELP end
    if input.bleeding == true or (tonumber(input.bleedingRate) or 0) > 0 then
        return Const.Need.BLEEDOUT
    end
    if input.treatableWoundCount and input.treatableWoundCount > 0 then
        return Const.Need.BANDAGE
    end
    if input.needsRescue == true then return Const.Need.RESCUE end
    if input.infected == true then return Const.Need.RESCUE end
    if input.critical == true then return Const.Need.HELP end
    return Const.Need.HELP
end

-- A hostile-downed NPC in front of a human attacker pleads; nothing else in
-- the matrix changes bucket, because the same wound still needs the same care.
local function applyThreatOverride(need, threat, audience)
    if audience == Const.Audience.HOSTILE
        and FlavorText.IsHumanThreat(threat)
    then
        return Const.Need.MERCY
    end
    if audience == Const.Audience.HOSTILE
        and threat == Const.Threat.ZOMBIE
    then
        return Const.Need.FAINT
    end
    return need
end

-- ---------------------------------------------------------------------------
-- Resolution
-- ---------------------------------------------------------------------------

-- Returns a bounded, ordered list of variant keys to try, most specific first.
function FlavorText.ResolveKeys(input)
    local keys = {}
    local i
    local audience
    local need
    local threat
    if type(input) ~= "table" then
        return { Const.Need.HELP }
    end
    threat = FlavorText.ClassifyThreat(input.threat or input.attacker)
    audience = resolveAudience(input)
    need = FlavorText.ClassifyNeed(input)
    need = applyThreatOverride(need, threat, audience)
    -- Zombie contact is the single most common case; keep the phrasing inside
    -- the generic audience lanes instead of multiplying variants per role.
    if threat == Const.Threat.ZOMBIE then
        keys[#keys + 1] = audience .. "__" .. need .. "__zombie"
    end
    if threat == Const.Threat.NPC or threat == Const.Threat.FOREIGN_NPC then
        keys[#keys + 1] = audience .. "__" .. need .. "__npc"
    end
    if threat == Const.Threat.PLAYER then
        keys[#keys + 1] = audience .. "__" .. need .. "__player"
    end
    keys[#keys + 1] = audience .. "__" .. need
    keys[#keys + 1] = audience
    keys[#keys + 1] = need
    return keys
end

-- Packages the resolver output as a normal social-flavor context table.  The
-- `when` matchers in the flavor definitions read these keys directly.
function FlavorText.BuildContext(input)
    local audience
    local need
    local threat
    if type(input) ~= "table" then input = {} end
    threat = FlavorText.ClassifyThreat(input.threat or input.attacker)
    audience = resolveAudience(input)
    need = applyThreatOverride(
        FlavorText.ClassifyNeed(input),
        threat,
        audience
    )
    return {
        downedAudience = audience,
        downedNeed = need,
        downedThreat = threat,
    }
end

-- Convenience: join build + resolve for callers that only need the keys.
function FlavorText.Resolve(input)
    return FlavorText.ResolveKeys(input), FlavorText.BuildContext(input)
end

FlavorText.VERSION = 1

-- ---------------------------------------------------------------------------
-- Leadership-loss (grief) classification
-- ---------------------------------------------------------------------------

-- How a surviving NPC felt about the leader who just died.  This is a tone
-- selector only: the addressed listener, the successor and the structural
-- outcome are separate inputs, so a colonist can mourn warmly while a rival
-- does not mourn at all.
function FlavorText.ClassifyGrief(input)
    local state
    local tier
    if type(input) ~= "table" then return Const.Grief.DISTANT end
    state = lower(input.relationshipState)
    tier = lower(input.relationshipTier)
    -- A partner, spouse or family member outranks every other signal.
    if inList(state, Const.FamilyStates)
        or inList(lower(input.relationshipKind), Const.FamilyStates)
    then
        return Const.Grief.DEVOTED
    end
    if inList(state, Const.HostileStates) then return Const.Grief.DISSENT end
    if input.wasLeaderOfSpeaker == true then return Const.Grief.CLOSE end
    if inList(tier, Const.BondedTiers) then return Const.Grief.CLOSE end
    if inList(tier, Const.FriendlyTiers) then return Const.Grief.CLOSE end
    if input.isCompanion == true then return Const.Grief.CLOSE end
    if input.sameFaction == true or input.isFollower == true
        or input.recruited == true
    then
        return Const.Grief.COLONIST
    end
    return Const.Grief.DISTANT
end

-- Packages the leadership-loss context for the flavor `when` matchers.
function FlavorText.BuildLeaderDeathContext(input)
    if type(input) ~= "table" then input = {} end
    return {
        leaderGrief = FlavorText.ClassifyGrief(input),
        leaderSuccession = tostring(input.succession or Const.Succession.NONE),
        leaderDied = true,
        leaderRelationshipKind = clean(input.relationshipKind, nil),
        leaderWasOwner = input.wasOwner == true,
        leaderSuccessorName = clean(input.successorName, nil),
        leaderGroupName = clean(input.groupName, nil),
    }
end

return FlavorText