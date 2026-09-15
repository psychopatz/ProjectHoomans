require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "ISUI/ISToolTip"

PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared
local Layout = PsychopatzCore.UI.Layout
local IdentityPresentation = PNC.NPCIdentityPresentation

-- Temporary shared artwork until the Project Hoomans trait icon set is
-- generated. Keep this fallback centralized so the generated paths can be
-- added without changing the trait presentation flow.
local TRAIT_ICON_PLACEHOLDER = "media/ui/Traits/trait_pnc_friendly.png"
local TRAIT_ICON_SIZE = 18

local function knowledgeSnapshot(npcID)
    local state = PNC.Network and PNC.Network.ClientState or nil
    return state and state.npcKnowledge and state.npcKnowledge[tostring(npcID)] or nil
end

local function traitEntries(npcID)
    local knowledge = knowledgeSnapshot(npcID)
    local entries = {}
    local seen = {}
    local known = false
    for _, category in ipairs(knowledge and knowledge.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            local presentation = descriptor.presentation or {}
            if presentation.topicID == "traits"
                and (presentation.traitSource == "npc"
                    or presentation.traitSource == "vanilla")
                and descriptor.value ~= nil
            then
                known = true
                if descriptor.value == true then
                    local rawTraitID = tostring(presentation.traitID or "")
                    local traitID = PNC.NPCTraits
                        and PNC.NPCTraits.NormalizeID
                        and PNC.NPCTraits.NormalizeID(rawTraitID)
                        or rawTraitID
                    local definition = PNC.NPCTraits
                        and PNC.NPCTraits.GetDefinition
                        and PNC.NPCTraits.GetDefinition(traitID) or nil
                    if not seen[traitID] then
                        local labelKey = definition and definition.labelKey
                            or presentation.labelKey
                        local descriptionKey = definition
                            and definition.descriptionKey
                            or presentation.descriptionKey
                        local label = Shared.TraitLabel(
                            traitID, definition, labelKey)
                        entries[#entries + 1] = {
                            id = traitID,
                            label = label,
                            description = Shared.TraitDescription(
                                traitID, definition, descriptionKey, label),
                            iconPath = definition and definition.iconPath
                                or presentation.iconPath
                                or TRAIT_ICON_PLACEHOLDER,
                        }
                        seen[traitID] = true
                    end
                end
            end
        end
    end
    table.sort(entries, function(left, right)
        return tostring(left.label) < tostring(right.label)
    end)
    return entries, known
end

local function loadTraitIcon(path)
    if type(path) ~= "string" or not getTexture then return nil end
    return getTexture(path)
end

local function drawTraitIcons(view, entries, x, y, availableWidth)
    if type(entries) ~= "table" or #entries == 0
        or availableWidth <= 0
    then
        return 0
    end
    local gap = 3
    local columns = math.max(1, math.floor(
        (availableWidth + gap) / (TRAIT_ICON_SIZE + gap)
    ))
    local drawn = 0
    local index
    view.traitIconHitboxes = {}
    for index = 1, #entries do
        local texture = loadTraitIcon(entries[index].iconPath)
        if not texture then
            texture = loadTraitIcon(TRAIT_ICON_PLACEHOLDER)
        end
        if texture then
            local column = drawn % columns
            local row = math.floor(drawn / columns)
            local iconX = x + column * (TRAIT_ICON_SIZE + gap)
            local iconY = y + row * (TRAIT_ICON_SIZE + gap)
            if view.drawTextureScaledAspect then
                view:drawTextureScaledAspect(
                    texture, iconX, iconY,
                    TRAIT_ICON_SIZE, TRAIT_ICON_SIZE, 1, 1, 1, 1
                )
            else
                view:drawTextureScaled(
                    texture, iconX, iconY,
                    TRAIT_ICON_SIZE, TRAIT_ICON_SIZE, 1, 1, 1, 1
                )
            end
            view.traitIconHitboxes[#view.traitIconHitboxes + 1] = {
                x = iconX, y = iconY,
                width = TRAIT_ICON_SIZE, height = TRAIT_ICON_SIZE,
                entry = entries[index],
            }
            drawn = drawn + 1
        end
    end
    if drawn == 0 then return 0 end
    return math.ceil(drawn / columns) * (TRAIT_ICON_SIZE + gap) - gap
end

local function hideTraitTooltip(view)
    local tooltip = view and view.traitTooltip or nil
    if tooltip and tooltip.getIsVisible and tooltip:getIsVisible() then
        tooltip:setVisible(false)
        tooltip:removeFromUIManager()
    end
    if view then
        view.traitTooltipEntryID = nil
    end
end

local function hoveredTrait(view, x, y)
    local hitboxes = view and view.traitIconHitboxes or {}
    local index
    local hitbox
    for index = #hitboxes, 1, -1 do
        hitbox = hitboxes[index]
        if x >= hitbox.x and x <= hitbox.x + hitbox.width
            and y >= hitbox.y and y <= hitbox.y + hitbox.height
        then
            return hitbox.entry
        end
    end
    return nil
end

local function updateTraitTooltip(view, x, y)
    -- ISUI passes movement deltas to onMouseMove, not absolute local
    -- coordinates. Hitboxes are drawn in the tab's local coordinate space.
    x = view and view.getMouseX and tonumber(view:getMouseX())
        or tonumber(x) or 0
    y = view and view.getMouseY and tonumber(view:getMouseY())
        or tonumber(y) or 0
    local entry = hoveredTrait(view, x, y)
    local text = entry and entry.description or nil
    if not text or not ISToolTip then
        hideTraitTooltip(view)
        return
    end
    if not view.traitTooltip then
        view.traitTooltip = ISToolTip:new()
        view.traitTooltip:setOwner(view)
        view.traitTooltip:setVisible(false)
        view.traitTooltip:setAlwaysOnTop(true)
        view.traitTooltip.maxLineWidth = 1000
    end
    if not view.traitTooltip:getIsVisible() then
        view.traitTooltip:addToUIManager()
        view.traitTooltip:setVisible(true)
    end
    if view.traitTooltip.setName then
        view.traitTooltip:setName(entry.label)
    end
    view.traitTooltip.description = text
    view.traitTooltipEntryID = tostring(entry.id or "")
    view.traitTooltip:setX(x + 23)
    view.traitTooltip:setY(y + 23)
end

function Tabs.CreateInfoChildren(view)
    view.portraitPanel = PsychopatzCore.UI.PortraitPanel:new(12, 12, 132, 264, {
        -- Match the vanilla player-info full-body preview. The NPC's live
        -- backing object is an IsoZombie, so use the descriptor's human pose.
        zoom = -3,
        yOffset = 0,
        direction = IsoDirections and IsoDirections.S,
        animSetName = false,
        stateName = "idle",
        animate = true,
    })
    view.portraitPanel:initialise()
    view.portraitPanel:instantiate()
    view:addChild(view.portraitPanel)
end

function Tabs.SetInfoContext(view, snapshot, payload)
    -- Live NPC data can refresh while the cursor remains over an icon. Do
    -- not close the tooltip for ordinary snapshot updates; RenderInfo will
    -- resolve the current hitbox and text again. A changed NPC is a real
    -- context switch and must discard the old tooltip.
    local contextID = tostring(view.npcId or "")
    if view.traitTooltipContextID
        and view.traitTooltipContextID ~= contextID
    then
        hideTraitTooltip(view)
    end
    view.traitTooltipContextID = contextID
    view.traitIconHitboxes = {}
    local character = Shared.GetLiveCharacter(view.npcId)
    local spec = Shared.BuildPortraitSpec(view.npcId, snapshot, payload)
    if view.portraitPanel then view.portraitPanel:setTarget(character, spec) end
end

function Tabs.OnInfoMouseMove(view, x, y)
    updateTraitTooltip(view, x, y)
    return true
end

function Tabs.OnInfoMouseMoveOutside(view)
    -- ISToolTip is top-level UI. Depending on event ordering, the tab can
    -- receive this callback while the cursor is still over the icon.
    local x = view and view.getMouseX and tonumber(view:getMouseX()) or nil
    local y = view and view.getMouseY and tonumber(view:getMouseY()) or nil
    if not hoveredTrait(view, x or 0, y or 0) then
        hideTraitTooltip(view)
    end
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
    local knownFaction = IdentityPresentation.GetFaction(view.npcId)
    local padding = 12
    local portraitRight = view.portraitPanel and view.portraitPanel:getRight() or math.floor(view.width * 0.33)
    local x = portraitRight + padding
    local width = math.max(100, view.width - x - padding)
    local labelWidth = math.min(112, math.floor(width * 0.42))
    local y = topY
    local name = IdentityPresentation.GetName(view.npcId)
    local archetype = IdentityPresentation.GetArchetype(view.npcId)
    local traitList, traitsKnown = traitEntries(view.npcId)
    local hp = tostring(math.floor(tonumber(resolved.hpCurrent) or 0)) .. "/" .. tostring(math.floor(tonumber(resolved.hpMax) or 0))
    local stamina = tostring(math.floor(tonumber(resolved.staminaCurrent) or 0)) .. "/" .. tostring(math.floor(tonumber(resolved.staminaMax) or 0))
    local carryText = tostring(Shared.Round(carry.usedWeight or 0, 1)) .. "/" .. tostring(Shared.Round(carry.maxWeight or 0, 1))

    view:drawText(name, x, y, 1, 1, 1, 1, UIFont.Medium)
    view:drawTextRight(archetype, x + width, y + 2, 1, 1, 1, 1, UIFont.Small)
    y = y + (getTextManager():getFontHeight(UIFont.Medium) + 3)
    view:drawRect(x, y, width, 1, 0.8, 0.5, 0.5, 0.5)
    y = y + 14

    y = Shared.DrawLabelValue(view,
        Shared.Text("UI_PNC_Character_Info_Faction", "Faction"),
        knownFaction and knownFaction.name or Shared.Text("UI_PNC_Character_Info_Unknown", "Unknown"),
        x, y, labelWidth)
    local traitLabel = Shared.Text("UI_PNC_Character_Traits", "Traits")
    local traitTextY = y
    local traitFontHeight = getTextManager():getFontHeight(UIFont.Small)
    view:drawTextRight(traitLabel, x + labelWidth, traitTextY,
        1, 1, 1, 1, UIFont.Small)
    if not traitsKnown then
        view:drawText(Shared.Text("UI_PNC_Character_Info_Unknown", "Unknown"), x + labelWidth + 10, traitTextY,
            1, 1, 1, 0.62, UIFont.Small)
    elseif #traitList == 0 then
        view:drawText(
            Shared.Text("UI_PNC_Character_Traits_None", "None"),
            x + labelWidth + 10, traitTextY, 1, 1, 1, 0.62, UIFont.Small
        )
    end
    local traitIconHeight = drawTraitIcons(
        view, traitList, x + labelWidth + 10, traitTextY,
        width - labelWidth - 10
    )
    -- Re-resolve every draw so a live data refresh cannot permanently hide a
    -- tooltip while the cursor stays over the same trait icon.
    updateTraitTooltip(view)
    y = traitTextY + math.max(
        traitFontHeight + 6,
        traitIconHeight > 0 and traitIconHeight + 4 or 0
    )
    local activity = Shared.GetMedicalActivity
        and Shared.GetMedicalActivity(snapshot, payload) or nil
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Status", "Status"),
        activity and activity.label or resolved.aiState or resolved.activeBehavior or "Idle",
        x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Health", "Health"), hp, x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Stamina", "Stamina"), stamina, x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_CarryWeight", "Carry Weight"), carryText, x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Hair", "Hair"), appearance.hairModel or survivor.hairModel or Shared.Text("UI_PNC_Character_Info_None", "None"), x, y, labelWidth)
    if resolved.isFemale ~= true then
        y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Beard", "Beard"), appearance.beardModel or survivor.beardModel or Shared.Text("UI_PNC_Character_Info_None", "None"), x, y, labelWidth)
    end
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Weapon", "Weapon"), equipment.primaryFullType or Shared.Text("UI_PNC_Character_Info_BareHands", "Bare hands"), x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Combat", "Combat"), resolved.combatModeResolved or resolved.weaponMode or "melee", x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Recruited", "Recruited"), resolved.recruited == true and Shared.Text("UI_PNC_Character_Info_Yes", "Yes") or Shared.Text("UI_PNC_Character_Info_No", "No"), x, y, labelWidth)
    y = Shared.DrawLabelValue(view, Shared.Text("UI_PNC_Character_Info_Owner", "Owner"), data.ownerUsername or "-", x, y, labelWidth)

    local portraitBottom = view.portraitPanel and view.portraitPanel:getBottom() or y
    local footerY = math.max(y + 8, portraitBottom + 10)
    view:drawTextCentre(PNC.Translation.TrFormat(
        "UI_PNC_Character_Info_InventoryItems", "Inventory Items  %1",
        tostring(carry.itemCount or 0)
    ), view.width / 2, footerY, 0.82, 0.82, 0.82, 1, UIFont.Small)
    return footerY + getTextManager():getFontHeight(UIFont.Small) + 10
end

return Tabs
