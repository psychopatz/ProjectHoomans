-- Colony journal requests are cursor-based and never rebuild the management
-- snapshot. The feed itself enforces the bounded query and ownership filter.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Network = PNC.Network

Router.Register(Const.CMD_COLONY_JOURNAL_REQUEST, function(player, args)
    local feed = PNC.ColonyJournalFeed
    local delta = feed and feed.GetDelta
        and feed.GetDelta(player, args) or {
            v = PNC.ColonyJournalProtocol.VERSION,
            error = "journal_unavailable",
        }
    Network.SendColonyJournal(player, delta)
end)
