-- Firearm anchor target rendering and reset lifecycle.
local Anchor = PNC.NameplateFirearmAnchor
local Internal = Anchor.Internal
local facing = Internal.facing
local DEBUG_DIRECTION_LENGTH = Internal.DEBUG_DIRECTION_LENGTH
local ANCHOR_COLOR = Internal.ANCHOR_COLOR
local SHOULDER_COLOR = Internal.SHOULDER_COLOR
local DIRECTION_COLOR = Internal.DIRECTION_COLOR
local GROUND_COLOR = Internal.GROUND_COLOR

local function drawCross(manager, x, y, size, color)
    manager:drawLine2(
        x - size, y, x + size, y,
        color.a, color.r, color.g, color.b
    )
    manager:drawLine2(
        x, y - size, x, y + size,
        color.a, color.r, color.g, color.b
    )
end

local function directionScreen(body, id, playerIndex)
    local directionX
    local directionY
    local facingX
    local facingY
    directionX, directionY = Anchor.GetScreenDirection(body, id, playerIndex)
    facingX, facingY = facing(body)
    return directionX, directionY, facingX, facingY
end

local function rounded(value)
    value = tonumber(value)
    if not value then return "-" end
    return string.format("%.1f", value)
end

local function debugText(manager, text, x, y, color, font)
    local Presentation = PNC.NameplatePresentation
    if Presentation and Presentation.DrawOutlinedText then
        Presentation.DrawOutlinedText(manager, text, x, y, color, 1, font)
    else
        manager:drawText(text, x, y, color.r, color.g, color.b, 1, font)
    end
end

function Anchor.Render(manager, body, id, nameX, nameY, groundX, groundY,
    worldX, worldY, worldZ)
    local cache
    local core
    local zoom = 1
    local muzzleX
    local muzzleY
    local directionX
    local directionY
    local facingX
    local facingY
    local textX
    local textY
    local font
    if not manager or not body or not Anchor.IsTarget(body, id) then
        return false
    end

    cache = Anchor.Get(body, id)
    if not cache then
        core = getCore and getCore() or nil
        if core and type(core.getZoom) == "function" then
            zoom = tonumber(core:getZoom(manager.playerIndex)) or 1
        end
        cache = Anchor.Update(
            body,
            id,
            manager.playerIndex,
            manager.x,
            manager.y,
            zoom,
            nameX,
            nameY,
            groundX,
            groundY,
            worldX,
            worldY,
            worldZ
        )
    end
    muzzleX, muzzleY = Anchor.GetLocalMuzzle(cache)
    if not muzzleX or not muzzleY then return false end
    -- Use the exact cached starter point that the effects bridge resolves.
    -- This prevents a stale caller argument from making the probe line and
    -- the tracer appear to disagree by a frame while an NPC is moving.
    nameX = cache.nameX or nameX
    nameY = cache.nameY or nameY

    drawCross(manager, nameX, nameY, 7, ANCHOR_COLOR)
    drawCross(manager, groundX or nameX, groundY or nameY, 7, GROUND_COLOR)
    drawCross(manager, muzzleX, muzzleY, 9, SHOULDER_COLOR)
    manager:drawLine2(
        nameX,
        nameY,
        muzzleX,
        muzzleY,
        SHOULDER_COLOR.a,
        SHOULDER_COLOR.r,
        SHOULDER_COLOR.g,
        SHOULDER_COLOR.b
    )

    directionX, directionY, facingX, facingY = directionScreen(
        body,
        id,
        manager.playerIndex
    )
    manager:drawLine2(
        muzzleX,
        muzzleY,
        muzzleX + (directionX * DEBUG_DIRECTION_LENGTH),
        muzzleY + (directionY * DEBUG_DIRECTION_LENGTH),
        DIRECTION_COLOR.a,
        DIRECTION_COLOR.r,
        DIRECTION_COLOR.g,
        DIRECTION_COLOR.b
    )

    if Anchor.IsDebugTextVisible() then
        textX = muzzleX + 14
        textY = muzzleY - 48
        font = PNC.NameplatePresentation
            and PNC.NameplatePresentation.Fonts
            and PNC.NameplatePresentation.Fonts.debug or UIFont.Small
        debugText(manager, "FIREARM ANCHOR  " .. tostring(cache.id or "?"),
            textX, textY, SHOULDER_COLOR, font)
        debugText(manager,
            "nameplate=" .. rounded(nameX) .. "," .. rounded(nameY)
                .. "  shoulder=" .. rounded(muzzleX) .. "," .. rounded(muzzleY),
            textX, textY + 14, ANCHOR_COLOR, font)
        debugText(manager,
            "local F/S/H=" .. rounded(Anchor.Config.forwardOffset) .. "/"
                .. rounded(Anchor.Config.sideOffset) .. "/"
                .. rounded(Anchor.Config.heightOffset)
                .. "  world=" .. rounded(worldX) .. "," .. rounded(worldY)
                .. "," .. rounded(worldZ),
            textX, textY + 28, GROUND_COLOR, font)
        debugText(manager,
            "facing=" .. rounded(facingX) .. "," .. rounded(facingY)
                .. "  line=orange",
            textX, textY + 42, DIRECTION_COLOR, font)
    end
    return true
end

function Anchor.Reset()
    Anchor.CacheByID = {}
    Anchor.CacheByBody = {}
    Anchor.ProjectionByPlayer = {}
    Anchor.Target = nil
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Anchor.Reset)
end

return Anchor
