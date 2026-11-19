-- Resolve roster membership and inheritance before drawing a shared draft portrait.
require 'PNC/CharacterCreation/PNC_StartingCompanionPresets'
require 'PNC/Core/Traits/PNC_StartingCompanionTraits'
local DraftPreview = require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringPresetPreview'

local Preview = {}

local function portrait(definition, seed)
    local draft, reason = PNC.UniqueNPCEditorModel.FromDefinition(definition, { previewSeed = seed })
    if not draft then return nil, nil, reason end
    draft.previewSeed = seed or draft.previewSeed
    local spec
    spec, reason = DraftPreview.BuildDraft(draft)
    if not spec then return nil, nil, reason end
    return spec, draft.displayName
end

function Preview.BuildProvider(payload, context, session, selectedTraitID)
    local authoring = PNC.NPCAuthoring
    local presets = PNC.StartingCompanionPresets
    local normalized, reason = presets.Deserialize(payload)
    if not normalized then return function() return nil, nil, 0, reason end end
    local members, cache = {}, {}
    if normalized.kind == "template" then
        members[1] = { source = normalized.companionTraitID, target = selectedTraitID or normalized.companionTraitID }
    else
        for _, spec in ipairs(PNC.StartingCompanionTraits.DEFINITIONS) do
            if normalized.slots[spec.id] and (not session or session:GetSlot(spec.id, false)) then
                members[#members + 1] = { source = spec.id, target = spec.id }
            end
        end
    end
    context = authoring.Registry.Copy(context or {})
    return function(index)
        index = math.max(1, math.min(#members, tonumber(index) or 1))
        local member = members[index]
        if not member then return nil, nil, 0, 'preset_empty' end
        if not cache[index] then
            local slot = session and session:GetSlot(member.target, false)
            local blueprint, plan = presets.PrepareSlot(
                normalized.slots[member.source], member.target, context, slot and slot.blueprint)
            local spec, label, why
            if blueprint then
                spec, label, why = portrait(plan.definition, blueprint.generationSeed)
            else
                why = plan
            end
            cache[index] = { spec = spec, label = label, reason = why }
        end
        local selected = cache[index]
        return selected.spec, selected.label, #members, selected.reason
    end
end
return Preview
