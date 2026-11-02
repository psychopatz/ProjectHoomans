local T = require "tests/support/test"

-- Load PsychopatzCore PlayerIdentity
package.path = "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;" .. package.path
local CoreIdentity = require "PsychopatzCore/Actors/PsychopatzPlayerIdentity"

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER_ROOT = T.path("ProjectHoomans", "server", "PNC/")

local globalData = {}
local worldHour = 100
local randomCounter = 0

ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

function getGameTime()
    return {
        getYear = function() return 1993 end,
        getMonth = function() return 8 end,
        getDay = function() return 1 end,
        getWorldAgeHours = function() return worldHour end,
    }
end

function getTimeInMillis()
    return math.floor(worldHour * 3600000)
end

function ZombRand(x)
    randomCounter = randomCounter + 1
    return randomCounter % (x or 1000)
end

-- Load Hoomans Identity & Services
T.load(SHARED_ROOT .. "Base/PNC_Core.lua")
T.load(SHARED_ROOT .. "Base/PNC_Constants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_PlayerCharacterConstants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_PlayerCharacterTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterDebug.lua")
T.load(SERVER_ROOT .. "Player/PNC_PlayerCharacterService.lua")

local function resetHoomansRegistry()
    globalData = {}
    PNC.PlayerCharacters.Registry = PNC.PlayerCharacterTypes.NewRegistry()
    PNC.PlayerCharacters.RuntimeByPlayer = setmetatable({}, { __mode = "k" })
    PNC.PlayerCharacters.RuntimeByUUID = {}
    PNC.PlayerCharacters.RuntimeContexts = setmetatable({}, { __mode = "k" })
    PNC.PlayerCharacters.Loaded = true
end

local function makePlayer(accountIdentity, modData, options)
    options = options or {}
    modData = modData or {}
    local player = {}
    player.getUsername = function() return accountIdentity end
    player.getOnlineID = function() return options.onlineID or -1 end
    player.getPlayerNum = function() return options.playerNum end
    player.getPlayerIndex = function() return options.playerNum end
    player.getModData = function() return modData end
    player.getDisplayName = function() return options.displayName or accountIdentity end
    player.getDescriptor = function()
        return {
            getForename = function() return options.forename or "Test" end,
            getSurname = function() return options.surname or "Survivor" end,
        }
    end
    player.getX = function() return 10 end
    player.getY = function() return 10 end
    player.getZ = function() return 0 end
    player.isDead = function() return false end
    return player, modData
end

print("=== Test 1: DT-First SP Player Identity Adoption ===")
do
    resetHoomansRegistry()
    -- Step 1: Player starts in Single Player with Core + DT only
    local isServerOrig = isServer
    local isClientOrig = isClient
    isServer = function() return false end
    isClient = function() return false end

    local spPlayer, modData = makePlayer("Survivor", nil, { playerNum = 7 })
    local dtUUID = CoreIdentity.GetCharacterUUID(spPlayer)
    local dtKey = CoreIdentity.GetTargetKey(spPlayer)

    T.truthy(dtUUID and string.match(dtUUID, "^char_"), "Core generated valid UUID")
    T.equal(dtKey, "player:sp_slot_7:" .. dtUUID, "Core canonical key is player:sp_slot_7:<uuid>")

    -- Step 2: Later Project Hoomans is enabled and loaded
    local hUUID, reason = PNC.PlayerCharacters.EnsureIdentity(spPlayer)
    local hKey = PNC.PlayerCharacters.GetEntityKey(spPlayer)

    T.equal(hUUID, dtUUID, "Hoomans adopted exact same UUID")
    T.equal(reason, "core_adopted", "EnsureIdentity returned core_adopted")
    T.equal(hKey, dtKey, "Hoomans GetEntityKey matches exact Core key")

    -- Check Hoomans registry record
    local record = PNC.PlayerCharacters.Registry.byUUID[hUUID]
    T.truthy(record, "Hoomans registry record created for adopted UUID")
    T.equal(record.accountKey, "sp_slot_7", "Record accountKey matches slot")
    T.equal(record.uuid, dtUUID, "Record UUID matches Core UUID")

    isServer = isServerOrig
    isClient = isClientOrig
end

print("=== Test 2: DT-First MP Player Identity Adoption ===")
do
    resetHoomansRegistry()
    -- Step 1: Player starts in MP (server authority)
    local isServerOrig = isServer
    local isClientOrig = isClient
    isServer = function() return true end
    isClient = function() return false end

    local mpPlayer, modData = makePlayer("Survivor_Alice", nil, { onlineID = 3 })
    local dtUUID = CoreIdentity.GetCharacterUUID(mpPlayer)
    local dtKey = CoreIdentity.GetTargetKey(mpPlayer)

    T.truthy(dtUUID and string.match(dtUUID, "^char_"), "Core generated valid MP UUID")
    T.equal(dtKey, "player:Survivor_Alice:" .. dtUUID, "Core canonical MP key is player:account:<uuid>")

    -- Step 2: Project Hoomans runs EnsureIdentity
    local hUUID, reason = PNC.PlayerCharacters.EnsureIdentity(mpPlayer)
    local hKey = PNC.PlayerCharacters.GetEntityKey(mpPlayer)

    T.equal(hUUID, dtUUID, "Hoomans adopted exact same MP UUID")
    T.equal(reason, "core_adopted", "EnsureIdentity returned core_adopted")
    T.equal(hKey, dtKey, "Hoomans GetEntityKey matches exact Core MP key")

    isServer = isServerOrig
    isClient = isClientOrig
