local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" } })

PNC = {
    Translation = { GetKey = function(_, key) return key end },
    FacilityDefinitions = { Get = function(id)
        local objects = {
            forge = "Base.Forge",
            primitive_forge = "Base.Forge_Primitive_Forge",
            advanced_forge = "Base.Advanced_Forge",
        }
        local objectInfoName = objects[id]
        return objectInfoName and {
            id = id, stationId = id, directWorkstation = true,
            entityScript = objectInfoName,
            buildRecipeObjectInfoName = objectInfoName,
            displayNameKey = id,
        } or nil
    end },
    BuildRecipeCatalog = { Get = function(objectInfoName)
        return { objectInfoName = objectInfoName,
            displayName = objectInfoName }
    end },
}

local Target = T.load("ProjectHoomans", "client",
    "PNC/UI/Shared/PNC_FacilityBuildTarget.lua")

local expected = {
    { id = "forge", object = "Base.Forge" },
    { id = "primitive_forge", object = "Base.Forge_Primitive_Forge" },
    { id = "advanced_forge", object = "Base.Advanced_Forge" },
}

for _, entry in ipairs(expected) do
    local target = Target.Resolve({
        definitionId = "missing_alias",
        facilityId = entry.id,
        id = entry.id,
    })
    T.truthy(target, "station target did not resolve: " .. entry.id)
    T.equal(target.optionId, entry.id,
        "station target returned the wrong facility id: " .. entry.id)
    T.equal(target.objectInfoName, entry.object,
        "station target returned the wrong native object: " .. entry.id)
    T.truthy(Target.MatchesOption({
        id = "different_card",
        buildRecipeObjectInfoName = entry.object,
    }, target), "native object did not match its Base card: " .. entry.id)
end

T.falsy(Target.Resolve(nil), "missing station resolved unexpectedly")

return T.finish("pnc_facility_build_target_smoke")
