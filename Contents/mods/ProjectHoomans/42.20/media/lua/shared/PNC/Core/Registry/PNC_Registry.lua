-- Stable entry point for persistent NPC records and live-body lookup.

PNC = PNC or {}
PNC.Registry = PNC.Registry or {}
PNC.Registry.Internal = PNC.Registry.Internal or {}

require "PNC/Core/Registry/PNC_Registry/PNC_Registry_StorageCore"
require "PNC/Core/Registry/PNC_Registry/PNC_Registry_StorageMigration"
require "PNC/Core/Registry/PNC_Registry/PNC_Registry_LoadDirty"
require "PNC/Core/Registry/PNC_Registry/PNC_Registry_Records"
require "PNC/Core/Registry/PNC_Registry/PNC_Registry_LivePositions"

return PNC.Registry
