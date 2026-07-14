require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"

PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared
local Layout = PsychopatzCore.UI.Layout

function Tabs.CreateInfoChildren(view)
    view.portraitPanel = PsychopatzCore.UI.PortraitPanel:new(12, 12, 132, 264, {
        zoom = 14,
        yOffset = -0.85,
        direction = IsoDirections and IsoDirections.S,
        animSetName = "zombie",
        stateName = "idle",
        animate = true,
    })
    view.portraitPanel:initialise()
    view.portraitPanel:instantiate()
    view:addChild(view.portraitPanel)
end

function Tabs.SetInfoContext(view, snapshot, payload)
    local character = Shared.GetLiveCharacter(view.npcId)
    local spec = Shared.BuildPortraitSpec(view.npcId, snapshot, payload)
    if view.portraitPanel then view.portraitPanel:setTarget(character, spec) end
end

function Tabs.LayoutInfo(view)
    if not view.portraitPanel then return end
    local scale = PsychopatzCore.UI.Layout.Scale()
    local padding = Layout.Pixels(12, scale)
    local portraitWidth = Shared.Clamp(math.floor(view.width * 0.31), Layout.Pixels(118, scale), Layout.Pixels(170, scale))
    local portraitHeight = math.min(math.max(Layout.Pixels(230, scale), view.height - padding * 2), Layout.Pixels(310, scale))
    view.portraitPanel:setPortraitBounds(padding, padding, portraitWidth, portraitHeight)
    local character = Shared.GetLiveCharacter(view.npcId)
    local spec = Shared.BuildPortraitSpec(view.npcId, view.snapshot, view.payload)
    view.portraitPanel:setTarget(character, spec)
end

function Tabs.RenderInfo(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local data = Shared.GetCharacterData(snapshot, payload)
    local identity = Shared.GetIdentity(snapshot, payload)
    local survivor = identity.survivor or {}
    local carry = Shared.GetCarry(snapshot, payload)
    local equipment = Shared.GetEquipment(snapshot, payload)
    local appearance = resolved.appearance or {}
    local padding = 12
    local portraitRight = view.portraitPanel and view.portraitPanel:getRight() or math.floor(view.width * 0.33)
    local x = portraitRight + padding
    local width = math.max(100, view.width - x - padding)
    local labelWidth = math.min(112, math.floor(width * 0.42))
    local y = topY
    local name = data.displayName or resolved.displayName or resolved.name or "Unknown"
    local archetype = data.archetypeLabel or resolved.archetypeLabel or "Survivor"
    local hp = tostring(math.floor(tonumber(resolved.hpCurrent) or 0)) .. "/" .. tostring(math.floor(tonumber(resolved.hpMax) or 0))
    local stamina = tostring(math.floor(tonumber(resolved.staminaCurrent) or 0)) .. "/" .. tostring(math.floor(tonumber(resolved.staminaMax) or 0))
    local carryText = tostring(Shared.Round(carry.usedWeight or 0, 1)) .. "/" .. tostring(Shared.Round(carry.maxWeight or 0, 1))

    view:drawText(name, x, y, 1, 1, 1, 1, UIFont.Medium)
    view:drawTextRight(archetype, x + width, y + 2, 1, 1, 1, 1, UIFont.Small)
    y = y + (getTextManager():getFontHeight(UIFont.Medium) + 3)
    view:drawRect(x, y, width, 1, 0.8, 0.5, 0.5, 0.5)
    y = y + 14

    y = Shared.DrawLabelValue(view, "Faction", resolved.faction or "-", x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Status", resolved.aiState or resolved.activeBehavior or "Idle", x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Health", hp, x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Stamina", stamina, x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Carry Weight", carryText, x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Hair", appearance.hairModel or survivor.hairModel or "None", x, y, labelWidth)
    if resolved.isFemale ~= true then
        y = Shared.DrawLabelValue(view, "Beard", appearance.beardModel or survivor.beardModel or "None", x, y, labelWidth)
    end
    y = Shared.DrawLabelValue(view, "Weapon", equipment.primaryFullType or "Bare hands", x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Combat", resolved.combatModeResolved or resolved.weaponMode or "melee", x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Recruited", resolved.recruited == true and "Yes" or "No", x, y, labelWidth)
    y = Shared.DrawLabelValue(view, "Owner", data.ownerUsername or "-", x, y, labelWidth)

    local portraitBottom = view.portraitPanel and view.portraitPanel:getBottom() or y
    local footerY = math.max(y + 8, portraitBottom + 10)
    view:drawTextCentre("Inventory Items  " .. tostring(carry.itemCount or 0), view.width / 2, footerY, 0.82, 0.82, 0.82, 1, UIFont.Small)
    return footerY + getTextManager():getFontHeight(UIFont.Small) + 10
end

return Tabs
