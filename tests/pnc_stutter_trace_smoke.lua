local T = require "tests/support/test"

T.addPackagePaths()
PNC = {}
require "PNC/Core/Diagnostics/PNC_StutterTrace"

local Trace = assert(PNC.StutterTrace, "PNC.StutterTrace missing")

-- 1. Off by default and no-op when disabled.
T.equal(Trace.Enabled, false, "StutterTrace must be off by default")
Trace.BeginTick(1000)
Trace.Record("acceptedHits", 5)
Trace.EndTick(1000, 99.0)
T.equal(#Trace.GetRecentFrames(), 0, "disabled trace must not record frames")
T.equal(#Trace.GetSpikeWindows(), 0, "disabled trace must not retain spike windows")

-- 2. When enabled, captures bounded pre -> spike -> post windows on threshold.
Trace.Reset()
Trace.SetEnabled(true, 16)
for i = 1, 10 do
    local t = 2000 + i * 50
    Trace.BeginTick(t)
    if i == 5 then
        Trace.Record("acceptedHits", 6)
        Trace.Record("woundMutations", 6)
        Trace.Record("witnessScans", 1)
    end
    Trace.EndTick(t, i == 5 and 28.5 or 2.0)
end

local frames = Trace.GetRecentFrames()
T.equal(#frames, 10, "recorded 10 recent frames")
local spikes = Trace.GetSpikeWindows()
T.equal(#spikes, 1, "exactly 1 spike window captured")
T.equal(#spikes[1].pre, Trace.PreWindowFrames, "captured bounded pre-spike frames")
T.equal(#spikes[1].post, Trace.PostWindowFrames, "captured bounded post-spike frames")
T.equal(spikes[1].spike.serverUpdateMs, 28.5, "spike duration preserved")
T.equal(spikes[1].spike.acceptedHits, 6, "spike acceptedHits counter preserved")
T.equal(spikes[1].spike.woundMutations, 6, "spike woundMutations counter preserved")
T.truthy(Trace.FormatRecentSpikes():find("ms=28.50", 1, true), "formatted summary includes spike ms")

-- 3. Bounded memory: ring and spike window count stay capped.
for i = 1, 80 do
    local t = 5000 + i * 50
    Trace.BeginTick(t)
    Trace.EndTick(t, 25.0)
end
T.equal(#Trace.GetRecentFrames(), Trace.RingCapacity, "ring buffer bounded to RingCapacity")
T.equal(#Trace.GetSpikeWindows(), Trace.MaxSpikeWindows, "spike windows bounded to MaxSpikeWindows")

-- 4. Clean disable.
Trace.SetEnabled(false)
T.equal(Trace.Enabled, false, "StutterTrace disables cleanly")

T.finish("pnc_stutter_trace_smoke")
