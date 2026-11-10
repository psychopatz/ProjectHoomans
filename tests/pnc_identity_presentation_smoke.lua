local T = require "tests/support/test"

PNC = {
    Network = {
        ClientState = {
            npcKnowledge = {},
            snapshots = {},
        },
    },
}

T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))

local Identity = PNC.NPCIdentityPresentation
local stranger = { id = "npc-stranger", displayName = "Morgan Reed" }

T.equal(Identity.GetName(stranger), "Stranger",
    "raw transport name is hidden until learned")
T.equal(Identity.GetContextLabel(stranger), "Talk to stranger",
    "unknown NPC context label")
T.equal(Identity.GetArchetype(stranger), "Unknown background",
    "raw archetype is hidden until learned")
T.equal(Identity.GetFactionName(stranger), "Unknown",
    "raw faction is hidden until learned")

PNC.Network.ClientState.npcKnowledge["npc-stranger"] = {
    knownFaction = { id = "ashwood", name = "Ashwood Haven" },
    categories = {
        {
            descriptors = {
                { descriptorID = "identity.name", value = "Morgan Reed", status = "confirmed" },
                { descriptorID = "identity.archetype", value = "doctor", status = "confirmed" },
                { descriptorID = "faction.identity", value = "ashwood", status = "confirmed" },
            },
        },
    },
}

T.equal(Identity.GetName(stranger), "Morgan Reed",
    "learned identity name")
T.equal(Identity.GetContextLabel(stranger), "Morgan Reed",
    "learned NPC context label")
T.equal(Identity.GetArchetype(stranger), "doctor",
    "learned archetype")
T.equal(Identity.GetFactionName(stranger), "Ashwood Haven",
    "learned faction")

PNC.Network.ClientState.npcKnowledge["npc-stranger"].categories[1].descriptors[#PNC.Network.ClientState.npcKnowledge["npc-stranger"].categories[1].descriptors + 1] = {
    descriptorID = "identity.nickname",
    value = "Mo",
    status = "confirmed",
}
T.equal(Identity.GetName(stranger), "Morgan Reed (Mo)",
    "full identity appends the learned nickname")
T.equal(Identity.GetFullName(stranger), "Morgan Reed",
    "full identity remains separately available")
T.equal(Identity.GetNickname(stranger), "Mo",
    "nickname remains separately available")

PNC.Network.ClientState.npcKnowledge["npc-nickname-only"] = {
    categories = {
        {
            descriptors = {
                { descriptorID = "identity.nickname", value = "Pat", status = "confirmed" },
            },
        },
    },
}
T.equal(Identity.GetName({ id = "npc-nickname-only" }), "Pat",
    "nickname is the visible identity before full name disclosure")

T.equal(Identity.GetName({
    id = "npc-companion", displayName = "Riley", recruited = true,
}), "Riley", "player companion name remains usable")
PNC.Network.ClientState.snapshots["npc-starting-family"] = {
    id = "npc-starting-family",
    displayName = "Casey Survivor",
    recruited = true,
}
T.equal(Identity.GetName("npc-starting-family"), "Casey Survivor",
    "companion lookup by ID uses its replicated identity immediately")
T.finish("pnc_identity_presentation_smoke")
