require "ISUI/ISUIElement"

PNC = PNC or {}
PNC.Nameplates = PNC.Nameplates or {}

local Nameplates = PNC.Nameplates
local Core = PNC.Core
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

Nameplates.Settings = Nameplates.Settings or {
    enabled = true,
    showAIDebug = false,
}
Nameplates.State = Nameplates.State or {
    managers = {},
}

local Settings = Nameplates.Settings
local State = Nameplates.State

local BAR_WIDTH = 60
local BAR_HEIGHT = 6
local PADDING = 2
local MAX_DRAW_DISTANCE = 22
local FLOOR_TOLERANCE = 1
local HEART_ICON_SIZE = 16
local HEART_ICON_GAP = 2
local HEART_TEXTURE_PATH = "media/ui/Moodle_internal_plus_red.png"
local NAME_Y_OFFSET = 152
local BAR_Y_OFFSET = 130
local HP_TEXT_TOP_GAP = 12
local DEBUG_TEXT_GAP = 14
local NAME_DEBUG_GAP = 16
local FONT_NAME = UIFont.Small
local FONT_HP = UIFont.Medium
local FONT_DEBUG = UIFont.Small
local UPDATE_RATE = 6
local SYNTH_FRAMES = {
    Walk = 24,
    Run = 20,
    SneakWalk = 24,
    Crawl = 20,
    Idle = 16,
}
local SYNTH_CYCLE_MS = {
    Walk = 900,
    Run = 720,
    SneakWalk = 1100,
    Crawl = 1300,
    Idle = 1500,
}

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function calculateDistance(a, b)
    local dx
    local dy
    if not a or not b then
        return 9999
    end
    dx = a:getX() - b:getX()
    dy = a:getY() - b:getY()
    return math.sqrt((dx * dx) + (dy * dy))
end

local function getHealthRatio(current, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or 1)
    return clamp((tonumber(current) or 0) / safeMax, 0, 1)
end

local function getStaminaRatio(current, maxValue)
    local safeMax = math.max(1, tonumber(maxValue) or 1)
    return clamp((tonumber(current) or 0) / safeMax, 0, 1)
end

local function getColorForRatio(ratio)
    if ratio >= 0.7 then
        return { r = 0.1, g = 0.75, b = 0.15, a = 1 }
    end
    if ratio >= 0.35 then
        return { r = 0.95, g = 0.8, b = 0.1, a = 1 }
    end
    return { r = 0.8, g = 0.15, b = 0.15, a = 1 }
end

local function getIncapacitatedBarColor(currentTime)
    local pulse = (math.sin(currentTime / 140) + 1) * 0.5
    return {
        r = 0.35 + (0.2 * pulse),
        g = 0.03 + (0.04 * pulse),
        b = 0.03 + (0.04 * pulse),
        a = 0.8 + (0.2 * pulse),
    }
end

local function getHeartTexture()
    local texture
    if State.heartTexture ~= nil then
        return State.heartTexture or nil
    end
    texture = getTexture(HEART_TEXTURE_PATH) or getTexture("heart_on")
    State.heartTexture = texture or false
    return texture
end

local function shouldShowHealth(snapshot, currentTime)
    if not snapshot then
        return false
    end
    if tostring(snapshot.healthState or "") == "incapacitated" then
        return true
    end
    if snapshot.inCombat == true then
        return true
    end
    return (tonumber(snapshot.recentDamageUntil) or 0) > currentTime
end

local function shouldShowStamina(snapshot, currentTime)
    local ratio
    if not snapshot then
        return false
    end
    if tostring(snapshot.healthState or "") == "incapacitated" then
        return true
    end
    if snapshot.inCombat == true then
        return true
    end
    if (tonumber(snapshot.staminaVisibleUntil) or 0) > currentTime then
        return true
    end
    ratio = getStaminaRatio(snapshot.staminaCurrent, snapshot.staminaMax)
    return ratio < 0.999
end

