-- SAVE-backed boundary into the real Project Hoomans persistence owners.
-- Submodules retain the public ProductionRehydration table and its API.

local ProductionRehydration = {
    Internal = {},
}

local installData = require "worker/ProductionRehydration_Data"
local installRegistries = require "worker/ProductionRehydration_Registries"
local installProjection = require "worker/ProductionRehydration_Projection"
local installLifecycle = require "worker/ProductionRehydration_Lifecycle"

installData(ProductionRehydration)
installRegistries(ProductionRehydration)
installProjection(ProductionRehydration)
installLifecycle(ProductionRehydration)

return ProductionRehydration
