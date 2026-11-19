-- Read-only, lazy portrait providers. Browsing never applies a preset/session edit.
require 'PNC/Identity/PNC_UniqueNPCDraft'
local Preview = {}

function Preview.BuildDraft(draft)
    local model = PNC.UniqueNPCEditorModel
    local candidate = model.BuildPreviewDraft(draft)
    local record, reason = model.EnsureRuntimeRecord(candidate, true)
    if not record then return nil, reason end
    return model.BuildPortraitSpec(candidate, record)
end

function Preview.Draft(draft)
    local cached
    return function()
        if not cached then
            local spec, reason = Preview.BuildDraft(draft)
            cached = { spec = spec, label = draft.displayName, reason = reason }
        end
        return cached.spec, cached.label, 1, cached.reason
    end
end

return Preview
