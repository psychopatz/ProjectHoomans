-- Client-side recruited-companion root choice provider.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local Companion = {}

local SYSTEM_SOURCE = Internal.MenuSystemSource
local dialoguePayload = Internal.MenuDialoguePayload

local function setPreviewRequirement(context, highlighted, requirement)
    local relationship = Conversation.Relationship
        or PNC.Conversation.Relationship
    if relationship and relationship.SetPreviewRequirement then
        local ok, reason = relationship.SetPreviewRequirement(
            context.npcID,
            highlighted and requirement or "inspect"
        )
        if not ok and PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "Conversation relationship preview unavailable npc="
                    .. tostring(context.npcID or "")
                    .. " reason=" .. tostring(reason or "unknown")
            )
        end
    end
end

local function appendUnrecruitedChoices(choices, context)
    if context.settlementVisit
        and context.settlementVisit.active == true
    then
        choices[#choices + 1] = {
            id = "settlement_admission",
            text = dialoguePayload(
                SYSTEM_SOURCE,
                "choice.settlement_admission",
                context
            ),
            action = function()
                Composer.RequestSettlementAdmission(context.npcID)
            end,
        }
        return
    end

    if context.ambientVisitPreview
        and context.ambientVisitPreview.eligible == true
    then
        choices[#choices + 1] = {
            id = "ambient_visit",
            text = dialoguePayload(
                SYSTEM_SOURCE,
                "choice.ambient_visit",
                context
            ),
            action = function()
                Composer.RequestAmbientVisit(context.npcID)
            end,
        }
    end

    choices[#choices + 1] = {
        id = "recruit",
        text = dialoguePayload(
            SYSTEM_SOURCE, "choice.recruit", context
        ),
        onHighlightChanged = function(_, highlighted)
            setPreviewRequirement(context, highlighted, "recruit")
        end,
        action = function()
            setPreviewRequirement(context, true, "recruit")
            Composer.RequestRecruit(context.npcID)
        end,
    }
end

local function appendRecruitedChoices(choices, context)
    local function departurePreview(highlighted)
        setPreviewRequirement(context, highlighted, "departure")
    end
    if context.pendingDepartureWarning == true then
        choices[#choices + 1] = {
            id = "disband_confirm",
            text = dialoguePayload(
                SYSTEM_SOURCE, "choice.disband_confirm", context
            ),
            onHighlightChanged = function(_, highlighted)
                departurePreview(highlighted)
            end,
            action = function()
                departurePreview(true)
                Composer.RequestDeparture(context.npcID, true)
            end,
        }
        choices[#choices + 1] = {
            id = "disband_cancel",
            text = dialoguePayload(
                SYSTEM_SOURCE, "choice.disband_cancel", context
            ),
            next = "menu",
            action = function()
                context.pendingDepartureWarning = nil
                local view = Internal.ActiveView(context.npcID)
                if view and view.spec and view.spec.context then
                    view.spec.context.pendingDepartureWarning = nil
                end
            end,
        }
        return
    end

    choices[#choices + 1] = {
        id = "disband",
        text = dialoguePayload(
            SYSTEM_SOURCE, "choice.disband", context
        ),
        onHighlightChanged = function(_, highlighted)
            departurePreview(highlighted)
        end,
        action = function()
            departurePreview(true)
            Composer.RequestDeparture(context.npcID, false)
        end,
    }
end

function Companion.Append(choices, context)
    local record = context.npcRecord or {}
    local verifier = PNC.Identity and PNC.Identity.Verifier or nil
    local ownership = verifier
        and verifier.BuildOwnershipSummary
        and verifier.BuildOwnershipSummary(context.entry)
        or nil
    local recruited = ownership
        and (ownership.recruited or ownership.colonyOwned)
        or record.recruited == true
    if recruited then
        appendRecruitedChoices(choices, context)
    else
        appendUnrecruitedChoices(choices, context)
    end
end

Internal.MenuRootCompanionChoices = Companion

return Companion