local function getStaminaColor(ratio)
    if ratio >= 0.7 then
        return { r = 0.24, g = 0.55, b = 0.98, a = 1.0 }
    end
    if ratio >= 0.35 then
        return { r = 0.92, g = 0.72, b = 0.14, a = 1.0 }
    end
    return { r = 0.88, g = 0.26, b = 0.18, a = 1.0 }
end

local function buildDebugText(snapshot, hasBoundBody)
    local debugState = snapshot and snapshot.debugState or nil
    local presence
    if not debugState then
        return "AI: Unknown"
    end
    presence = string.upper(tostring(snapshot.presenceState or "unknown"))
    if snapshot.presenceState == Const.PRESENCE_LIVE then
        presence = presence .. "/" .. (hasBoundBody and "BOUND" or "MISSING")
    end
    return table.concat({
        "Presence: " .. presence,
        "AI: " .. tostring(debugState.aiState or snapshot.aiState or "Unknown"),
        "Job: " .. tostring(debugState.activeJob or "-"),
        "Order: " .. tostring(debugState.orderKind or "-"),
        "Target: " .. tostring(debugState.targetKind or "none"),
        "Mode: " .. tostring(debugState.combatModeResolved or debugState.weaponMode or "-"),
        "Weapon: " .. tostring(debugState.weaponStatus or "-"),
        "Stamina: " .. tostring(debugState.staminaState or snapshot.staminaState or "-"),
        "Block: " .. tostring(debugState.combatBlockReason or "-"),
    }, " | ")
end

local function getSyntheticAnimFrame(zombie, animName, moving, animSpeed)
    local modData
    local now
    local cycleMs
    local frameCount
    local key
    local elapsed
    local phase
    if not zombie then
        return nil, nil, nil
    end
    animName = tostring(animName or "Idle")
    frameCount = SYNTH_FRAMES[animName] or nil
    cycleMs = SYNTH_CYCLE_MS[animName] or nil
    if not frameCount or not cycleMs then
        return nil, nil, nil
    end
    modData = zombie.getModData and zombie:getModData() or nil
    now = PNC and PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    key = table.concat({
        animName,
        tostring(moving == true),
        string.format("%.3f", tonumber(animSpeed) or 0),
    }, "|")
    if modData then
        if modData.PNC_DebugAnimCycleKey ~= key then
            modData.PNC_DebugAnimCycleKey = key
            modData.PNC_DebugAnimCycleStartAt = now
        end
        now = tonumber(now) or 0
        elapsed = math.max(0, now - (tonumber(modData.PNC_DebugAnimCycleStartAt) or now))
    else
        elapsed = 0
    end
    phase = frameCount <= 1 and 0 or ((elapsed * math.max(0.05, tonumber(animSpeed) or 0)) % cycleMs) / cycleMs
    return math.max(0, math.min(frameCount - 1, math.floor((phase * frameCount) + 0.0001))), frameCount, phase
end

