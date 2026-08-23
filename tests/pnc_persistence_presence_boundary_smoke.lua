local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Persistence/PNC_Persistence.lua"
)
local providers = {
    "PNC_Persistence_Primitives",
    "PNC_Persistence_HealthBody",
    "PNC_Persistence_HealthCodec",
    "PNC_Persistence_RecordState",
    "PNC_Persistence_Runtime",
    "PNC_Persistence_Serialize",
    "PNC_Persistence_DeserializeFinalization",
    "PNC_Persistence_Deserialize",
    "PNC_Persistence_Collections",
}

local previous = 0
for index = 1, #providers do
    local needle = "require \"PNC/Core/Persistence/PNC_Persistence/"
        .. providers[index] .. "\""
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, providers[index] .. " load order")
    previous = position
end

T.finish("pnc_persistence_presence_boundary_smoke")
