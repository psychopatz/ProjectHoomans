local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

local now = 1000
local discovered = false
local isClientOnly = false
local offTexture = { name = "off", getWidth = function() return 70 end, getHeight = function() return 39 end }
local onTexture = { name = "on", getWidth = function() return 70 end, getHeight = function() return 39 end }
getTexture = function(path)
    return string.find(path, "eyeconOn", 1, true) and onTexture or offTexture
end
isClient = function() return isClientOnly end

local player = {
    isDead = function() return false end,
    isSneaking = function() return true end,
    isRunning = function() return false end,
    isSprinting = function() return false end,
    getVehicle = function() return nil end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getAlpha = function() return 0.9 end,
}
local draws = {}
local manager = {
    player = player,
    playerIndex = 0,
    x = 100,
    y = 50,
    drawTextureScaled = function(_, texture, x, y, width, height, alpha)
        draws[#draws + 1] = {
            texture = texture, x = x, y = y,
            width = width, height = height, alpha = alpha,
        }
    end,
}

isoToScreenX = function() return 300 end
isoToScreenY = function() return 400 end

PNC = {
    Const = { STEALTH_INDICATOR_TIMEOUT_MS = 1500 },
    Core = { Now = function() return now end },
    Network = { ClientState = {} },
    Stealth = {
        IsOwnerActuallySneaking = function() return player:isSneaking() end,
        IsOwnerDiscovered = function()
            return discovered, discovered and "owner_seen" or "owner_hidden"
        end,
    },
}
PNC.Network.ClientState.snapshots = {
    follower = {
        alive = true,
        recruited = true,
        tacticalClass = "colonist",
        orderKind = "follow",
        ownerUsername = "local-player",
    },
}
player.getUsername = function() return "local-player" end

T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Nameplates/PNC_NameplateStealthIndicator.lua"
)

local indicator = PNC.NameplateStealthIndicator
PNC.Network.ClientState.snapshots = {}
T.equal(indicator.Render(manager, { showStealthIndicator = true }), false,
    "icon rendered without a colonist follower")
PNC.Network.ClientState.snapshots = {
    follower = {
        alive = true,
        recruited = true,
        tacticalClass = "colonist",
        orderKind = "follow",
        ownerUsername = "local-player",
    },
}
now = 1300
local visible = indicator.ResolveState(player, now)
T.equal(visible, false, "single-player hidden state")
T.equal(indicator.Render(manager, { showStealthIndicator = true }), true,
    "single-player icon did not render")
T.equal(draws[1].texture, offTexture, "hidden icon texture")
T.equal(draws[1].width, 70, "native icon width")

discovered = true
now = 1500
T.equal(indicator.Render(manager, { showStealthIndicator = true }), true,
    "discovered icon did not render")
T.equal(draws[2].texture, onTexture, "discovered icon texture")

player.isSneaking = function() return false end
T.equal(indicator.Render(manager, { showStealthIndicator = true }), false,
    "icon rendered while not sneaking")

player.isSneaking = function() return true end
isClientOnly = true
PNC.Network.ClientState.stealthDiscovery = {
    hasFollowingColonist = true,
    sneaking = true, discovered = true, revision = 1, expiresAt = 1200,
}
now = 1100
T.equal(indicator.ResolveState(player, now), true,
    "multiplayer server state was not used")
now = 1300
T.equal(indicator.Render(manager, { showStealthIndicator = true }), false,
    "expired multiplayer state remained visible")

T.finish("pnc_stealth_indicator_smoke")
