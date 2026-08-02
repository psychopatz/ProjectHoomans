local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

PNC = {
    Network = {
        ClientState = {
            npcKnowledge = {},
            snapshots = {},
        },
    },
}

dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Knowledge/PNC_NPCIdentityPresentation.lua")

local Identity = PNC.NPCIdentityPresentation
local stranger = { id = "npc-stranger", displayName = "Morgan Reed" }

assertEqual(Identity.GetName(stranger), "Unknown survivor",
    "raw transport name is hidden until learned")
assertEqual(Identity.GetContextLabel(stranger), "Talk to stranger",
    "unknown NPC context label")
assertEqual(Identity.GetArchetype(stranger), "Unknown background",
    "raw archetype is hidden until learned")
assertEqual(Identity.GetFactionName(stranger), "Unknown",
    "raw faction is hidden until learned")

PNC.Network.ClientState.npcKnowledge["npc-stranger"] = {
    knownFaction = { id = "ashwood", name = "Ashwood Haven" },
    categories = {
        {
            descriptors = {
                { descriptorID = "identity.name", value = "Morgan Reed", status = "confirmed" },
                { descriptorID = "identity.archetype", value = "doctor", status = "confirmed" },
            },
        },
    },
}

assertEqual(Identity.GetName(stranger), "Morgan Reed",
    "learned identity name")
assertEqual(Identity.GetContextLabel(stranger), "Morgan Reed",
    "learned NPC context label")
assertEqual(Identity.GetArchetype(stranger), "doctor",
    "learned archetype")
assertEqual(Identity.GetFactionName(stranger), "Ashwood Haven",
    "learned faction")

assertEqual(Identity.GetName({
    id = "npc-companion", displayName = "Riley", recruited = true,
}), "Riley", "player companion name remains usable")

print("pnc_identity_presentation_smoke: ok")