end

print("=== Test 3: Reconnect Online ID Change Stability ===")
do
    local isServerOrig = isServer
    local isClientOrig = isClient
    isServer = function() return true end
    isClient = function() return false end

    -- Simulate player reconnecting: onlineID changes from 3 to 99
    local reconnectedPlayer, modData = makePlayer("Survivor_Alice", nil, { onlineID = 99 })
    -- Put persisted modData back
    local origUUID = CoreIdentity.GetCharacterUUID(reconnectedPlayer)
    local origKey = CoreIdentity.GetTargetKey(reconnectedPlayer)

    local hUUID, reason = PNC.PlayerCharacters.EnsureIdentity(reconnectedPlayer)
    local hKey = PNC.PlayerCharacters.GetEntityKey(reconnectedPlayer)

    T.equal(hUUID, origUUID, "Reconnected player retains same UUID")
    T.equal(hKey, origKey, "Reconnected player retains same canonical target key")

    isServer = isServerOrig
    isClient = isClientOrig
end

print("=== Test 4: Security — Arbitrary Untrusted Claim Rejected ===")
do
    resetHoomansRegistry()
    local isServerOrig = isServer
    isServer = function() return true end

    -- Player with arbitrary untrusted modData claim (no Core provenance signature)
    local untrustedPlayer, modData = makePlayer("Eve", nil, { onlineID = 10 })
    modData.PNC_CharacterUUID = "char_arbitrary_untrusted_123"

    local claimValid, claimReason = PNC.PlayerCharacters.ValidateClaim(untrustedPlayer, "char_arbitrary_untrusted_123")
    T.falsy(claimValid, "ValidateClaim rejected untrusted claim")
    T.equal(claimReason, "unknown_uuid", "ValidateClaim reported unknown_uuid")

    local hUUID, reason = PNC.PlayerCharacters.EnsureIdentity(untrustedPlayer)
    T.falsy(hUUID == "char_arbitrary_untrusted_123", "Untrusted claim was NOT adopted")
    T.equal(reason, "new_identity", "Untrusted claim resulted in fresh new identity generation")
    T.truthy(PNC.PlayerCharacters.Registry.byUUID[hUUID], "New valid identity registered")

    isServer = isServerOrig
end

print("=== Test 5: Security — Cross-Account Spoofed Claim Rejected ===")
do
    resetHoomansRegistry()
    local isServerOrig = isServer
    isServer = function() return true end

    -- Alice has a legitimate Core identity
    local alicePlayer, aliceData = makePlayer("Alice", nil, { onlineID = 11 })
    local aliceUUID = CoreIdentity.GetCharacterUUID(alicePlayer)

    -- Eve steals Alice's modData and attempts to use it under account 'Eve'
    local evePlayer, eveData = makePlayer("Eve", nil, { onlineID = 12 })
    eveData.Core_CharacterUUID = aliceData.Core_CharacterUUID
    eveData.PNC_CharacterUUID = aliceData.PNC_CharacterUUID
    eveData.Core_CharacterAccountKey = aliceData.Core_CharacterAccountKey
    eveData.Core_CharacterSignature = aliceData.Core_CharacterSignature

    local hUUID, reason = PNC.PlayerCharacters.EnsureIdentity(evePlayer)
    T.falsy(hUUID == aliceUUID, "Cross-account stolen UUID was NOT adopted by Eve")
    T.equal(reason, "new_identity", "Cross-account claim rejected, fresh identity created")

    isServer = isServerOrig
end

print("=== Test 6: Repeated Enable / Idempotent Adoption ===")
do
    resetHoomansRegistry()
    local isServerOrig = isServer
    isServer = function() return false end
    isClient = function() return false end

    local player, modData = makePlayer("Survivor", nil, { playerNum = 0 })
    local dtUUID = CoreIdentity.GetCharacterUUID(player)
    local dtKey = CoreIdentity.GetTargetKey(player)

    -- First load/adoption
    local hUUID1, reason1 = PNC.PlayerCharacters.EnsureIdentity(player)
    T.equal(hUUID1, dtUUID, "First adoption matches Core UUID")
    T.equal(reason1, "core_adopted", "First adoption is core_adopted")

    -- Second load (simulate immediate second call on live instance)
    local hUUID2, reason2 = PNC.PlayerCharacters.EnsureIdentity(player)
    T.equal(hUUID2, dtUUID, "Second call retains same UUID")
    T.equal(reason2, "reused", "Second call reuses runtime binding")

    -- Clear runtime binding to simulate fresh server restart reading registry
    PNC.PlayerCharacters.RuntimeByPlayer = setmetatable({}, { __mode = "k" })
    PNC.PlayerCharacters.RuntimeByUUID = {}

    local hUUID3, reason3 = PNC.PlayerCharacters.EnsureIdentity(player)
    local hKey3 = PNC.PlayerCharacters.GetEntityKey(player)
    T.equal(hUUID3, dtUUID, "Post-restart call retains same UUID")
    T.equal(reason3, "reused", "Post-restart call validates registered claim and reuses")
    T.equal(hKey3, dtKey, "Key remains strictly identical")

    isServer = isServerOrig
    isClient = isClientOrig
end

print("pnc_core_player_identity_adoption_smoke: PASS")
