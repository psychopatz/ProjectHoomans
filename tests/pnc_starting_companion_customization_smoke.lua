local T = require "tests/support/test"

T.addPackagePaths()
PNC = { Identity = {} }
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileConstants.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialProfileTypes.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Relationships/PNC_SocialTraits.lua"))

local StartingTraits = require "PNC/Core/Traits/PNC_StartingCompanionTraits"
local Session = require "PNC/CharacterCreation/PNC_StartingCompanionSession"
local Authoring = require "PNC/Core/Identity/PNC_NPCAuthoring"
local Customization = require
    "PNC/Core/Identity/PNC_StartingCompanionCustomization"
local Blueprint = Authoring.Blueprint
local TID = StartingTraits.IDS

local function context(surname, female, orientation)
    return {
        playerSurname = surname,
        playerFemale = female,
        orientation = orientation,
        playerAppearance = {
            skinTexture = "FemaleBody02",
            skinColor = { r = 0.4, g = 0.3, b = 0.2 },
            hairColor = { r = 0.1, g = 0.1, b = 0.1 },
        },
    }
end

local session = Session.New({
    sessionSeed = 111,
    context = context("Reyes", true, "straight"),
})
session:Reconcile(
    { TID.BROTHER, TID.IS_MARRIED },
    context("Reyes", true, "straight")
)
session:SetField(TID.BROTHER, "identity.forename", "Riley")
session:SetField(TID.BROTHER, "identity.nickname", "Rye")
session:ClearField(TID.BROTHER, "identity.nickname")
session:SetField(TID.BROTHER, "appearance", { outfit = { mode = "none" }, slots = {
    ["base:makeup_lips"] = { mode = "item", type = "Base.MakeUp_LipsPink" },
    Tshirt = { mode = "item", type = "Base.Tshirt_Rock", itemState = { visualDecal = "RockPrint" } },
} })

local envelope, reason = Customization.BuildEnvelope(
    session,
    { TID.BROTHER, TID.IS_MARRIED }
)
T.truthy(envelope, "starter envelope builds from the canonical session")
T.equal(envelope.schemaId, Customization.SCHEMA_ID,
    "envelope has the explicit customization schema")
T.equal(envelope.registryFingerprint, Authoring.Registry.Fingerprint(),
    "envelope carries the canonical registry fingerprint")
