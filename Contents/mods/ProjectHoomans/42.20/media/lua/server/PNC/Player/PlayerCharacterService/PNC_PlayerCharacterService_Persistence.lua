if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerCharacters = PNC.PlayerCharacters or {}
PNC.PlayerContext = PNC.PlayerContext or {}
PNC.PlayerCharacters.Internal = PNC.PlayerCharacters.Internal or {}

local PlayerCharacters = PNC.PlayerCharacters
local Internal = PlayerCharacters.Internal
local Constants = PNC.PlayerCharacterConstants
local Types = PNC.PlayerCharacterTypes
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local deepEqual = Internal.deepEqual
local copy = Internal.copy
local assignTable = Internal.assignTable
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"

function PlayerCharacters.Load()
    local raw
    local normalized
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    raw = Reset.Read(Constants.REGISTRY_MODDATA_KEY)
    local reason = Reset.Check(raw, Constants.REGISTRY_SCHEMA_VERSION, nil,
        function(value)
            return type(value.byUUID) == "table"
                and type(value.byAccountKey) == "table"
        end)
    normalized = Types.NormalizeRegistry(reason == nil and raw or nil)
    PlayerCharacters.Registry = normalized
    PlayerCharacters.Loaded = true
    PlayerCharacters.Dirty = (reason ~= nil and reason ~= "empty_state")
        or (reason == nil and not deepEqual(raw, normalized))
    if reason ~= nil and reason ~= "empty_state" then
        Reset.Mark(PlayerCharacters, raw, Constants.REGISTRY_SCHEMA_VERSION,
            reason, "player_characters")
    end
    PlayerCharacters.ResetRuntimeBindings("registry_load")
    return true, PlayerCharacters.Dirty
end

function PlayerCharacters.EnsureLoaded()
    if not PlayerCharacters.Loaded then
        return PlayerCharacters.Load()
    end
    return true
end

function PlayerCharacters.Save(flushGlobal)
    local target
    PlayerCharacters.EnsureLoaded()
    if not PlayerCharacters.Dirty then
        return false, "not_dirty"
    end
    local written = Reset.Write(Constants.REGISTRY_MODDATA_KEY,
        Types.NormalizeRegistry(PlayerCharacters.Registry))
    if not written then return false, "moddata_unavailable" end
    PlayerCharacters.Dirty = false
    if flushGlobal ~= false and GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    return true
end

function PlayerCharacters.NormalizeRegistry(value)
    local normalized
    if value ~= nil then
        return Types.NormalizeRegistry(value)
    end
    PlayerCharacters.EnsureLoaded()
    normalized = Types.NormalizeRegistry(PlayerCharacters.Registry)
    if not deepEqual(PlayerCharacters.Registry, normalized) then
        PlayerCharacters.Registry = normalized
        PlayerCharacters.Dirty = true
    end
    return copy(PlayerCharacters.Registry)
end

function PlayerCharacters.GetRegistryRecord(characterUUID)
    local record
    PlayerCharacters.EnsureLoaded()
    characterUUID = Types.ResolveUUID(
        PlayerCharacters.Registry, characterUUID
    )
    record = characterUUID
        and PlayerCharacters.Registry.byUUID[characterUUID] or nil
    return record and copy(record) or nil
end

function PlayerCharacters.GetRegistrySnapshot()
    PlayerCharacters.EnsureLoaded()
    return copy(PlayerCharacters.Registry)
end

-- Internal server-side commit boundary used by the social-profile service.
-- It deliberately accepts only a normalized profile-shaped table and is not
-- exposed through any client command.

return PlayerCharacters
