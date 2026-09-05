local T = require "tests/support/test"

T.addPackagePaths()

local clock = 100
PNC = {
    Const = { CMD_COLONY_JOURNAL = "colony_journal" },
    Core = { Now = function() clock = clock + 1; return clock end },
    Client = { Internal = {} },
    Network = {
        ClientState = {
            colonyJournal = { rows = {} },
            colonyJournalRevision = 0,
        },
    },
}

local handlers = {}
function PNC.Client.Internal.RegisterServerCommand(command, handler)
    if command then handlers[command] = handler end
end

T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Colony.lua")

local apply = PNC.Client.Internal.ApplyColonyJournal
local row = function(sequence) return { sequence, sequence, 1, 3, "npc", "NPC" } end
apply({ rows = { row(1), row(2) }, nextCursor = 2, latestSequence = 2 })

local journal = PNC.Network.ClientState.colonyJournal
T.equal(journal.rows[1][1], 2, "latest journal row is first")
T.equal(journal.rows[2][1], 1, "older journal row follows latest")
local revision = PNC.Network.ClientState.colonyJournalRevision

apply({
    rows = { row(1), row(2) },
    afterCursor = 2,
    nextCursor = 2,
    latestSequence = 2,
})
T.equal(#journal.rows, 2,
    "replayed journal page does not duplicate rows")
local replayRevision = PNC.Network.ClientState.colonyJournalRevision
apply({
    rows = { row(1) },
    afterCursor = 0,
    nextCursor = 1,
    latestSequence = 2,
})
T.equal(#journal.rows, 2,
    "older journal response is ignored")
T.equal(PNC.Network.ClientState.colonyJournalRevision, replayRevision,
    "older journal response does not redraw the journal")

apply({ rows = {}, nextCursor = 2, latestSequence = 2 })
T.equal(PNC.Network.ClientState.colonyJournalRevision, revision,
    "empty polling response does not redraw the journal")

apply({ rows = { row(3) }, nextCursor = 3, latestSequence = 3 })
T.equal(journal.rows[1][1], 3, "newly received row is prepended")
T.equal(journal.rows[2][1], 2, "previous latest row moves down")
T.truthy(handlers.colony_journal, "journal command handler is registered")

T.finish("pnc_colony_journal_client_order_smoke")
