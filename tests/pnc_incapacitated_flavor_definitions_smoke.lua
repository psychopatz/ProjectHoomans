local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

-- The flavor registry is shared data; definitions are registered by the client
-- presentation tree but are pure tables and load without a running game.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.SocialFlavor = PsychopatzCore.SocialFlavor
    or require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

local Flavor = PsychopatzCore.SocialFlavor
local Resolver = require "PNC/Core/Social/PNC_FlavorTextResolver"
local Const = PNC.FlavorTextConst

-- Register the authored definitions under test.
-- Load the split definitions through their real load-order barrel so the
-- require chain is exercised exactly as the game would resolve it.
local FUNCTION_DIR = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/"
local function loadDefinitions()
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua")
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Call.lua")
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Update.lua")
    dofile(FUNCTION_DIR .. "PNC_SocialFlavorDefinitions_Incapacitated_Repeat.lua")
end
loadDefinitions()

local call = Flavor.Get("social.incapacitated_call")
local update = Flavor.Get("social.incapacitated_update")
T.truthy(call, "the incapacitated call flavor is registered")
T.truthy(update, "the incapacitated update flavor is registered")
T.equal(call.family, Const.FAMILY,
    "the call flavor uses the shared distress family")
T.equal(update.family, Const.FAMILY,
    "the update flavor uses the shared distress family")

-- ---------------------------------------------------------------------------
-- The matrix must have no silent gaps: every audience x need x threat cell the
-- resolver can emit has to resolve to authored text (a specific variant or a
-- broader fallback), and must never return the raw unresolved key.
-- ---------------------------------------------------------------------------

local audiences = {
    Const.Audience.ALLY,
    Const.Audience.FRIENDLY,
    Const.Audience.NEUTRAL,
    Const.Audience.STRANGER,
    Const.Audience.HOSTILE,
    Const.Audience.SELF,
}
local needs = {
    Const.Need.BANDAGE,
    Const.Need.BLEEDOUT,
    Const.Need.RESCUE,
    Const.Need.MERCY,
    Const.Need.HELP,
    Const.Need.FAINT,
}
local threats = {
    Const.Threat.ZOMBIE,
    Const.Threat.NPC,
    Const.Threat.PLAYER,
    Const.Threat.FOREIGN_NPC,
    Const.Threat.UNKNOWN,
}

-- Rebuild the exact `when` payloads the resolver produces, then ask the
-- registry for the winning variant.  This tests the real selection engine.
local function pick(flavorID, context)
    return Flavor.ResolveDetailed(flavorID, "npc", "gap-seed", context)
end

