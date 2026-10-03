-- Client-side conversation lifecycle factory composition root.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Lifecycle = PNC.Conversation.Lifecycle or {}
local Lifecycle = PNC.Conversation.Lifecycle
local H = Lifecycle.Internal or {}

require "PNC/Conversation/PNC_ConversationLifecycle_Create_Begin"
require "PNC/Conversation/PNC_ConversationLifecycle_Create_Update"
require "PNC/Conversation/PNC_ConversationLifecycle_Create_Finish"

local begin = H.CreateBegin
local update = H.CreateUpdate
local finish = H.CreateFinish
if not H.CurrentTime or not H.Refresh or not H.ClearWorkingContext
    or not begin or not update or not finish
then
    return Lifecycle
end

function Lifecycle.Create()
    return {
        begin = begin,
        update = update,
        finish = finish,
    }
end

return Lifecycle
