-- Relationship-aware adapter for the shared NPC authoring presentation.
--
-- The editor never writes resolved values directly to the session.  It keeps
-- a view snapshot, detects an actual user edit, and sends only that edit
-- through StartingCompanionSession's policy-aware canonical API.  This is
-- what keeps inherited and derived values visible without turning them into
-- authored blueprint intent.

require "PNC/Identity/PNC_NPCAuthoringComposer"
require "PNC/Identity/PNC_UniqueNPCDraft"
require "PNC/Core/Identity/PNC_NPCAuthoring"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Profile"
require "PNC/Identity/PNC_NPCAuthoringVariation"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringRelationshipPresentation"

PNC = PNC or {}
PNC.StartingCompanionAuthoringAdapter =
    PNC.StartingCompanionAuthoringAdapter or {}

local Adapter = PNC.StartingCompanionAuthoringAdapter
local Composer = PNC.NPCAuthoringComposer
local Model = PNC.UniqueNPCEditorModel
local Authoring = PNC.NPCAuthoring
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint
local Profile = PNC.NPCAuthoringEditorProfile

local function copy(value)
    return Registry.Copy(value)
end

local function stateValue(blueprint, fieldID)
    local state, value = Blueprint.Get(blueprint, fieldID)
    return {
        state = state or "absent",
        value = copy(value),
    }
end

local function sameValue(left, right)
    return Registry.Hash(left or { state = "absent" })
        == Registry.Hash(right or { state = "absent" })
end

local function sourceHelp(source)
    return Profile.SourceHelp(source)
end

local function contextFingerprint(context)
    context = type(context) == "table" and context or {}
    -- Do not hash the live player/descriptor userdata.  These are the
    -- semantic context values that the relationship resolver actually reads
    -- and they remain stable across UI refreshes while still invalidating a
    -- preview when the final player changes.
    return Registry.Hash({
        playerSurname = context.playerSurname,
        playerFemale = context.playerFemale,
        orientation = context.orientation,
        socialOrientation = context.socialOrientation,
        playerAppearance = copy(context.playerAppearance),
        socialTraitIDs = copy(context.socialTraitIDs),
    })
end

function Adapter.New(session, traitID)
    local object = {
        session = session,
        traitID = traitID,
        composer = Composer.New({ session = session, traitID = traitID }),
        _viewSnapshot = nil,
    }
    return setmetatable(object, { __index = Adapter })
end

function Adapter:Attach(editor)
    self.editor = editor
    return self
end

function Adapter:Slot()
    return self.composer and self.composer:Slot() or nil
end

function Adapter:BlueprintIntent()
    return self.composer and self.composer:BlueprintIntent() or nil
end

function Adapter:ContextFingerprint()
    local context = self.session and self.session.GetContext
        and self.session:GetContext() or {}
    return contextFingerprint(context)
end

function Adapter:PreviewGenerationIdentity()
    local intent = self:BlueprintIntent() or {}
    return table.concat({
        "companion", tostring(self.traitID),
        tostring(intent.generationSeed or "none"),
        "context", self:ContextFingerprint(),
    }, ":")
end

function Adapter:PreviewIdentity()
    local intent = self:BlueprintIntent() or {}
    local fingerprint = Blueprint.Fingerprint(intent)
        or Registry.Hash(intent)
    return table.concat({
        "companion", tostring(self.traitID),
        tostring(fingerprint),
        "seed", tostring(intent.generationSeed or "none"),
        "context", self:ContextFingerprint(),
    }, ":")
end

function Adapter:FieldCapability(fieldID)
    local visible = Profile.IsVisible("companion", fieldID)
    local row
    if self.composer and visible then
        for _, candidate in ipairs(self.composer:FieldRows(64)) do
            if candidate.fieldID == fieldID then
                row = candidate
                break
            end
        end
    end
    if not visible or not row then
        return {
            visible = false,
            editable = false,
            source = "generated",
            sourceLabel = sourceHelp("generated"),
        }
    end
    local capability = {
        visible = true,
        editable = row.editable == true,
        constraint = row.locked == true,
        required = row.required == true,
        inherited = row.inherited == true,
        derived = row.derived == true,
        source = row.source,
        sourceLabel = sourceHelp(row.source),
        rule = row.rule,
        dependencies = copy(row.dependencies),
    }
    capability.explanation = PNC.NPCAuthoringRelationshipPresentation.Reason(self, fieldID, capability)
    return capability