local function getAnimationDebug(zombie, snapshot)
    local parts = {}
    local animName
    local moveAnim
    local moving
    local actionState
    local walkTypeVar
    local engineWalkType
    local animSpeed
    local frameIndex
    local frameCount
    local phase
    if not zombie then
        return "Anim: n/a"
    end
    animName = tostring(snapshot and snapshot.visualState and snapshot.visualState.anim or zombie.getVariableString and zombie:getVariableString("PNCAnim") or "-")
    moveAnim = tostring(zombie.getVariableString and zombie:getVariableString("PNCMoveAnim") or "-")
    moving = zombie.isMoving and zombie:isMoving() or zombie.getVariableBoolean and zombie:getVariableBoolean("bMoving") or false
    actionState = tostring(zombie.getActionStateName and zombie:getActionStateName() or zombie.getCurrentStateName and zombie:getCurrentStateName() or "-")
    walkTypeVar = tostring(zombie.getVariableString and zombie:getVariableString("WalkType") or "")
    engineWalkType = tostring(zombie.getVariableString and zombie:getVariableString("PNCEngineWalkType") or "")
    animSpeed = tonumber(zombie.getVariableFloat and zombie:getVariableFloat("PNCAnimSpeed", 0.0) or 0.0) or 0.0
    parts[#parts + 1] = "Anim: " .. animName
    parts[#parts + 1] = "MoveAnim: " .. moveAnim
    parts[#parts + 1] = "Moving: " .. tostring(moving)
    parts[#parts + 1] = "Action: " .. actionState
    parts[#parts + 1] = "WalkVar: " .. walkTypeVar
    parts[#parts + 1] = "EngineWalk: " .. engineWalkType
    parts[#parts + 1] = string.format("AnimSpd: %.2f", animSpeed)
    frameIndex, frameCount, phase = getSyntheticAnimFrame(zombie, moveAnim ~= "" and moveAnim or animName, moving == true, animSpeed)
    if frameIndex ~= nil and frameCount ~= nil then
        parts[#parts + 1] = "Frame~: " .. tostring(frameIndex) .. "/" .. tostring(frameCount)
    elseif phase ~= nil then
        parts[#parts + 1] = string.format("Cycle: %.2f", tonumber(phase) or 0)
    else
        parts[#parts + 1] = "Frame~: n/a"
    end
    return table.concat(parts, " | ")
end

local function getNameColor(snapshot)
    if snapshot and snapshot.faction == "hostile" then
        return { r = 1.0, g = 0.28, b = 0.28, a = 1.0 }
    end
    return { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
end

local function cacheEntryMetrics(entry, snapshot, zombie)
    local textManager = getTextManager()
    local name = snapshot and snapshot.name or "PNC NPC"
    local hpText
    local debugText

    if entry.name ~= name then
        entry.name = name
        entry.nameWidth = textManager:MeasureStringX(FONT_NAME, name)
    elseif not entry.nameWidth then
        entry.nameWidth = textManager:MeasureStringX(FONT_NAME, name)
    end

    hpText = "[" .. tostring(math.floor((tonumber(snapshot.hpCurrent) or 0) + 0.5))
        .. "/" .. tostring(math.floor((tonumber(snapshot.hpMax) or 0) + 0.5)) .. "]"
    if entry.hpText ~= hpText then
        entry.hpText = hpText
        entry.hpTextWidth = textManager:MeasureStringX(FONT_HP, hpText)
    elseif not entry.hpTextWidth then
        entry.hpTextWidth = textManager:MeasureStringX(FONT_HP, hpText)
    end

    debugText = buildDebugText(snapshot, zombie ~= nil)
    if Settings.showAIDebug then
        debugText = debugText .. " | " .. getAnimationDebug(zombie, snapshot)
    end
    if entry.debugText ~= debugText then
        entry.debugText = debugText
        entry.debugTextWidth = textManager:MeasureStringX(FONT_DEBUG, debugText)
    elseif not entry.debugTextWidth then
        entry.debugTextWidth = textManager:MeasureStringX(FONT_DEBUG, debugText)
    end
end

local function drawOutlinedText(manager, text, x, y, r, g, b, a, font)
    local outlineAlpha
    if not text or text == "" then
        return
    end
    outlineAlpha = math.min(1, (a or 1) * 0.95)
    manager:drawText(text, x - 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x + 1, y, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y - 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y + 1, 0, 0, 0, outlineAlpha, font)
    manager:drawText(text, x, y, r, g, b, a, font)
end

ISPNCNameplateManager = ISUIElement:derive("ISPNCNameplateManager")

function ISPNCNameplateManager:initialise()
    ISUIElement.initialise(self)
end

function ISPNCNameplateManager:prerender()
    self:setStencilRect(0, 0, self.renderWidth, self.renderHeight)
end

function ISPNCNameplateManager:new(playerIndex, player)
    local x = getPlayerScreenLeft(playerIndex)
    local y = getPlayerScreenTop(playerIndex)
    local width = getPlayerScreenWidth(playerIndex)
    local height = getPlayerScreenHeight(playerIndex)
    local o = ISUIElement:new(x, y, width, height)

    setmetatable(o, self)
    self.__index = self

    o.playerIndex = playerIndex
    o.player = player
    o.active = true
    o.renderWidth = width
    o.renderHeight = height
    o.entries = {}
    o.updateCounter = 0
    o:setCapture(false)

    return o
end

function ISPNCNameplateManager:update()
    local zombieList
    local bodyByID = {}
    local bodyByLease = {}
    local bodyByOnlineID = {}
    local bodyByInstanceID = {}
    local currentTime
    local player
    local uuid
    local snapshot
    local i
    local zombie
    local modData
    local instanceID
    local alive
    local entry
    local visible = {}

    self:setX(getPlayerScreenLeft(self.playerIndex))
    self:setY(getPlayerScreenTop(self.playerIndex))
    self.renderWidth = getPlayerScreenWidth(self.playerIndex)
    self.renderHeight = getPlayerScreenHeight(self.playerIndex)
    self:setWidth(self.renderWidth)
    self:setHeight(self.renderHeight)

    self.player = getSpecificPlayer(self.playerIndex)
    player = self.player
    if not player or not Settings.enabled or not getCell then
        self.entries = {}
        return
    end

    self.updateCounter = (self.updateCounter or 0) + 1
    if self.updateCounter < UPDATE_RATE then
        return
    end
    self.updateCounter = 0

    zombieList = getCell():getZombieList()
    currentTime = getTimeInMillis()
    if not zombieList then
        self.entries = {}
        return
    end

    for i = 0, zombieList:size() - 1 do
        zombie = zombieList:get(i)
        if zombie and not zombie:isDead() and zombie.getModData then
            modData = zombie:getModData()
            uuid = modData and modData.PNC_UUID or nil
            if uuid then
                uuid = tostring(uuid)
                if bodyByID[uuid] ~= nil and bodyByID[uuid] ~= zombie then
                    bodyByID[uuid] = false
                elseif bodyByID[uuid] == nil then
                    bodyByID[uuid] = zombie
                end
                if modData.PNC_BodyLease then
                    local leaseKey = uuid .. ":" .. tostring(modData.PNC_BodyLease)
                    if bodyByLease[leaseKey] ~= nil and bodyByLease[leaseKey] ~= zombie then
                        bodyByLease[leaseKey] = false
                    elseif bodyByLease[leaseKey] == nil then
                        bodyByLease[leaseKey] = zombie
                    end
                end
            end
            local onlineID = PNC.Network and PNC.Network.GetZombieOnlineID
                and PNC.Network.GetZombieOnlineID(zombie) or nil
            if onlineID ~= nil then
                bodyByOnlineID[tostring(onlineID)] = zombie
            end
            instanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
            if instanceID ~= nil then
                instanceID = tostring(instanceID)
                if bodyByInstanceID[instanceID] ~= nil and bodyByInstanceID[instanceID] ~= zombie then
                    bodyByInstanceID[instanceID] = false
                elseif bodyByInstanceID[instanceID] == nil then
                    bodyByInstanceID[instanceID] = zombie
                end
            end
        end
    end

    for uuid, snapshot in pairs(ClientState.snapshots or {}) do
        zombie = bodyByOnlineID[tostring(snapshot and snapshot.liveBodyOnlineID or "")]
        if not zombie and snapshot and snapshot.liveBodyLease then
            zombie = bodyByLease[tostring(uuid) .. ":" .. tostring(snapshot.liveBodyLease)]
        end
        if not zombie and snapshot and not snapshot.liveBodyLease then
            zombie = bodyByID[tostring(uuid)]
        end
        zombie = zombie or bodyByInstanceID[tostring(snapshot and snapshot.liveBodyInstanceID or "")]
        alive = snapshot and snapshot.alive ~= false and snapshot.presenceState == Const.PRESENCE_LIVE
        if zombie and alive then
            modData = zombie.getModData and zombie:getModData() or nil
            if modData then
                modData.PNC_UUID = tostring(uuid)
                modData.PNC_NPC = true
                modData.PNC_LiveBodyInstanceID = snapshot.liveBodyInstanceID
                modData.PNC_LiveBodyOnlineID = snapshot.liveBodyOnlineID
                modData.PNC_BodyKind = "live"
                modData.PNC_BodyLease = snapshot.liveBodyLease
                modData.PNC_TagVersion = Const.BODY_TAG_VERSION
            end
            if math.abs(player:getZ() - zombie:getZ()) <= FLOOR_TOLERANCE
                and calculateDistance(player, zombie) <= MAX_DRAW_DISTANCE
            then
                entry = self.entries[uuid] or { uuid = uuid }
                entry.snapshot = snapshot
                entry.zombie = zombie
                entry.debugOnly = false
                entry.healthRatio = getHealthRatio(snapshot.hpCurrent, snapshot.hpMax)
                entry.nameColor = getNameColor(snapshot)
                entry.healthVisible = shouldShowHealth(snapshot, currentTime)
                entry.staminaVisible = shouldShowStamina(snapshot, currentTime)
                entry.staminaRatio = getStaminaRatio(snapshot.staminaCurrent, snapshot.staminaMax)
                entry.staminaColor = getStaminaColor(entry.staminaRatio)
                entry.barColor = snapshot.healthState == "incapacitated"
                    and getIncapacitatedBarColor(currentTime)
                    or getColorForRatio(entry.healthRatio)
                cacheEntryMetrics(entry, snapshot, zombie)
                self.entries[uuid] = entry
                visible[uuid] = true
            end
        elseif Settings.showAIDebug and snapshot
            and math.abs(player:getZ() - (tonumber(snapshot.z) or 0)) <= FLOOR_TOLERANCE
            and Core.Distance(player:getX(), player:getY(), tonumber(snapshot.x) or 0, tonumber(snapshot.y) or 0) <= MAX_DRAW_DISTANCE
        then
            entry = self.entries[uuid] or { uuid = uuid }
            entry.snapshot = snapshot
            entry.zombie = nil
            entry.debugOnly = true
            entry.worldX = tonumber(snapshot.x) or 0
            entry.worldY = tonumber(snapshot.y) or 0
            entry.worldZ = tonumber(snapshot.z) or 0
            entry.nameColor = getNameColor(snapshot)
            cacheEntryMetrics(entry, snapshot, nil)
            self.entries[uuid] = entry
            visible[uuid] = true
        end
    end

    for uuid, _ in pairs(self.entries) do
        if not visible[uuid] then
            self.entries[uuid] = nil
        end
    end
end

function ISPNCNameplateManager:render()
    local zoom
    local scaleDivisor
    local barWidth
    local barHeight
    local nameYOffset
    local barYOffset
    local heartIconSize
    local heartGap
    local currentTime
    local uuid
    local entry
    local zombie
    local alpha
    local screenX
    local screenY
    local barLeft
    local barTop
    local heartIcon
    local totalCounterWidth
    local counterX
    local counterY
    local hpR
    local hpG
    local hpB
    local debugY
    local staminaTop

    if not Settings.enabled or not self.player then
        self:clearStencilRect()
        return
    end

    zoom = getCore():getZoom(self.playerIndex)
    if zoom <= 0 then
        zoom = 1
    end
    scaleDivisor = zoom > 1 and (zoom * 1.15) or 1
    barWidth = BAR_WIDTH / scaleDivisor
    barHeight = BAR_HEIGHT / scaleDivisor
    heartIconSize = HEART_ICON_SIZE / scaleDivisor
    heartGap = HEART_ICON_GAP / scaleDivisor
    nameYOffset = NAME_Y_OFFSET / zoom
    barYOffset = BAR_Y_OFFSET / zoom
    heartIcon = getHeartTexture()
    currentTime = getTimeInMillis()

    for uuid, entry in pairs(self.entries) do
        zombie = entry.zombie
        if entry.debugOnly then
            screenX = isoToScreenX(self.playerIndex, entry.worldX, entry.worldY, entry.worldZ) - self.x
            screenY = isoToScreenY(self.playerIndex, entry.worldX, entry.worldY, entry.worldZ) - self.y
            drawOutlinedText(
                self,
                entry.name,
                screenX - ((entry.nameWidth or 0) / 2),
                screenY - nameYOffset,
                entry.nameColor.r,
                entry.nameColor.g,
                entry.nameColor.b,
                0.9,
                FONT_NAME
            )
            drawOutlinedText(
                self,
                entry.debugText,
                screenX - ((entry.debugTextWidth or 0) / 2),
                (screenY - nameYOffset) + NAME_DEBUG_GAP,
                0.8,
                0.9,
                1.0,
                0.9,
                FONT_DEBUG
            )
        elseif zombie and not zombie:isDead() then
            alpha = zombie.getAlpha and zombie:getAlpha(self.playerIndex) or 1
            if alpha > 0 then
                screenX = isoToScreenX(self.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()) - self.x
                screenY = isoToScreenY(self.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()) - self.y
                barLeft = screenX - (barWidth / 2)
                barTop = screenY - barYOffset

                if entry.snapshot.healthState == "incapacitated" then
                    entry.barColor = getIncapacitatedBarColor(currentTime)
                end

                drawOutlinedText(
                    self,
                    entry.name,
                    screenX - ((entry.nameWidth or 0) / 2),
                    screenY - nameYOffset,
                    entry.nameColor.r,
                    entry.nameColor.g,
                    entry.nameColor.b,
                    entry.nameColor.a * alpha,
                    FONT_NAME
                )

                if entry.healthVisible then
                    self:drawRect(
                        barLeft - PADDING,
                        barTop - PADDING,
                        barWidth + (PADDING * 2),
                        barHeight + (PADDING * 2),
                        0.55 * alpha,
                        0,
                        0,
                        0
                    )
                    self:drawRect(
                        barLeft,
                        barTop,
                        barWidth * entry.healthRatio,
                        barHeight,
                        entry.barColor.a * alpha,
                        entry.barColor.r,
                        entry.barColor.g,
                        entry.barColor.b
                    )
                    self:drawRectBorder(
                        barLeft - PADDING,
                        barTop - PADDING,
                        barWidth + (PADDING * 2),
                        barHeight + (PADDING * 2),
                        alpha,
                        math.min(1, entry.barColor.r + 0.08),
                        math.min(1, entry.barColor.g + 0.08),
                        math.min(1, entry.barColor.b + 0.08)
                    )

                    totalCounterWidth = heartIconSize + heartGap + (entry.hpTextWidth or 0)
                    counterX = screenX - (totalCounterWidth / 2)
                    counterY = barTop - (HP_TEXT_TOP_GAP / zoom)

                    if heartIcon then
                        self:drawTextureScaled(
                            heartIcon,
                            counterX,
                            counterY + (2 / zoom),
                            heartIconSize,
                            heartIconSize,
                            alpha,
                            1,
                            1,
                            1
                        )
                    end

                    hpR = 0.1
                    hpG = 0.8
                    hpB = 0.1
                    if entry.healthRatio < 0.25 then
                        hpR = 0.8
                        hpG = 0.1
                        hpB = 0.1
                    elseif entry.healthRatio < 0.6 then
                        hpR = 0.8
                        hpG = 0.8
                        hpB = 0.1
                    end

                    drawOutlinedText(
                        self,
                        entry.hpText,
                        counterX + heartIconSize + heartGap,
                        counterY,
                        hpR,
                        hpG,
                        hpB,
                        alpha,
                        FONT_HP
                    )
                end

                if entry.staminaVisible then
                    staminaTop = entry.healthVisible and (barTop + barHeight + (6 / zoom)) or barTop
                    self:drawRect(
                        barLeft - PADDING,
                        staminaTop - PADDING,
                        barWidth + (PADDING * 2),
                        barHeight + (PADDING * 2),
                        0.48 * alpha,
                        0,
                        0,
                        0
                    )
                    self:drawRect(
                        barLeft,
                        staminaTop,
                        barWidth * entry.staminaRatio,
                        barHeight,
                        entry.staminaColor.a * alpha,
                        entry.staminaColor.r,
                        entry.staminaColor.g,
                        entry.staminaColor.b
                    )
                    self:drawRectBorder(
                        barLeft - PADDING,
                        staminaTop - PADDING,
                        barWidth + (PADDING * 2),
                        barHeight + (PADDING * 2),
                        alpha,
                        math.min(1, entry.staminaColor.r + 0.08),
                        math.min(1, entry.staminaColor.g + 0.08),
                        math.min(1, entry.staminaColor.b + 0.08)
                    )
                end

                if Settings.showAIDebug then
                    if entry.staminaVisible then
                        debugY = (entry.healthVisible and staminaTop or barTop) + barHeight + DEBUG_TEXT_GAP
                    elseif entry.healthVisible then
                        debugY = barTop + barHeight + DEBUG_TEXT_GAP
                    else
                        debugY = (screenY - nameYOffset) + NAME_DEBUG_GAP
                    end
                    drawOutlinedText(
                        self,
                        entry.debugText,
                        screenX - ((entry.debugTextWidth or 0) / 2),
                        debugY,
                        0.8,
                        0.9,
                        1.0,
                        0.95 * alpha,
                        FONT_DEBUG
                    )
                end
            end
        end
    end

    self:clearStencilRect()
end

function Nameplates.IsDebugEnabled()
    return Settings.showAIDebug == true
end

function Nameplates.ToggleDebug()
    local player = getSpecificPlayer(0)
    Settings.showAIDebug = not Settings.showAIDebug
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.debugEnabled = Settings.showAIDebug == true
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, "PNC AI Overlay: " .. (Settings.showAIDebug and "ON" or "OFF"))
    end
    return Settings.showAIDebug
end

function Nameplates.DebugDescribeSnapshot(snapshot)
    if not snapshot then
        return "No snapshot"
    end
    return table.concat({
        "id=" .. tostring(snapshot.id),
        "name=" .. tostring(snapshot.name),
        "archetype=" .. tostring(snapshot.archetypeLabel or "-"),
        "ai=" .. tostring(snapshot.aiState),
        "job=" .. tostring(snapshot.debugState and snapshot.debugState.activeJob or "-"),
        "order=" .. tostring(snapshot.debugState and snapshot.debugState.orderKind or "-"),
        "target=" .. tostring(snapshot.debugState and snapshot.debugState.targetKind or "none"),
        "mode=" .. tostring(snapshot.debugState and snapshot.debugState.combatModeResolved or snapshot.weaponMode or "-"),
        "weapon=" .. tostring(snapshot.debugState and snapshot.debugState.weaponStatus or "-"),
        "block=" .. tostring(snapshot.debugState and snapshot.debugState.combatBlockReason or "-"),
        "hp=" .. tostring(snapshot.hpCurrent) .. "/" .. tostring(snapshot.hpMax),
        "stamina=" .. tostring(snapshot.staminaCurrent) .. "/" .. tostring(snapshot.staminaMax),
        "healthState=" .. tostring(snapshot.healthState),
        "presence=" .. tostring(snapshot.presenceState),
    }, " | ")
end

local function initForPlayer(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    local manager
    if not player then
        return
    end
    if State.managers[playerIndex] then
        return
    end
    manager = ISPNCNameplateManager:new(playerIndex, player)
    manager:initialise()
    State.managers[playerIndex] = manager
end

local function onCreatePlayer(playerIndex)
    initForPlayer(playerIndex)
end

local function onGameStart()
    local i
    for i = 0, getNumActivePlayers() - 1 do
        initForPlayer(i)
    end
end

local function onPreUIDraw()
    local _
    local manager
    if isIngameState and not isIngameState() then
        return
    end
    for _, manager in pairs(State.managers) do
        if manager and manager.active then
            manager:update()
            manager:prerender()
            manager:render()
        end
    end
end

local function onResetLua()
    State.managers = {}
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnGameStart.Add(onGameStart)
if Events and Events.OnPreUIDraw then
    Events.OnPreUIDraw.Add(onPreUIDraw)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
