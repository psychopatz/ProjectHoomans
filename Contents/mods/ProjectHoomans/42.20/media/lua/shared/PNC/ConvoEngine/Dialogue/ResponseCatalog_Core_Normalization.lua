-- ResponseCatalog variant normalization and fallback helpers.
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local ResponsePlan = require
    "PNC/ConvoEngine/Dialogue/ResponsePlan"

return function(Core)
    function Core.copy(value, depth)
        if type(value) ~= "table" then return value end
        depth = tonumber(depth) or 0
        if depth >= 6 then return nil end
        local output = {}
        local key
        local item
        for key, item in pairs(value) do
            if type(key) == "string" or type(key) == "number" then
                output[key] = Core.copy(item, depth + 1)
            end
        end
        return output
    end

    function Core.validID(value)
        value = tostring(value or "")
        return value ~= ""
            and #value <= 96
            and string.find(value, "[^%w_%.%-]") == nil
    end

    function Core.boundedText(value)
        value = tostring(value or "")
        if #value > 256 then return string.sub(value, 1, 256) end
        return value
    end

    function Core.registerTextFallback(templateID, fallback)
        local text = PsychopatzCore
            and PsychopatzCore.Conversation
            and PsychopatzCore.Conversation.Text
        if text and type(text.RegisterFallback) == "function" then
            text.RegisterFallback(templateID, fallback)
        end
    end

    local function contentFallback(templateID)
        local registry = PNC.ConvoEngine and PNC.ConvoEngine.Registry or nil
        if type(registry) ~= "table" then
            local loaded = require "PNC/ConvoEngine/Registry"
            registry = type(loaded) == "table" and loaded or nil
        end
        if type(registry) ~= "table"
            or type(registry.FamilyFor) ~= "function"
        then
            return nil
        end
        local _, phrases = registry.FamilyFor(templateID, "neutral")
        local phrase = type(phrases) == "table" and phrases[1] or nil
        if not (phrase and phrase.fallback and phrase.fallback ~= "") then
            local ConvoPlanFamily = PNC.ConvoEngine
                and PNC.ConvoEngine.ConvoPlanFamily or nil
            if type(ConvoPlanFamily) ~= "table" then
                local loaded = require "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"
                ConvoPlanFamily = type(loaded) == "table" and loaded or nil
            end
            if type(ConvoPlanFamily) == "table"
                and type(ConvoPlanFamily.install) == "function"
            then
                ConvoPlanFamily.install(templateID)
                _, phrases = registry.FamilyFor(templateID, "neutral")
                phrase = type(phrases) == "table" and phrases[1] or nil
            end
        end
        local fallback = phrase and phrase.fallback or nil
        return Core.boundedText(fallback)
    end

    local function contentOwnerForPool(poolID)
        poolID = tostring(poolID or "")
        if string.find(poolID, "semantic.compat.", 1, true) == 1 then
            return "projecthoomans.dialogue_content.compatibility"
        end
        if string.find(poolID, "semantic.tool_reply.", 1, true) == 1 then
            return "projecthoomans.dialogue_content.tool_replies"
        end
        if string.find(poolID, "semantic.command.", 1, true) == 1
            or string.find(poolID, "semantic.emote.", 1, true) == 1
            or string.find(poolID, "semantic.flow.greeting.", 1, true) == 1
        then
            return "projecthoomans.dialogue_content.commands_emotes"
        end
        if string.find(poolID, "semantic.medical.", 1, true) == 1
            or string.find(poolID, "semantic.combat.", 1, true) == 1
            or string.find(poolID, "semantic.leader_loss.", 1, true) == 1
            or string.find(poolID, "semantic.companion.", 1, true) == 1
            or string.find(poolID, "semantic.conversation.safety", 1, true) == 1
            or string.find(poolID, "semantic.corpse.", 1, true) == 1
            or string.find(poolID, "semantic.social.farewell.depart", 1, true) == 1
            or string.find(poolID, "semantic.social.reaction", 1, true) == 1
        then
            return "projecthoomans.dialogue_content.events"
        end
        return nil
    end

    local function normalizePlanContent(plan, templateID)
        if type(plan) ~= "table" or type(plan.turns) ~= "table" then
            return plan
        end
        for _, turn in ipairs(plan.turns) do
            for _, segment in ipairs(turn.segments or {}) do
                if type(segment) == "table" and segment.kind == "literal" then
                    local text = Core.boundedText(segment.text)
                    if text ~= "" then
                        segment.kind = "translation"
                        segment.templateID = templateID
                        segment.fallback = text
                        segment.args = {}
                        segment.text = nil
                    end
                end
            end
        end
        return plan
    end

    function Core.hash(value)
        local output = 0
        value = tostring(value or "")
        for index = 1, #value do
            output = (output * 31 + string.byte(value, index)) % 2147483647
        end
        return output
    end

    local function prepareVariant(poolID, index, value)
        if type(value) == "string" then
            value = { fallback = value }
        end
        if type(value) ~= "table" then
            return nil, "invalid_variant_definition", {
                poolID = tostring(poolID or ""),
                variantIndex = index,
            }
        end
        local templateID = tostring(value.templateID or value.id or "")
        local id = tostring(value.id or (poolID .. "." .. tostring(index)))
        local detail = {
            poolID = tostring(poolID or ""),
            variantIndex = index,
            templateID = templateID ~= "" and templateID or id,
            realizationID = id,
        }
        local fallback = Core.boundedText(value.fallback or value.text)
        if fallback == "" then fallback = contentFallback(templateID) end
        if fallback == "" then
            return nil, "unresolved_template_fallback", detail
        end
        if not Core.validID(id) then
            return nil, "invalid_variant_id", detail
        end
        local plan
        if value.plan ~= nil then
            local valid, normalized, planReason = ResponsePlan.Build(value.plan)
            if not valid then
                return nil, tostring(planReason or "invalid_response_plan"), detail
            end
            plan = normalizePlanContent(normalized, tostring(
                value.templateID or id
            ))
        end
        local contentOwner = value.contentOwner or contentOwnerForPool(poolID)
        local when = Core.copy(value.when)
        return {
            id = id,
            templateID = templateID ~= "" and templateID or id,
            fallback = fallback,
            plan = plan,
            dialogueAct = value.dialogueAct,
            topic = value.topic,
            groundedFactRefs = Core.copy(
                value.groundedFactRefs or value.sourceFactRefs
            ),
            uncertainty = value.uncertainty,
            tone = value.tone,
            personalityStyle = value.personalityStyle,
            contentOwner = contentOwner,
            translationArgs = Core.copy(value.translationArgs),
            when = when,
            _whenKeys = Core.compileWhenKeys(when),
            _whenCompiled = true,
            priority = tonumber(value.priority) or 0,
        }, nil, detail
    end

    function Core.validateVariant(poolID, index, value)
        return prepareVariant(poolID, index, value)
    end

    function Core.normalizedVariant(poolID, index, value)
        local normalized, reason, detail = prepareVariant(poolID, index, value)
        if not normalized then return nil, reason, detail end
        Core.registerTextFallback(normalized.templateID, normalized.fallback)
        return normalized, nil, detail
    end

    function Core.install(Catalog)
        Catalog.VERSION = 1
        Catalog.MAX_POOLS = nil
        Catalog.MAX_VARIANTS = 32
        Catalog.MAX_LAST_VARIANTS = 512
        Catalog.POOLS = Catalog.POOLS or {}
        Catalog.POOL_COUNT = tonumber(Catalog.POOL_COUNT) or 0
        Catalog.REVISION = Catalog.REVISION or 0
        Catalog.REGISTRATION_ORIGINS = Catalog.REGISTRATION_ORIGINS or {}
        Catalog.LAST_VARIANTS = Catalog.LAST_VARIANTS or {}
        Catalog.LAST_VARIANT_ORDER = Catalog.LAST_VARIANT_ORDER or {}
        Catalog._lastVariantHead = tonumber(Catalog._lastVariantHead) or 1
        Catalog._lastVariantCount = tonumber(Catalog._lastVariantCount) or 0
    end

    return Core
end
