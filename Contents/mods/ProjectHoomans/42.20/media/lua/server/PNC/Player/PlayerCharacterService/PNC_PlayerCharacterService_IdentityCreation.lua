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
local presentationIdentityFor = Internal.presentationIdentityFor
local informationalFields = Internal.informationalFields
local setMirror = Internal.setMirror
local incrementRegistryRevision = Internal.incrementRegistryRevision
local indexRecord = Internal.indexRecord
local bind = Internal.bind

local function createIdentity(player, accountKey, at)
    local uuid
    local reason
    local info
    local record
    uuid, reason = PlayerCharacters.GenerateUUID()
    if not uuid then
        return nil, reason
    end
    info = informationalFields(player)
    record = Types.NewCharacterRecord({
        uuid = uuid,
        accountKey = accountKey,
        accountIdentity = presentationIdentityFor(player) or accountKey,
        status = Constants.STATUS_ACTIVE,
        createdAt = at,
        firstSeenAt = at,
        lastSeenAt = at,
        forename = info and info.forename,
        surname = info and info.surname,
        displayName = info and info.displayName,
        lastKnownX = info and info.lastKnownX,
        lastKnownY = info and info.lastKnownY,
        lastKnownZ = info and info.lastKnownZ,
        revision = 1,
    })
    PlayerCharacters.Registry.byUUID[uuid] = record
    indexRecord(record)
    incrementRegistryRevision()
    setMirror(player, uuid, accountKey)
    bind(player, uuid, accountKey)
    return uuid, "new_identity"
end


Internal.createIdentity = createIdentity

return PlayerCharacters
