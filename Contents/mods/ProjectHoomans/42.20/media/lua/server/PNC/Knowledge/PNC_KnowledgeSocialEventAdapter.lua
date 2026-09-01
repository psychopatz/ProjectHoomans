-- Converts social-event outcomes into normalized knowledge evidence. The
-- knowledge service deliberately has no event-name switch; this adapter owns
-- the domain mapping and can be replaced/extended by future event sources.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.KnowledgeSocialEventAdapter = PNC.KnowledgeSocialEventAdapter or {}

local Adapter = PNC.KnowledgeSocialEventAdapter
local EntityRef = PNC.EntityRef
local PlayerCharacters = PNC.PlayerCharacters
local Knowledge = PNC.NPCKnowledge

local MAP = {
    player_emote_insult = {
        { "personality.aggression", 1, .45 },
        { "personality.compassion", -1, .45 },
    },
    treated_wound = { { "personality.compassion", 1, .45 } },
    saved_from_incapacitation = {
        { "personality.compassion", 1, .65 }, { "personality.bravery", 1, .55 }, { "personality.loyalty", 1, .55 },
    },
    protected_from_attacker = {
        { "personality.bravery", 1, .55 }, { "personality.loyalty", 1, .50 },
    },
    survived_combat_together = { { "personality.bravery", 1, .35 }, { "personality.loyalty", 1, .40 } },
    abandoned_in_combat = {
        { "personality.loyalty", -1, .70 }, { "personality.compassion", -1, .55 }, { "personality.bravery", -1, .50 },
    },
}

local function participant(key)
    return EntityRef and EntityRef.Parse and EntityRef.Parse(key) or nil
end

-- A player receives evidence only when the NPC is the acting participant. A
-- future witness adapter can add third-party observation without changing this.
function Adapter.Record(event)
    local mapping = event and MAP[event.type] or nil
    local actor = participant(event and event.actorKey)
    local target = participant(event and event.targetKey)
    if not mapping or not actor or not target or actor.kind ~= "npc" or target.kind ~= "player" then return 0 end
    local characterUUID = target.characterUUID
    if not characterUUID or not Knowledge then return 0 end
    local count = 0
    for _, entry in ipairs(mapping) do
        local outcome = Knowledge.RecordEvidence({
            characterUUID = characterUUID, npcID = actor.npcID, descriptorID = entry[1],
            sourceType = "observed_behavior", direction = entry[2], strength = entry[3],
            sourceEventID = event.id, sourceEntityKey = event.actorKey, worldAgeHours = event.occurredAt,
            tags = { socialEvent = event.type },
        })
        if outcome then count = count + 1 end
    end
    if count > 0 then
        Knowledge.RecordJournal(characterUUID, actor.npcID, {
            type = "social_event", translationKey = "UI_PNC_KnowledgeJournal_" .. tostring(event.type),
            sourceEventID = event.id, createdAt = event.occurredAt,
        })
    end
    return count
end

return Adapter
