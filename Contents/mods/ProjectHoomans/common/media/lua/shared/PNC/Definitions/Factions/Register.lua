-- Registers Project Hoomans (PNC) faction name definition modules into
-- PsychopatzCore's shared generation registry and PNC.FactionNameGenerator.
-- Expansion packs can register additional faction types the same way without
-- touching core logic or existing faction definitions.

local FACTION_DEFINITIONS = {
    require "PNC/Definitions/Factions/Settler",
    require "PNC/Definitions/Factions/Looter",
    require "PNC/Definitions/Factions/Refugee",
}

local Register = {}

function Register.Apply(coreProfiles, pncGenerator)
    if not coreProfiles then
        local ok, loaded = pcall(
            require,
            "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationProfiles"
        )
        if ok and type(loaded) == "table" then
            coreProfiles = loaded
        end
    end
    local count = 0
    for _, pool in ipairs(FACTION_DEFINITIONS) do
        if type(pool) == "table" and pool.id then
            if coreProfiles and type(coreProfiles.RegisterNamePool) == "function" then
                coreProfiles.RegisterNamePool(pool.id, pool)
            end
            if pncGenerator and type(pncGenerator.RegisterPool) == "function" then
                pncGenerator.RegisterPool(pool.id, pool)
            end
            count = count + 1
        end
    end
    return count
end

Register.Definitions = FACTION_DEFINITIONS
Register.Apply(nil, PNC and PNC.FactionNameGenerator or nil)

return Register