end

function Adapter:InspectorRows(limit)
    local rows = self.composer and self.composer:FieldRows(limit or 64) or {}
    for _, row in ipairs(rows) do
        row.sourceLabel = sourceHelp(row.source)
    end
    return rows
end

function Adapter:_snapshotDraft(draft)
    local blueprint = Model.BuildBlueprint(draft, {
        generationSeed = self:BlueprintIntent()
            and self:BlueprintIntent().generationSeed or draft.previewSeed,
    })
    local snapshot = {}
    if not blueprint then return snapshot end
    for _, field in ipairs(Profile.List("companion")) do
        snapshot[field.id] = stateValue(blueprint, field.id)
    end
    return snapshot
end

function Adapter:BuildDraft()
    local preview = self.composer and self.composer:ResolvedPreview() or nil
    local intent = self:BlueprintIntent()
    if not preview or not intent then return nil end
    local draft = Model.FromDefinition(preview)
    if not draft then return nil end
    draft.previewSeed = intent.generationSeed
    draft.previewIdentity = self:PreviewIdentity()
    draft.previewGenerationIdentity = self:PreviewGenerationIdentity()
    draft.identityIDLocked = true
    self._viewSnapshot = self:_snapshotDraft(draft)
    return draft
end

-- Project the look already shown to the user into the existing blueprint
-- fields at export. The live editing blueprint keeps its sparse intent.
function Adapter:RememberPreview(record)
    local slot = self:Slot()
    local intent = self:BlueprintIntent()
    local snapshot = record.runtime and record.runtime.previewVisualSnapshot
    if not slot or not intent or not snapshot or not self.session.RememberPreview then return end
    local output = Blueprint.Clone(intent)
    local look = snapshot.appearance
    for _, name in ipairs({ "hairModel", "beardModel", "skinTexture", "skinColor", "hairColor",
        "hairStubble", "beardStubble", "chestHair" }) do
        local key = "appearance." .. name
        local state = Blueprint.Get(intent, key)
        if state ~= "value" and look[name] ~= nil and self:FieldCapability(key).editable then
            output = Blueprint.Set(output, key, look[name])
            if not output then return end
        end
    end
    if self:FieldCapability("appearance").editable then
        local appearance = PNC.Identity.Appearance.Normalize(slot.resolvedDefinition.appearance)
        local captured = false
        for _, item in pairs(record.inventory and record.inventory.items or {}) do
            if item.wornSlot and not item.maxWeight and not item.bagContainer then
                captured = true
                PNC.Identity.Appearance.CaptureSlot(appearance.slots, item.wornSlot, {
                    mode = "item", type = item.type, wornSlot = item.wornSlot,
                    itemState = copy(item.itemState),
                })
            end
        end
        if captured or appearance.outfit.mode == "none" then
            appearance.outfit = { mode = "none" }
            output = Blueprint.Set(output, "appearance", appearance)
            if not output then return end
        end
    end
    self.session:RememberPreview(self.traitID, output)
end

function Adapter:_commitCandidate(candidate)
    local slot = self:Slot()
    local policy = Authoring.Resolver.PolicyForStartingCompanion(slot.spec, self.session:GetContext())
    local plan, reason = Authoring.Resolver.ResolvePlan(candidate, self.session:GetContext(), policy)
    if not plan then return false, reason end
    return self.session:SetBlueprint(self.traitID, candidate)
end

function Adapter:CommitDraft(draft)
    local intent = self:BlueprintIntent()
    if not self.session or not draft or not intent then return false end
    local proposed, reason = Model.BuildBlueprint(draft, { generationSeed = intent.generationSeed, id = intent.id })
    if not proposed then return false, reason end
    local current = self:_snapshotDraft(draft)
    local candidate, changed = Blueprint.Clone(intent), false
    for _, field in ipairs(Profile.List("companion")) do
        local before = self._viewSnapshot and self._viewSnapshot[field.id]
        local after = current[field.id]
        if self:FieldCapability(field.id).editable ~= false and before and not sameValue(before, after) then
            if after.state == "value" then candidate, reason = Blueprint.Set(candidate, field.id, after.value)
            else candidate, reason = Blueprint.Clear(candidate, field.id) end
            if not candidate then return false, reason end
            changed = true
        end
    end
    if not changed then return false end
    return self:_commitCandidate(candidate)
