-- Character-creation state for starting companions.
--
-- The session is keyed by the canonical starting-companion trait ID.  It
-- stores authored blueprints only; previews and traces are rebuilt from the
-- current survivor/context without mutating the blueprint.

require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PNC/Core/Relationships/PNC_SocialProfileConstants"
require "PNC/Core/Relationships/PNC_SocialProfileTypes"
require "PNC/Core/Relationships/PNC_SocialTraits"
require "PNC/Core/Identity/PNC_NPCAuthoring"

PNC = PNC or {}
PNC.StartingCompanionSession = PNC.StartingCompanionSession or {}

local Session = PNC.StartingCompanionSession
local StartingTraits = PNC.StartingCompanionTraits
local SocialTraits = PNC.SocialTraits
local Authoring = PNC.NPCAuthoring
local Registry = Authoring.Registry
local Blueprint = Authoring.Blueprint
local Resolver = Authoring.Resolver
local CoreTraits = PsychopatzCore and PsychopatzCore.Traits
local Identity = PNC.Identity

Session.VERSION = 1
Session.MAX_SLOTS = #StartingTraits.DEFINITIONS

local function copy(value)
    return Registry.Copy(value)
end

local function seed(value, fallback)
    if Identity and Identity.NormalizeSeed then
        return Identity.NormalizeSeed(value, fallback)
    end
    return tonumber(Registry.Hash(tostring(fallback or "starting-companion"))) or 1
end

local function nextSeed(fallback)
    if Identity and Identity.RollSeed and type(ZombRand) == "function" then
        return seed(Identity.RollSeed(), fallback)
    end
    return seed(nil, fallback)
end

local function merge(left, right)
    local output = {}
    local key
    if type(left) == "table" then
        for key, value in pairs(left) do output[key] = value end
    end
    if type(right) == "table" then
        for key, value in pairs(right) do output[key] = value end
    end
    return output
end

local function normalizeTraitID(value)
    local id = value
    if CoreTraits and CoreTraits.NormalizeID then
        id = CoreTraits.NormalizeID(value, StartingTraits.OWNER)
    end
    if id and StartingTraits.GetDefinition(id) then return id end
    return nil
end

