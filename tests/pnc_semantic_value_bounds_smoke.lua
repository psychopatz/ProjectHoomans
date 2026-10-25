local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local ValueBounds = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticValueBounds.lua"
)

local source = {
    nested = { value = "kept" },
    callback = function() end,
}
local copied = ValueBounds.Copy(source)
T.truthy(copied ~= source, "copy creates a new table")
T.equal(copied.nested.value, "kept", "copy preserves nested values")
T.equal(copied.callback, nil, "copy omits function values")

local deep = { value = "too deep" }
for _ = 1, 10 do deep = { child = deep } end
T.equal(ValueBounds.Copy(deep, 10), nil,
    "copy stops at the configured depth")
T.equal(ValueBounds.Copy(deep, 0, 6).child.child.child.child.child.child, nil,
    "copy accepts a caller-owned depth bound")

T.equal(ValueBounds.Text("abcdef", 3), "abc",
    "text applies the requested maximum")
T.equal(ValueBounds.Text(nil, nil, 4), "",
    "text preserves empty-value semantics")

T.finish("pnc_semantic_value_bounds_smoke")
