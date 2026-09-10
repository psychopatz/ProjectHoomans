require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}

local Tabs = PNC.CharacterWindowTabs
local Shared = PNC.CharacterWindowShared
local Layout = PsychopatzCore.UI.Layout
local IdentityPresentation = PNC.NPCIdentityPresentation

-- Temporary shared artwork until the Project Hoomans trait icon set is
-- generated. Keep this fallback centralized so the generated paths can be
-- added without changing the trait presentation flow.
local TRAIT_ICON_PLACEHOLDER = "media/ui/Traits/trait_artisan.png"
local TRAIT_ICON_PATHS = {}
local TRAIT_ICON_SIZE = 18

local function knowledgeSnapshot(npcID)
    local state = PNC.Network and PNC.Network.ClientState or nil
    return state and state.npcKnowledge and state.npcKnowledge[tostring(npcID)] or nil
end

local function traitEntries(npcID)
    local knowledge = knowledgeSnapshot(npcID)
    local entries = {}
    local known = false
    for _, category in ipairs(knowledge and knowledge.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            local presentation = descriptor.presentation or {}
            if presentation.topicID == "traits" and descriptor.value ~= nil then
                known = true
                if descriptor.value == true then
                    local traitID = tostring(presentation.traitID or "")
                    entries[#entries + 1] = {
                        id = traitID,
                        label = Shared.Text(
                            presentation.labelKey, presentation.traitID
                        ),
                        iconPath = TRAIT_ICON_PATHS[traitID]
                            or presentation.iconPath
                            or TRAIT_ICON_PLACEHOLDER,
                    }
                end
            end
        end
    end
    table.sort(entries, function(left, right)
        return tostring(left.label) < tostring(right.label)
    end)
    return entries, known
end

local function traitText(npcID, entries, known)
    if not entries or not known then
        entries, known = traitEntries(npcID)
    end
    if not known then return "Unknown" end
    if #entries == 0 then
        return Shared.Text("UI_PNC_Character_Traits_None", "None")
    end
    local labels = {}
    for index = 1, #entries do labels[index] = entries[index].label end
    return table.concat(labels, ", ")
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
    for index = 1, #entries do
        local texture = loadTraitIcon(entries[index].iconPath)
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
            drawn = drawn + 1
        end
    end
    if drawn == 0 then return 0 end
    return math.ceil(drawn / columns) * (TRAIT_ICON_SIZE + gap) - gap
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

    y = Shared.DrawLabelValue(view, "Faction", knownFaction and knownFaction.name or "Unknown", x, y, labelWidth)
    y = Shared.DrawLabelValue(
        view,
        Shared.Text("UI_PNC_Character_Traits", "Traits"),
        traitText(view.npcId, traitList, traitsKnown),
        x, y, labelWidth
    )
    local traitIconHeight = drawTraitIcons(
        view, traitList, x + labelWidth + 10, y + 1,
        width - labelWidth - 10
    )
    if traitIconHeight > 0 then y = y + traitIconHeight + 4 end
    local activity = Shared.GetMedicalActivity
        and Shared.GetMedicalActivity(snapshot, payload) or nil
    y = Shared.DrawLabelValue(view, "Status",
        activity and activity.label or resolved.aiState or resolved.activeBehavior or "Idle",
        x, y, labelWidth)
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
