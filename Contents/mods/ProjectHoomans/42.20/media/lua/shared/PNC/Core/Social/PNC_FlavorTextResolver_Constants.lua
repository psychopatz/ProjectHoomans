--[[
    PNC Flavor Text Resolver - bounded vocabularies.

    These tables are the contract between the resolver and the flavor
    definitions.  Adding a value here means adding at least one matching
    `when` variant in `PNC_SocialFlavorDefinitions.lua`; unknown values must
    always have a generic fallback lane.
]]

PNC = PNC or {}
PNC.FlavorTextConst = PNC.FlavorTextConst or {}

local Const = PNC.FlavorTextConst

-- Who caused the incapacitation.
Const.Threat = {
    ZOMBIE = "zombie",
    NPC = "npc",
    PLAYER = "player",
    FOREIGN_NPC = "foreign_npc",
    UNKNOWN = "unknown",
}

Const.AllThreats = {
    Const.Threat.ZOMBIE,
    Const.Threat.NPC,
    Const.Threat.PLAYER,
    Const.Threat.FOREIGN_NPC,
    Const.Threat.UNKNOWN,
}

-- Standing between the downed NPC and whoever can hear it.
Const.Audience = {
    SELF = "self",
    ALLY = "ally",
    FRIENDLY = "friendly",
    NEUTRAL = "neutral",
    STRANGER = "stranger",
    HOSTILE = "hostile",
}

-- What the downed NPC needs from the listener.
Const.Need = {
    BANDAGE = "bandage",
    BLEEDOUT = "bleedout",
    RESCUE = "rescue",
    MERCY = "mercy",
    HELP = "help",
    FAINT = "faint",
}

Const.AllNeeds = {
    Const.Need.BANDAGE,
    Const.Need.BLEEDOUT,
    Const.Need.RESCUE,
    Const.Need.MERCY,
    Const.Need.HELP,
    Const.Need.FAINT,
}

-- Relationship vocabulary.
Const.HostileStates = { "enemy", "rival", "hostile", "hated" }
Const.FriendlyStates = { "friend", "lover", "family", "companion" }
Const.FamilyStates = { "lover", "partner", "spouse", "family" }
Const.BondedTiers = { "bonded", "intimate" }
Const.NeutralStates = { "neutral", "acquaintance", "stranger", "known" }
Const.FriendlyTiers = { "bonded", "intimate", "warm" }
Const.NeutralTiers = { "familiar", "reserved", "unknown" }

-- Presentation tuning for the downed line.  Downed speech is a distress
-- signal, not ambient chatter: it outranks combat commentary and must be able
-- to interrupt it, but it still merges so a burst of state changes for one NPC
-- produces a single line.
Const.PRIORITY = 70
Const.WEIGHT = 3
Const.TTL_MS = 12000
Const.HOLD_MS = 3200
Const.FAMILY_COOLDOWN_MS = 15000
Const.SPEAKER_COOLDOWN_MS = 12000
Const.AMBIENT_CADENCE_MS = 4500
Const.MERGE_WINDOW_MS = 8000
Const.FAMILY = "incapacitated_distress"

-- The initial plea, a wound-status change, and the slow repeat beat all share
-- one episode merge key so a changing need replaces rather than stacks, but
-- each has its own authored voice so a long wait does not read as one line.
Const.FLAVOR_CALL = "social.incapacitated_call"
Const.FLAVOR_UPDATE = "social.incapacitated_update"
Const.FLAVOR_REPEAT = "social.incapacitated_repeat"

-- Cadence of the repeat beat while an NPC stays down.  Deliberately slower
-- than the update cooldown: the NPC sounds insistent, not hysterical.
Const.REPEAT_INTERVAL_MS = 45000

-- ---------------------------------------------------------------------------
-- Leadership-loss flavor (a player leader died in front of their followers)
-- ---------------------------------------------------------------------------

-- Mood of the grieving line, derived from the follower's relationship to the
-- dead leader.  This decides tone, not who is addressed.
Const.Grief = {
    DEVOTED = "devoted",   -- lover or family
    CLOSE = "close",       -- bonded companion or warm friend
    COLONIST = "colonist", -- a faction member with no close bond
    DISTANT = "distant",   -- neutral or unknown
    DISSENT = "dissent",   -- hostile or rival
}

Const.AllGrief = {
    Const.Grief.DEVOTED,
    Const.Grief.CLOSE,
    Const.Grief.COLONIST,
    Const.Grief.DISTANT,
    Const.Grief.DISSENT,
}

-- What the survivors do next, which the line should acknowledge.  These mirror
-- the two real branches in Factions.HandlePlayerCharacterDeath: a surviving
-- player inherits the faction, or the group converts to refugees and names an
-- NPC leader (the mobile group).
Const.Succession = {
    PROMOTED = "promoted",   -- an NPC became leader of the mobile group
    PLAYER = "player",       -- a surviving player inherited the faction
    NONE = "none",           -- no structural change observed
}

Const.FLAVOR_LEADER_DEATH = "social.witnessed_leader_death"

Const.LEADER_DEATH_PRIORITY = 88
Const.LEADER_DEATH_WEIGHT = 6
Const.LEADER_DEATH_TTL_MS = 18000
Const.LEADER_DEATH_HOLD_MS = 4500
Const.LEADER_DEATH_FAMILY = "leader_loss"
Const.LEADER_DEATH_COOLDOWN_MS = 60000

return Const