end

-- Explicit visual variation is allowed in character creation. Random policies
-- remain absent from selectors; only concrete editable visual fields are saved.
function Adapter:VaryLook()
    local intent = self:BlueprintIntent()
    local draft = self:BuildDraft()
    if not intent or not draft then return nil, "slot_not_found" end
    Model.Randomize(draft)
    local preview = Model.BuildPreviewDraft(draft)
    local record, reason = Model.EnsureRuntimeRecord(preview, true)
    if not record then return nil, reason end
    local spec = Model.BuildPortraitSpec(preview)
    local look = spec and spec.appearance or {}
    -- Freeze the actual generated wardrobe too: fallback archetype clothing
    -- must not revert to the old global seed after the visual-only transaction.
    local appearance = PNC.Identity.Appearance.Normalize(draft.appearance)
    for _, item in pairs(record.inventory and record.inventory.items or {}) do
        if item.wornSlot and not item.equipSlot and not item.maxWeight and not item.bagContainer then
            appearance.slots[item.wornSlot] = { mode = "item", type = item.type,
                wornSlot = item.wornSlot, itemState = copy(item.itemState) }
        end
    end
    draft.appearance = appearance
    for _, key in ipairs({ "hairModel", "beardModel", "skinTexture", "skinColor", "hairColor" }) do
        draft.identity.survivor[key] = copy(look[key])
    end
    local generated
    generated, reason = Model.BuildBlueprint(draft)
    if not generated then return nil, reason end
    local candidate = Blueprint.Clone(intent)
    for _, field in ipairs(Profile.List("companion")) do
        local visual = field.group == "appearance" and not string.find(field.id, "appearance.voice", 1, true)
        if (visual or field.id == "startingItems") and self:FieldCapability(field.id).editable ~= false then
            local state, value = Blueprint.Get(generated, field.id)
            if state == "value" then candidate, reason = Blueprint.Set(candidate, field.id, value)
            else candidate, reason = Blueprint.Clear(candidate, field.id) end
            if not candidate then return nil, reason end
        end
    end
    -- Keep the original generation seed: rerolling it would also change names,
    -- relationship defaults and attributes outside this action's visual scope.
    local slot = self:Slot()
    local plan
    plan, reason = Authoring.Resolver.ResolvePlan(candidate, self.session:GetContext(),
        Authoring.Resolver.PolicyForStartingCompanion(slot.spec, self.session:GetContext()))
    if not plan then return nil, reason end
    local ok
    ok, reason = self.session:SetBlueprint(self.traitID, candidate)
    if not ok then return nil, reason end
    self._viewSnapshot = nil
    return true
end

function Adapter:RandomizeTab(scope)
    local intent = self:BlueprintIntent()
    local source = self:BuildDraft()
    if not source then return nil, "slot_not_found" end
    self.variationCount = (self.variationCount or 0) + 1
    local V = PNC.NPCAuthoringVariation
    local varied, reason = V.Generate(source, scope, V.Seed(intent.generationSeed, scope, self.variationCount, Blueprint.Fingerprint(intent)))
    if not varied then return nil, reason end
    local proposed
    proposed, reason = Model.BuildBlueprint(varied)
    if not proposed then return nil, reason end
    local candidate = Blueprint.Clone(intent)
    for _, field in ipairs(Profile.List("companion")) do
        if V.Includes(scope, field.id) and self:FieldCapability(field.id).editable ~= false then
            local state, value = Blueprint.Get(proposed, field.id)
            if state == "value" then candidate, reason = Blueprint.Set(candidate, field.id, value)
            else candidate, reason = Blueprint.Clear(candidate, field.id) end
            if not candidate then return nil, reason end
        end
    end
    local ok
    ok, reason = self:_commitCandidate(candidate)
    if ok then self._viewSnapshot = nil end
    return ok, reason
end

function Adapter:Randomize()
    return nil, "randomization_unavailable"
end

function Adapter:Reset()
    self._viewSnapshot = nil
    return self.session:ResetSlot(self.traitID)
end

function Adapter:RevertToPreset()
    self._viewSnapshot = nil
    return self.session:RevertToPreset(self.traitID)
end

function Adapter:Refresh(context)
    self._viewSnapshot = nil
    return self.session:Refresh(context)
end

return Adapter
