local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Persistence/PNC_Persistence.lua"
)
local providers = {
    "PNC/Core/Health/PNC_HealthRepository",
    "PNC/Core/Identity/PNC_IdentityRepository",
    "PNC/Core/Relationships/PNC_RelationshipRepository",
    "PNC/Core/Skills/PNC_SkillsRepository",
    "PNC/Core/Commands/PNC_CompanionRecordRepository",
    "PNC/Core/Combat/PNC_CombatRecordRepository",
    "PNC/Core/Presence/PNC_BodyRepository",
    "PNC/Core/Travel/PNC_TravelRepository",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Runtime",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Repairs",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Serialize",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_DeserializeFinalization",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Deserialize",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Collections",
}

local previous = 0
for index = 1, #providers do
    local needle = "require \"" .. providers[index] .. "\""
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, providers[index] .. " load order")
    previous = position
end

T.finish("pnc_persistence_presence_boundary_smoke")
