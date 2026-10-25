-- Movement, camping, inventory-intent, and world-action concepts.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog concept module requires Catalog.Internal")
end

local registerConcept = Internal.RegisterConcept
local CampSite = PNC.Semantics.CampSite
if type(registerConcept) ~= "function"
then
    error("semantic catalog concept module requires registration adapters")
end
if type(CampSite) ~= "table" or type(CampSite.RoomTypesList) ~= "function" then
    error("semantic catalog concepts require camp-site room definitions")
end

function Internal.RegisterActionConcepts()
    registerConcept(
        "FOLLOW",
        { "follow", "follow me", "come with me", "come along" }
    )
    registerConcept("STOP", { "stop", "halt" })
    registerConcept("WAIT", {
        "wait", "stay", "wait here", "stay here", "stay right here",
    })
    registerConcept("CAMP", { "camp", "camping" })
    registerConcept("CAMP_PREP", { "at", "in", "inside", "by", "near" })
    registerConcept("CAMPFIRE", {
        "campfire", "fire pit", "firepit", "fire",
    })
    for _, roomDefinition in ipairs(CampSite.RoomTypesList()) do
        registerConcept("ROOM_" .. tostring(roomDefinition.id),
            roomDefinition.aliases, 2)
    end
    registerConcept("GO", { "go", "head", "travel" })
    registerConcept("HOME", { "home" })
    registerConcept("FETCH", { "bring", "get", "fetch", "grab" })
    registerConcept("GIVE", { "give", "hand", "pass" })
    registerConcept("HAVE", { "have", "got", "carry", "carrying" })
    registerConcept("ANY_ITEM", {
        "anything", "something", "item", "items", "thing", "things",
        "stuff",
    }, 5)
    registerConcept("WANT", { "want", "wants", "need", "needs" })
    registerConcept("GIFT", { "gift", "present" }, 3)
    registerConcept("HEAR", { "hear", "heard" })
    registerConcept("NEWS", {
        "news", "gossip", "gossips", "rumor", "rumors",
        "rumour", "rumours",
    })
    -- This is a safe, non-mutating conversation root.  The exact dataset
    -- patterns remain authoritative; the concept alias only lets Core's
    -- bounded fuzzy pass recover compact/typo-level variants such as
    -- "whaat up" without making any action command fuzzy.
    registerConcept("WHATS_UP", {
        "what's up", "whats up", "whatsup", "what up",
    }, 6)
end

return Internal
