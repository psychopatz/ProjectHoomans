local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = { Semantics = {} }
local Reactions = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)

local styles = {
    "aggressive", "supportive", "shaken", "brave",
    "reserved", "cold", "practical",
}
local firstTextByStyle = {}

local function resolve(role, style, eventID)
    local eventType = role == "killer"
        and "zombie_kill_self" or "zombie_kill_witnessed"
    local result = Reactions.Resolve({
        eventType = eventType,
        eventID = eventID,
        npcID = "npc-catalog",
        act = "REACT",
        topic = "combat",
        context = {
            eventType = eventType,
            eventRef = eventID,
            combatReactionRole = role,
            combatReactionStyle = style,
            combatReactionMood = style == "shaken" and "panicked" or "steady",
            combatPressure = "several",
            killerActorKind = role == "killer" and "npc" or "player",
            factRefs = { eventID },
            semanticEventFacts = {
                [eventID] = {
                    eventRef = eventID,
                    authoritative = true,
                    disclosure = "player",
                    summary = "a zombie was killed nearby",
                    happened = "a zombie was killed nearby",
                    quantity = "5 zombies are still close enough to matter.",
                    health = "I'm okay.",
                    nextAction = "Clear the nearby zombies before we relax.",
                },
            },
        },
    })
    T.truthy(result, role .. "/" .. style .. " resolves")
    T.truthy(string.find(
        result.realizationFamily,
        "semantic.combat.kill." .. role .. "." .. style,
        1,
        true
    ), role .. "/" .. style .. " uses its bounded pool")
    T.equal(#(result.offerIDs or {}), 4,
        role .. "/" .. style .. " exposes grounded follow-ups")
    T.truthy(result.fallback and result.fallback ~= "",
        role .. "/" .. style .. " has authored fallback text")
    return result
end

for _, role in ipairs({ "witness", "killer" }) do
    for _, style in ipairs(styles) do
        local eventID = "event:kill:" .. role .. ":" .. style
        local first = resolve(role, style, eventID)
        local repeated = resolve(role, style, eventID)
        T.truthy(
            string.find(first.realizationID,
                "kill_" .. role .. "_" .. style .. "_", 1, true)
            and string.find(repeated.realizationID,
                "kill_" .. role .. "_" .. style .. "_", 1, true),
            role .. "/" .. style .. " stays in one semantic family"
        )
        firstTextByStyle[role .. ":" .. style] = first.fallback

        local variants = {
            [first.realizationID] = true,
            [repeated.realizationID] = true,
        }
        for index = 1, 18 do
            local varied = resolve(
                role,
                style,
                eventID .. ":" .. tostring(index)
            )
            variants[varied.realizationID] = true
        end
        local count = 0
        for _ in pairs(variants) do count = count + 1 end
        T.truthy(count >= 2,
            role .. "/" .. style .. " exposes more than one deterministic variant")
    end
end

T.truthy(
    firstTextByStyle["witness:supportive"]
        ~= firstTextByStyle["witness:cold"],
    "relationship/personality styles do not collapse to one witness line"
)
T.truthy(
    firstTextByStyle["killer:shaken"]
        ~= firstTextByStyle["killer:aggressive"],
    "mood/personality styles do not collapse to one killer line"
)

T.finish("pnc_semantic_combat_reaction_catalog_smoke")