local a
local n
local t
local v
local checked = 0
local missing = {}
local VARIANT_IDS = {
    "social.incapacitated_call",
    "social.incapacitated_repeat",
    "social.incapacitated_update",
}
-- Every flavor id in the distress family must cover the whole matrix: the
-- call, the slow repeat and the wound-status update all share one lane
-- vocabulary, so a gap in any of them is a lane that renders nothing.
for v = 1, #VARIANT_IDS do
    for a = 1, #audiences do
        for n = 1, #needs do
            for t = 1, #threats do
                local context = {
                    downedAudience = audiences[a],
                    downedNeed = needs[n],
                    downedThreat = threats[t],
                }
                local result = pick(VARIANT_IDS[v], context)
                checked = checked + 1
                if not result or not result.text or result.text == "" then
                    missing[#missing + 1] = VARIANT_IDS[v] .. ":"
                        .. table.concat({
                            audiences[a], needs[n], threats[t],
                        }, "/")
                else
                    -- Name tokens are supplied later by the presentation layer
                    -- from identity data.  Only resolver-owned keys must never
                    -- survive unresolved into the text.
                    T.falsy(string.find(result.text, "{downed", 1, true),
                        "no resolver key leaks into " .. VARIANT_IDS[v] .. " "
                            .. audiences[a] .. "/" .. needs[n] .. "/" .. threats[t])
                end
            end
        end
    end
end

T.equal(#missing, 0, "every distress flavor id covers every context cell: "
    .. table.concat(missing, ", "))
T.equal(checked, #VARIANT_IDS * #audiences * #needs * #threats,
    "the whole audience/need/threat matrix was exercised for every flavor id")

-- ---------------------------------------------------------------------------
-- Spot-check that the *correct* lane wins, not merely a non-empty fallback.
-- ---------------------------------------------------------------------------

local allyZombieBleed = pick("social.incapacitated_call", {
    downedAudience = Const.Audience.ALLY,
    downedNeed = Const.Need.BLEEDOUT,
    downedThreat = Const.Threat.ZOMBIE,
})
T.equal(allyZombieBleed.variantID, "ally_bleedout_zombie",
    "the most specific ally/zombie/bleedout lane wins")

local strangerNeutral = pick("social.incapacitated_call", {
    downedAudience = Const.Audience.STRANGER,
    downedNeed = Const.Need.HELP,
    downedThreat = Const.Threat.ZOMBIE,
})
T.equal(strangerNeutral.variantID, "stranger",
    "a stranger with no specific wound falls back to the stranger lane")

local mercy = pick("social.incapacitated_call", {
    downedAudience = Const.Audience.HOSTILE,
    downedNeed = Const.Need.MERCY,
    downedThreat = Const.Threat.NPC,
})
T.equal(mercy.variantID, "hostile_mercy_npc",
    "an NPC attacker produces the NPC-attributed plea variant")
T.truthy(string.find(mercy.text, "{attackerName}")
    or string.find(mercy.text, "Enough")
    or string.find(mercy.text, "Mercy")
    or string.find(mercy.text, "finished"),
    "the mercy lane addresses the attacker rather than a friend")

local mercyPlayer = pick("social.incapacitated_call", {
    downedAudience = Const.Audience.HOSTILE,
    downedNeed = Const.Need.MERCY,
    downedThreat = Const.Threat.PLAYER,
})
T.equal(mercyPlayer.variantID, "hostile_mercy_player",
    "a player attacker produces the player-attributed plea variant")
T.equal(mercyPlayer.text, Flavor.Resolve("social.incapacitated_call", "npc",
    "gap-seed", {
        downedAudience = Const.Audience.HOSTILE,
        downedNeed = Const.Need.MERCY,
        downedThreat = Const.Threat.PLAYER,
    }),
    "the same context and seed resolve deterministically")

local faint = pick("social.incapacitated_call", {
    downedAudience = Const.Audience.HOSTILE,
    downedNeed = Const.Need.FAINT,
    downedThreat = Const.Threat.ZOMBIE,
})
T.equal(faint.variantID, "hostile_faint_zombie",
    "a hostile facing the dead gets the faint lane, not the mercy lane")

-- ---------------------------------------------------------------------------
-- End-to-end: resolver input -> context -> text
-- ---------------------------------------------------------------------------

local keys, context = Resolver.Resolve({
    threat = { kind = "npc" },
    relationshipState = "enemy",
    relationshipTier = "reserved",
})
T.equal(context.downedAudience, Const.Audience.HOSTILE,
    "the resolver classifies the attacker's enemy as hostile")
T.equal(context.downedNeed, Const.Need.MERCY,
    "the resolver turns a hostile NPC attack into a mercy plea")
local resolved = pick("social.incapacitated_call", context)
T.truthy(resolved and resolved.text ~= "",
    "the end-to-end hostile NPC plea produces visible text")
T.truthy(string.find(keys[1], "mercy", 1, true),
    "the primary fallback key advertises the mercy need")

-- ---------------------------------------------------------------------------
-- Variety: the same lane must be able to say different things, and the seed
-- must actually rotate the line.  This is what stops a long wait sounding
-- like one sentence on repeat.
-- ---------------------------------------------------------------------------

local function distinctFor(flavorID, context, samples)
    local seen = {}
    local count = 0
    local i
    for i = 1, samples do
        local result = Flavor.ResolveDetailed(
            flavorID, "npc", "seed-" .. tostring(i), context
        )
        if result and result.text and not seen[result.text] then
            seen[result.text] = true
            count = count + 1
        end
    end
    return count
end

local allyBleed = {
    downedAudience = Const.Audience.ALLY,
    downedNeed = Const.Need.BLEEDOUT,
    downedThreat = Const.Threat.ZOMBIE,
}
local callVariety = distinctFor("social.incapacitated_call", allyBleed, 8)
local repeatVariety = distinctFor("social.incapacitated_repeat", allyBleed, 8)
T.truthy(callVariety >= 3,
    "the ally bleedout call lane offers at least 3 distinct lines, got "
        .. tostring(callVariety))
T.truthy(repeatVariety >= 3,
    "the ally bleedout repeat lane offers at least 3 distinct lines, got "
        .. tostring(repeatVariety))

-- The repeat beat must not reuse the call wording, otherwise a long wait
-- reads as the same sentence twice.
local firstCall = Flavor.ResolveDetailed(
    "social.incapacitated_call", "npc", "seed-1", allyBleed)
local callSet = {}
local i
for i = 1, 8 do
    local r = Flavor.ResolveDetailed(
        "social.incapacitated_call", "npc", "seed-" .. tostring(i), allyBleed)
    if r then callSet[r.text] = true end
end
local overlaps = 0
for i = 1, 8 do
    local r = Flavor.ResolveDetailed(
        "social.incapacitated_repeat", "npc", "seed-" .. tostring(i), allyBleed)
    if r and callSet[r.text] then overlaps = overlaps + 1 end
end
T.equal(overlaps, 0,
    "the repeat beat never repeats the call wording verbatim")

-- Every authored lane must carry more than one line, so no lane can read as
-- a single canned sentence.
local laneShortages = {}
for v = 1, #VARIANT_IDS do
    local definition = Flavor.Get(VARIANT_IDS[v])
    if definition and type(definition.variants) == "table" then
        for _, variant in ipairs(definition.variants) do
            local lines = variant.npc
            if type(lines) == "table" and #lines < 2 then
                laneShortages[#laneShortages + 1] = VARIANT_IDS[v] .. ":"
                    .. tostring(variant.id) .. "(" .. tostring(#lines) .. ")"
            end
        end
    end
end
T.equal(#laneShortages, 0,
    "every distress lane has at least two authored lines: "
        .. table.concat(laneShortages, ", "))

-- The distress family should be substantially larger than a one-time line.
local totalLines = 0
for v = 1, #VARIANT_IDS do
    local definition = Flavor.Get(VARIANT_IDS[v])
    local function countLines(lines)
        if type(lines) ~= "table" then return 0 end
        return #lines
    end
    if definition then
        totalLines = totalLines + countLines(definition.npc)
        for _, variant in ipairs(definition.variants or {}) do
            totalLines = totalLines + countLines(variant.npc)
        end
    end
end
T.truthy(totalLines >= 100,
    "the distress family offers wide variety, got " .. tostring(totalLines)
        .. " authored lines")

return true