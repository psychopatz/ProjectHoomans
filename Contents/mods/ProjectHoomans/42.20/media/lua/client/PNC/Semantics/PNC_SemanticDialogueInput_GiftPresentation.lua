-- Client presentation adapter for semantic gift item selection.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local audit = Internal.Audit or function() return false end

function Internal.GiftResponse(templateID, fallback, args)
    return {
        key = templateID,
        domain = "pnc.system.shared.categories",
        text = fallback,
        fallback = fallback,
        args = args,
    }
end

local function giftConversationContext(view)
    local root = view and view.spec and view.spec.context or nil
    if type(root) ~= "table" then return nil end
    root.giftConversationActive = true
    if type(root.conversationBlockContext) == "table" then
        root.conversationBlockContext.giftConversationActive = true
    end
    return root
end

function Internal.OpenGiftSelector(view, offer, context, reason)
    giftConversationContext(view)
    local window = PNC.InventoryWindow
    if not window or type(window.Open) ~= "function" then
        return {
            status = "gift_selector_unavailable",
            accepted = false,
            reason = "inventory_ui_unavailable",
            response = Internal.GiftResponse(
                "semantic.gift.selection_required",
                "I need to see what you brought me first."
            ),
        }
    end
    window.Open(context.npcID, {
        mode = "gift",
        token = context.conversationToken,
        giftIntent = offer,
        semantic = true,
    })
    audit("semantic.gift.selector_opened", {
        npcID = context.npcID,
        conversationID = context.conversationID,
        requestID = context.requestID,
        query = offer and offer.query,
        mode = offer and offer.mode,
        reason = reason,
    }, { requestID = context.requestID })
    return {
        status = "gift_selector_open",
        accepted = true,
        pending = true,
        reason = reason,
    }
end

return Input
