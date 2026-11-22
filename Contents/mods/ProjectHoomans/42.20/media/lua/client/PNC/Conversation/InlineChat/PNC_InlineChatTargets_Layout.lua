-- World-to-screen panel placement for inline chat.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local State = InlineChat.State
local Targets = Internal.Targets or {}
Internal.Targets = Targets

local function screenBounds(playerIndex)
    local core = getCore and getCore() or nil
    local width = core and core.getScreenWidth and core:getScreenWidth() or 1920
    local height = core and core.getScreenHeight and core:getScreenHeight() or 1080
    local left = getPlayerScreenLeft and getPlayerScreenLeft(playerIndex) or 0
    local top = getPlayerScreenTop and getPlayerScreenTop(playerIndex) or 0
    local playerW = getPlayerScreenWidth and getPlayerScreenWidth(playerIndex) or width
    local playerH = getPlayerScreenHeight and getPlayerScreenHeight(playerIndex) or height
    return left, top, left + playerW, top + playerH
end

function Targets.Position(playerIndex, player)
    local part = State.part
    if not part or not player or not isoToScreenX or not isoToScreenY then return false end
    if not player.getX or not player.getY or not player.getZ then return false end
    local sx = isoToScreenX(playerIndex, player:getX(), player:getY(), player:getZ())
    local sy = isoToScreenY(playerIndex, player:getX(), player:getY(), player:getZ())
    local left, top, right, bottom = screenBounds(playerIndex)
    local width, height = part:getWidth(), part:getHeight()
    local targetX = sx - (width / 2)
    local targetY = sy + Config.PLAYER_Y_OFFSET
    part:setX(math.max(left, math.min(math.max(left, right - width), targetX)))
    part:setY(math.max(top, math.min(math.max(top, bottom - height), targetY)))
    return true
end

return Targets