T.equal(#envelope.slots, 2, "envelope contains only selected slots")

local decoded, decodeReason = Customization.DecodeEnvelope(envelope)
T.truthy(decoded, "compact starter envelope decodes atomically")
T.equal(decoded.selectedTraitIDs[1], TID.BROTHER,
    "decoded slot IDs remain canonical strings")
T.equal(Blueprint.Get(decoded.blueprints[TID.BROTHER], "identity.forename"),
    "value", "compact codec preserves explicit values")
T.equal(Blueprint.Get(decoded.blueprints[TID.BROTHER], "identity.nickname"),
    "clear", "compact codec preserves explicit clears")
T.equal(Customization.Fingerprint(envelope), envelope.fingerprint,
    "envelope fingerprint is deterministic metadata")

local badFingerprint = Authoring.Registry.Copy(envelope)
badFingerprint.registryFingerprint = "registry:v1:incompatible"
local rejected, rejectedReason = Customization.DecodeEnvelope(badFingerprint)
T.falsy(rejected, "registry mismatch rejects the complete envelope")
T.equal(rejectedReason, "customization_registry_fingerprint_mismatch",
    "registry mismatch is explicit")

local badAuthority = Authoring.Registry.Copy(envelope)
badAuthority.runtimeNPCID = "spoofed-runtime-id"
rejected, rejectedReason = Customization.DecodeEnvelope(badAuthority)
T.falsy(rejected, "authority keys are not accepted by the envelope")
T.truthy(rejectedReason and string.find(rejectedReason, "key_invalid", 1, true),
    "spoofed authority is rejected before decode")

local conflict = Authoring.Registry.Copy(envelope)
conflict.slots[1].blueprint.clears[2] = true
conflict.fingerprint = nil
rejected, rejectedReason = Customization.DecodeEnvelope(conflict)
T.falsy(rejected, "a compact value and clear conflict is rejected")
T.equal(rejectedReason, "compact_value_clear_conflict",
    "compact conflict has an explicit reason")

local sanitized, report = Customization.SanitizeBlueprint(
    Blueprint.Set(
        Blueprint.New({ id = "starter:" .. TID.BROTHER }),
        "identity.surname",
        "Spoofed"
    ),
    StartingTraits.GetDefinition(TID.BROTHER)
)
T.truthy(sanitized, "server sanitizer accepts the canonical blueprint shape")
T.equal(Blueprint.Get(sanitized, "identity.surname"), "absent",
    "mandatory surname intent is removed before authoritative resolution")
T.equal(report.rebound[1], "identity.surname",
    "sanitizer reports the relationship rebinding")

local family = assert(Customization.SanitizeBlueprint(
    decoded.blueprints[TID.BROTHER], StartingTraits.GetDefinition(TID.BROTHER)))
local _, familyOutfit = Blueprint.Get(family, "appearance")
T.equal(familyOutfit.slots["base:makeup_lips"].type, "Base.MakeUp_LipsPink", "family inheritance keeps equipped makeup")
T.equal(familyOutfit.slots.Tshirt.itemState.visualDecal, "RockPrint", "family inheritance keeps clothing variants")

local clock = 100000
local oldNow = PNC.Core and PNC.Core.Now
PNC.Core = PNC.Core or {}
PNC.Core.Now = function() return clock end
PNC.PlayerCharacters = {
    GetCharacterUUID = function(player) return player.uuid end,
}
PNC.StartingCompanions = {
    Ensure = function(_, _, _, options)
        local value = options and options.blueprints
            and options.blueprints[TID.BROTHER] or nil
        if value then
            local _, outfit = Blueprint.Get(value, "appearance")
            T.equal(outfit.slots["base:makeup_lips"].type, "Base.MakeUp_LipsPink",
                "server grant receives the makeup through the validated envelope")
        end
        return true, "granted", { customized = value ~= nil }
    end,
}
local originalSelections = StartingTraits.ResolveSelections
StartingTraits.ResolveSelections = function()
    return {
        StartingTraits.GetDefinition(TID.BROTHER),
        StartingTraits.GetDefinition(TID.IS_MARRIED),
    }, "selected"
end
package.loaded["PNC/Companions/PNC_StartingCompanionCustomizationService"] = nil
local Service = require
    "PNC/Companions/PNC_StartingCompanionCustomizationService"
Service.Reset()

local player = { uuid = "char_customization" }
local state = Service.Begin(player, player.uuid, 42)
T.equal(state.phase, Service.PHASE_PENDING,
    "creation begins in the bounded pending state")
T.equal(state.createdAt, clock,
    "customization deadline uses the server millisecond clock")
local pending, pendingReason = Service.Ensure(player, player.uuid, clock)
T.falsy(pending, "missing payload does not block character creation")
T.equal(pendingReason, "customization_pending",
    "payload has a bounded pending window")

local received, receivedReason = Service.Receive(player, envelope)
T.truthy(received, "payload received before the deadline is retained")
T.equal(receivedReason, "validated",
    "payload is validated against actual selected traits")
local granted, grantedReason = Service.Ensure(player, player.uuid, clock)
T.truthy(granted, "validated payload reaches the starter grant owner")
T.equal(grantedReason, "granted", "starter owner result is preserved")
T.equal(Service.GetState(player.uuid).phase, Service.PHASE_GRANTS_COMPLETE,
    "successful grants close the lifecycle")
local duplicate = Service.Ensure(player, player.uuid, clock)
T.truthy(duplicate, "reconnect is idempotent")

Service.Reset()
StartingTraits.ResolveSelections = function()
    return { StartingTraits.GetDefinition(TID.BROTHER) }, "selected"
end
local invalidEnvelope = Authoring.Registry.Copy(envelope)
invalidEnvelope.slots[1].traitID = TID.FRIEND
local invalidAccepted = Service.Receive(player, invalidEnvelope)
T.falsy(invalidAccepted, "a slot for an unselected trait is rejected")
T.equal(Service.GetState(player.uuid).phase, Service.PHASE_DEFAULTED,
    "invalid customization atomically falls back to default")

Service.Reset()
clock = 200000
Service.Begin(player, player.uuid, 42)
local beforeTimeout = Service.Ensure(player, player.uuid, clock)
T.falsy(beforeTimeout, "timeout fallback waits only for the bounded window")
clock = 200000 + Service.TIMEOUT_MS + 1
local fallback, fallbackReason = Service.Ensure(player, player.uuid, clock)
T.truthy(fallback, "timeout falls back to deterministic starter generation")
T.equal(fallbackReason, "granted", "fallback preserves starter grant status")
T.equal(Service.GetState(player.uuid).phase, Service.PHASE_GRANTS_COMPLETE,
    "fallback reaches grants complete")

StartingTraits.ResolveSelections = originalSelections
if oldNow then PNC.Core.Now = oldNow end

T.finish("pnc_starting_companion_customization_smoke")