local function normalizeCompanionIDs(values)
    local found = {}
    local output = {}
    local id
    local value
    if type(values) ~= "table" then return output end
    for _, value in ipairs(values) do
        id = normalizeTraitID(value)
        if id then found[id] = true end
    end
    for _, spec in ipairs(StartingTraits.DEFINITIONS) do
        if found[spec.id] then output[#output + 1] = spec.id end
    end
    return output
end

local function asSet(values)
    local output = {}
    for _, value in ipairs(values or {}) do output[value] = true end
    return output
end

local function readMethod(target, name)
    if not target then return nil end
    local method = target[name]
    if type(method) ~= "function" then return nil end
    return method(target)
end

local function findDescriptor(screen, context)
    if context and context.playerDescriptor then
        return context.playerDescriptor
    end
    if screen and screen.desc then return screen.desc end
    if MainScreen and MainScreen.instance and MainScreen.instance.desc then
        return MainScreen.instance.desc
    end
    if context and context.player and context.player.getDescriptor then
        return context.player:getDescriptor()
    end
    return context and context.player or nil
end

local function readPlayerContext(screen, context)
    local output = merge(context, {})
    local descriptor = findDescriptor(screen, output)
    local value
    if descriptor then
        if output.playerDescriptor == nil then
            output.playerDescriptor = descriptor
        end
        if output.playerSurname == nil then
            value = readMethod(descriptor, "getSurname")
            if value ~= nil then output.playerSurname = tostring(value) end
        end
        if output.playerFemale == nil then
            value = readMethod(descriptor, "isFemale")
            if value ~= nil then output.playerFemale = value == true end
        end
        if output.playerAppearance == nil
            and Identity and Identity.GetCharacterAppearance
        then
            output.playerAppearance = Identity.GetCharacterAppearance(descriptor)
        end
    end
    if output.playerAppearance == nil
        and output.player
        and Identity
        and Identity.GetCharacterAppearance
    then
        output.playerAppearance = Identity.GetCharacterAppearance(output.player)
    end
    return output
end

local function updateSocialContext(context, selectedTraitIDs)
    local profile
    if type(selectedTraitIDs) ~= "table" or not SocialTraits then
        return context
    end
    profile = SocialTraits.ResolveTraits(selectedTraitIDs)
    if profile and profile.orientation then
        context.orientation = profile.orientation
        context.socialOrientation = profile.orientation
    end
    context.socialProfile = profile
    context.socialTraitIDs = copy(selectedTraitIDs)
    return context
end

local function newSlot(self, traitID)
    local slotSeed = seed(nil, tostring(self.sessionSeed) .. ":slot:" .. traitID)
    local blueprint = Blueprint.New({
        id = "starter:" .. tostring(traitID),
        generationSeed = slotSeed,
    })
    return {
        traitID = traitID,
        spec = StartingTraits.GetDefinition(traitID),
        active = true,
        defaultBlueprint = Blueprint.Clone(blueprint),
        blueprint = blueprint,
        presetBaseline = nil,
        resolvedDefinition = nil,
        trace = nil,
        error = nil,
    }
end

local function setBlueprint(slot, blueprint)
    local normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return false, reason end
    normalized.id = "starter:" .. tostring(slot.traitID)
    slot.blueprint = normalized
    return true
end

function Session.New(options)
    options = type(options) == "table" and options or {}
    local initialSeed = options.sessionSeed or options.seed
    if initialSeed == nil then
        initialSeed = nextSeed(options.seedText or "starting-companion-session")
    end
    local object = {
        version = Session.VERSION,
        sessionSeed = seed(initialSeed,
            options.seedText or "starting-companion-session"),
        baseContext = merge(options.context, {}),
        context = merge(options.context, {}),
        slots = {},
        cache = {},
        pendingBlueprints = {},
        selected = {},
        selectedOrder = {},
        randomizeCount = 0,
        lastEvent = nil,
        lastReconciliation = nil,
    }
    return setmetatable(object, { __index = Session })
end

function Session:BuildContext(snapshot, overrides)
    local selectedTraitIDs = snapshot and snapshot.selectedTraitIDs or nil
    local context = readPlayerContext(
        snapshot and snapshot.screen or self.context.screen,
        merge(self.baseContext, overrides)
    )
    if selectedTraitIDs then
        context = updateSocialContext(context, selectedTraitIDs)
    end
    return context
end

function Session:GetContext()
    return self.context
end

function Session:GetSlot(traitID, includeInactive)
    local id = normalizeTraitID(traitID) or traitID
    local slot = id and self.slots[id] or nil
    if slot and (includeInactive == true or slot.active == true) then
        return slot
    end
    return nil
end

function Session:GetActiveSlots()
    local output = {}
    for _, id in ipairs(self.selectedOrder) do
        local slot = self.slots[id]
        if slot and slot.active then output[#output + 1] = slot end
    end
    return output
end

function Session:GetBlueprint(traitID)
    local slot = self:GetSlot(traitID, true)
    return slot and Blueprint.Clone(slot.blueprint) or nil
end

function Session:IsSlotAuthored(traitID)
    local slot = self:GetSlot(traitID, true)
    local currentFingerprint
    local defaultFingerprint
    if not slot or not slot.active then return false end
    if not slot.defaultBlueprint then return true end
    currentFingerprint = Blueprint.Fingerprint(slot.blueprint)
    defaultFingerprint = Blueprint.Fingerprint(slot.defaultBlueprint)
    if not currentFingerprint or not defaultFingerprint then return true end
    return currentFingerprint ~= defaultFingerprint
end

function Session:HasAuthoredIntent()
    for _, id in ipairs(self.selectedOrder) do
        if self:IsSlotAuthored(id) then return true end
    end
    return false
end

function Session:ResolveSlot(traitID, context)
    local slot = self:GetSlot(traitID, true)
    local plan
    local reason
    if not slot then return nil, "slot_not_found" end
    plan, reason = Resolver.ResolvePlan(
        slot.blueprint,
        context or self.context,
        Resolver.PolicyForStartingCompanion(slot.spec, context or self.context),
        { id = "starter:" .. tostring(slot.traitID), version = 1 }
    )
    if not plan then
        slot.resolvedDefinition = nil
        slot.trace = nil
        slot.error = reason
        return nil, reason
    end
    slot.resolvedDefinition = plan.definition
    slot.trace = plan.trace
    slot.error = nil
    return plan
end

function Session:ResolveActive()
    local errors = {}
    local context = self.context
    for _, id in ipairs(self.selectedOrder) do
        local slot = self.slots[id]
        if slot and slot.active then
            local _, reason = self:ResolveSlot(id, context)
            if reason then errors[id] = reason end
        end
    end
    return errors
end

function Session:ValidateActive()
    local errors = self:ResolveActive()
    for _, id in ipairs(self.selectedOrder) do
        if errors[id] then
            return false, "slot:" .. tostring(id) .. ":" .. tostring(errors[id]),
                errors
        end
    end
    return true, nil, errors
end

function Session:Reconcile(selectedTraitIDs, context)
    local currentOrder = normalizeCompanionIDs(selectedTraitIDs)
    local current = asSet(currentOrder)
    local previous = self.selected
    local added = {}
    local removed = {}
    local unchanged = {}
    local id
    local slot
    local pending
    local errors

    for _, spec in ipairs(StartingTraits.DEFINITIONS) do
        id = spec.id
        if current[id] and not previous[id] then
            added[#added + 1] = id
            slot = self.slots[id] or self.cache[id]
            if not slot then slot = newSlot(self, id) end
            slot.active = true
            pending = self.pendingBlueprints[id]
            if pending then
                setBlueprint(slot, pending)
                slot.presetBaseline = Blueprint.Clone(pending)
                self.pendingBlueprints[id] = nil
            end
            self.slots[id] = slot
            self.cache[id] = slot
        elseif current[id] and previous[id] then
            unchanged[#unchanged + 1] = id
            slot = self.slots[id]
            if slot then slot.active = true end
        elseif previous[id] and not current[id] then
            removed[#removed + 1] = id
            slot = self.slots[id]
            if slot then
                slot.active = false
                self.cache[id] = slot
            end
        end
    end
    self.selected = current
    self.selectedOrder = currentOrder
    self.context = context or self.context or {}
    errors = self:ResolveActive()
    self.lastReconciliation = {
        added = copy(added),
        removed = copy(removed),
        unchanged = copy(unchanged),
        active = copy(currentOrder),
        selected = copy(current),
        errors = errors,
    }
    return self.lastReconciliation
end

function Session:HandleCharacterCreationEvent(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    local selected = snapshot.selectedCompanionTraitIDs
        or snapshot.selectedTraitIDs or {}
    local context = self:BuildContext(snapshot, snapshot.context)
    self.lastEvent = snapshot
    return self:Reconcile(selected, context)
end

function Session:Refresh(context, selectedTraitIDs)
    if selectedTraitIDs then
        return self:Reconcile(selectedTraitIDs, self:BuildContext(nil, context))
    end
    self.context = self:BuildContext(nil, context)
    local errors = self:ResolveActive()
    if self.lastReconciliation then self.lastReconciliation.errors = errors end
    return errors
end

function Session:SetField(traitID, fieldID, value)
    local slot = self:GetSlot(traitID, true)
    local policy
    local binding
    local nextBlueprint
    local reason
    if not slot then return nil, "slot_not_found" end
    policy = Resolver.PolicyForStartingCompanion(slot.spec, self.context)
    binding = policy.bindings and policy.bindings[tostring(fieldID)] or nil
    if binding and binding.editable == false then
        return nil, "field_locked:" .. tostring(fieldID)
    end
    nextBlueprint, reason = Blueprint.Set(slot.blueprint, fieldID, value)
    if not nextBlueprint then return nil, reason end
    slot.blueprint = nextBlueprint
    self:ResolveSlot(slot.traitID, self.context)
    return Blueprint.Clone(slot.blueprint)
end

function Session:ClearField(traitID, fieldID)
    local slot = self:GetSlot(traitID, true)
    local policy
    local nextBlueprint
    local reason
    if not slot then return nil, "slot_not_found" end
    policy = Resolver.PolicyForStartingCompanion(slot.spec, self.context)
    nextBlueprint, reason = Blueprint.Clear(slot.blueprint, fieldID, policy)
    if not nextBlueprint then return nil, reason end
    slot.blueprint = nextBlueprint
    self:ResolveSlot(slot.traitID, self.context)
    return Blueprint.Clone(slot.blueprint)
end

function Session:RandomizeSlot(traitID, generationSeed)
    local slot = self:GetSlot(traitID, true)
    local nextBlueprint
    local reason
    if not slot then return nil, "slot_not_found" end
    self.randomizeCount = self.randomizeCount + 1
    nextBlueprint, reason = Blueprint.Randomize(
        slot.blueprint,
        generationSeed or nextSeed(
            tostring(self.sessionSeed) .. ":randomize:" .. self.randomizeCount
        )
    )
    if not nextBlueprint then return nil, reason end
    slot.blueprint = nextBlueprint
    self:ResolveSlot(slot.traitID, self.context)
    return Blueprint.Clone(slot.blueprint)
end

function Session:ResetSlot(traitID)
    local slot = self:GetSlot(traitID, true)
    if not slot then return nil, "slot_not_found" end
    slot.blueprint = Blueprint.Clone(slot.defaultBlueprint)
    self:ResolveSlot(slot.traitID, self.context)
    return Blueprint.Clone(slot.blueprint)
end

function Session:RevertToPreset(traitID)
    local slot = self:GetSlot(traitID, true)
    if not slot then return nil, "slot_not_found" end
    if not slot.presetBaseline then return nil, "preset_baseline_missing" end
    slot.blueprint = Blueprint.Clone(slot.presetBaseline)
    self:ResolveSlot(slot.traitID, self.context)
    return Blueprint.Clone(slot.blueprint)
end

function Session:SetPresetBaseline(traitID, blueprint)
    local slot = self:GetSlot(traitID, true)
    local normalized, reason
    if not slot then return false, "slot_not_found" end
    normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return false, reason end
    normalized.id = "starter:" .. tostring(slot.traitID)
    slot.presetBaseline = Blueprint.Clone(normalized)
    return true
end

function Session:SetBlueprint(traitID, blueprint, options)
    local slot = self:GetSlot(traitID, true)
    local normalized, reason
    options = type(options) == "table" and options or {}
    if not slot then return false, "slot_not_found" end
    normalized, reason = Blueprint.Normalize(blueprint)
    if not normalized then return false, reason end
    normalized.id = "starter:" .. tostring(slot.traitID)
    slot.blueprint = normalized
    if options.presetBaseline == true then
        slot.presetBaseline = Blueprint.Clone(normalized)
    end
    self:ResolveSlot(slot.traitID, self.context)
    return true
end

function Session:FinalBlueprints()
    local output = {}
    for _, id in ipairs(self.selectedOrder) do
        local slot = self.slots[id]
        if slot and slot.active then output[id] = Blueprint.Clone(slot.blueprint) end
    end
    return output
end

function Session:ResolutionRows(traitID, limit)
    local slot = self:GetSlot(traitID, true)
    if not slot or not slot.trace then return {} end
    return Resolver.BuildResolutionSummary(slot.trace, limit)
end

function Session:FinalSummary()
    local output = {}
    for _, id in ipairs(self.selectedOrder) do
        local slot = self.slots[id]
        local identity
        local resolved
        if slot and slot.active then
            resolved = slot.resolvedDefinition or {}
            identity = resolved.identity or {}
            output[#output + 1] = {
                traitID = id,
                relationshipKind = slot.spec.relationshipKind,
                displayName = identity and identity.displayName
                    or resolved.displayName,
                nickname = identity and identity.nickname or nil,
                isFemale = identity and identity.isFemale or nil,
                trace = self:ResolutionRows(id, 12),
                error = slot.error,
            }
        end
    end
    return output
end

return Session
