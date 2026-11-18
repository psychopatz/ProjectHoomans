-- Human relationship explanations over the authoritative trait/policy metadata.
PNC.NPCAuthoringRelationshipPresentation = PNC.NPCAuthoringRelationshipPresentation or {}
local P = PNC.NPCAuthoringRelationshipPresentation
local function tr(key, fallback) return PNC.Translation.GetKey(key, fallback) end

function P.Reason(adapter, id, capability)
    if not capability or capability.editable ~= false or not capability.constraint then return nil end
    local slot = adapter:Slot()
    local spec = slot and slot.spec
    if not spec then return nil end
    local context = adapter.session:GetContext() or {}
    if id == "identity.surname" then
        if not context.playerSurname or context.playerSurname == "" then
            return tr("UI_PNC_Authoring_ReasonSurnamePending", "Enter your character's surname; this relationship inherits it.")
        end
        return string.format(tr("UI_PNC_Authoring_ReasonSurname", "This relationship uses your character's surname: %s."), context.playerSurname or "")
    elseif id == "identity.isFemale" then
        if spec.sex == "orientation" then
            local orientation = context.orientation or context.socialOrientation or "straight"
            return orientation == "gay" and tr("UI_PNC_Authoring_ReasonGay", "Your character is gay, so this partner has the same gender.")
                or tr("UI_PNC_Authoring_ReasonStraight", "Your character is straight, so this partner has the opposite gender.")
        end
        local trait = tr(spec.uiName, spec.relationshipKind)
        return string.format(tr(spec.sex == "female" and "UI_PNC_Authoring_ReasonFemale" or "UI_PNC_Authoring_ReasonMale",
            spec.sex == "female" and "%s requires a female companion." or "%s requires a male companion."), trait)
    elseif string.sub(id, 1, 11) == "appearance." then
        local trait = tr(spec.uiName, spec.relationshipKind)
        return string.format(tr("UI_PNC_Authoring_ReasonFamily", "%s inherits this appearance value from your character."), trait)
    end
    return capability.sourceLabel
end
function P.Rows(adapter, draft)
    local slot = adapter:Slot()
    local spec = slot and slot.spec
    if not spec then return {} end
    local names = { brother = "Brother", sister = "Sister", mother = "Mother", father = "Father", lover = "Lover", friend = "Friend" }
    local kind = spec.relationshipKind
    local key = names[kind] or "Friend"
    local descriptions = { Brother = "%s is your brother.", Sister = "%s is your sister.", Mother = "%s is your mother.", Father = "%s is your father.", Lover = "%s is your partner.", Friend = "%s is your friend." }
    local rows = {}
    local function add(label, value) rows[#rows + 1] = { label = label, value = value } end
    add(tr("UI_PNC_Authoring_Relationship", "Relationship"), string.format(tr("UI_PNC_Authoring_Relation" .. key,
        descriptions[key]), draft and draft.displayName or ""))
    local role = (kind == "mother" or kind == "father") and "Child" or (kind == "brother" or kind == "sister") and "Sibling"
        or kind == "lover" and "Partner" or "Friend"
    add(tr("UI_PNC_Authoring_PlayerRole", "Your role"), tr("UI_PNC_Authoring_Player" .. role, ({ Child = "You are their child.", Sibling = "You are their sibling.", Partner = "You are their partner.", Friend = "You are their friend." })[role]))
    add(tr("UI_PNC_Authoring_RelationshipSource", "From character trait"), tr(spec.uiName, kind))
    for _, field in ipairs({ "identity.isFemale", "identity.surname", "appearance.skinTexture", "appearance.hairColor" }) do
        local cap = adapter:FieldCapability(field)
        local value = P.Reason(adapter, field, cap) or tr("UI_PNC_Authoring_IndependentValue", "Independent; you can edit this value.")
        add(PNC.NPCAuthoringEditorProfile.Label(field), value)
    end
    add(tr("UI_PNC_Authoring_Backstory", "Backstory"), tr("UI_PNC_Authoring_BackstoryPending", "Backstory generation is planned. The relationship is set by your selected trait."))
    return rows
end
local function lines(text, width)
    local result, line = {}, ""
    local manager = getTextManager and getTextManager()
    local function measure(value) return manager and manager.MeasureStringX and manager:MeasureStringX(UIFont.Small, value) or #value * 8 end
    for word in string.gmatch(tostring(text or ""), "%S+") do
        local joined = line == "" and word or line .. " " .. word
        if line ~= "" and measure(joined) > width then result[#result + 1] = line; line = word else line = joined end
    end
    if line ~= "" then result[#result + 1] = line end
    return result
end
function P.Layout(list)
    if not list then return end
    if list.setFont then list:setFont(UIFont.Small, 6) end
    local height = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 16
    local total = 0
    for _, entry in ipairs(list.items or {}) do
        entry.item.lines = lines(entry.item.value, math.max(1, list.width - 32))
        entry.item.lineHeight = height
        entry.height = (#entry.item.lines + 1) * height + 18
        total = total + entry.height
    end
    list:setScrollHeight(total)
end
function P.DrawRow(list, y, entry, alternate)
    local row = entry.item
    local h = entry.height or list.itemheight
    PsychopatzCore.UI.DrawListSelection(list, y, h, list.selected == entry.index, alternate)
    list:drawText(row.label or "", 8, y + 5, .6, .7, .74, 1, UIFont.Small)
    for index, line in ipairs(row.lines or {}) do
        list:drawText(PsychopatzCore.UI.Layout.Ellipsize(line, UIFont.Small, math.max(1, list.width - 32)), 8,
            y + 10 + index * (row.lineHeight or 16), .92, .95, .95, 1, UIFont.Small)
    end
    return y + h
end
return P
