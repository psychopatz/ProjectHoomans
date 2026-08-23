local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_Bite.lua"
)
local providers = {
    "PNC_ZombieAggro_Bite_Lane",
    "PNC_ZombieAggro_Bite_Diagnostics",
    "PNC_ZombieAggro_Bite_Release",
    "PNC_ZombieAggro_Bite_Start",
    "PNC_ZombieAggro_Bite_Damage",
    "PNC_ZombieAggro_Bite_Update",
}
local publicFunctions = {
    "HasBiteLane",
    "ClearBiteEntryForZombie",
    "ClearBiteEntriesForNPCBody",
    "TryStartBite",
    "UpdateBiteState",
    "PumpBiteRecovery",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = {},
    Const = {},
    Registry = {},
    Sandbox = {},
    Health = {},
    ZombieAggro = {
        State = { bites = {} },
        Internal = {},
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_Bite.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.ZombieAggro[functionName]),
        "function",
        "entry point should preserve ZombieAggro." .. functionName
    )
end
for i = 1, #providers do
    package.loaded[
        "PNC/Core/Zombies/PNC_ZombieAggro_Bite/" .. providers[i]
    ] = nil
end

T.finish("pnc_zombie_aggro_bite_presence_boundary_smoke")
