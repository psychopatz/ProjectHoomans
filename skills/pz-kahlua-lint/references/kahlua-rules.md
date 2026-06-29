# PZ Kahlua Lua Compatibility Rules

Project Zomboid uses **Kahlua2** — a Lua 5.1 interpreter written in Java.
This document lists every rule enforced by `pz_kahlua_lint.py` with rationale.

---

## Error Rules (KAHL-E*)

These will crash or fail silently at runtime.

| Rule ID     | Pattern / Feature              | Lua Version | Notes |
|-------------|-------------------------------|-------------|-------|
| KAHL-E001   | `goto <label>`                | 5.2+        | Kahlua has no goto; refactor with if/else or break |
| KAHL-E002   | `::label::`                   | 5.2+        | goto labels, same restriction |
| KAHL-E003   | `//` floor division            | 5.3+        | Use `math.floor(a / b)` |
| KAHL-E004   | `&` bitwise AND                | 5.3+        | Use `bit.band()` or arithmetic |
| KAHL-E005   | `\|` bitwise OR                | 5.3+        | Use `bit.bor()` |
| KAHL-E006   | `~` bitwise NOT/XOR            | 5.3+        | `~=` (inequality) is still valid Lua 5.1 |
| KAHL-E007   | `>>` / `<<` bitwise shift      | 5.3+        | Use `bit.rshift()` / `bit.lshift()` |
| KAHL-E008   | `table.pack()`                 | 5.2+        | Use `local t = {...}` |
| KAHL-E009   | `table.unpack()`               | 5.2+        | Use `unpack()` (Lua 5.1 global) |
| KAHL-E010   | `table.move()`                 | 5.3+        | Implement a manual loop |
| KAHL-E011   | `rawlen()`                     | 5.2+        | Use `#` operator |
| KAHL-E012   | `math.type()`                  | 5.3+        | Use `type()` — no integer subtype in 5.1 |
| KAHL-E013   | `math.tointeger()`             | 5.3+        | Use `math.floor()` |
| KAHL-E014   | `string.pack/unpack/packsize`  | 5.3+        | Manual bit arithmetic |
| KAHL-E015   | `utf8.*`                       | 5.3+        | Use `string.*` byte functions |
| KAHL-E016   | `coroutine.*`                  | Kahlua N/A  | Use PZ `Events.*` or state machines |
| KAHL-E017   | `io.*`                         | Sandboxed   | Use `getModFileWriter/Reader` |
| KAHL-E018   | `os.*`                         | Sandboxed   | Use `getGameTime()` |
| KAHL-E019   | `debug.*`                      | Sandboxed   | Use `print()` for logging |
| KAHL-E020   | `package.*`                    | Sandboxed   | PZ auto-loads lua files |
| KAHL-E021   | `require()`                    | Sandboxed   | PZ auto-loads lua files |
| KAHL-E022   | `dofile()` / `loadfile()`      | Sandboxed   | PZ auto-loads lua files |
| KAHL-E023   | `!=`                           | Not Lua     | Use `~=` for inequality |
| KAHL-E024   | `continue`                     | Not Lua     | Use `repeat/until false` with break, or restructure |

---

## Warning Rules (KAHL-W*)

These may work in some contexts but indicate problems or deprecated usage.

| Rule ID     | Pattern / Feature              | Notes |
|-------------|-------------------------------|-------|
| KAHL-W001   | `load(string)`                | In Lua 5.1/Kahlua use `loadstring()`; `load()` signature changed in 5.2 |
| KAHL-W002   | `table.getn()`                | Deprecated since Lua 5.1; use `#` operator |
| KAHL-W003   | `string.len()`                | Works but `#s` is idiomatic Lua |
| KAHL-W004   | `setfenv()`/`getfenv()`       | Lua 5.1 only; verify Kahlua implements them |
| KAHL-W005   | `pcall()` with no args         | Called with no function — likely a bug |
| KAHL-W006   | Top-level `function foo()`     | Creates global; prefer module table pattern |
| KAHL-W007   | Top-level `varName = value`    | Creates/modifies global; add `local` |

---

## Info Rules (KAHL-I*)

Informational notices — these are correct patterns, just worth flagging.

| Rule ID     | Pattern                        | Notes |
|-------------|-------------------------------|-------|
| KAHL-I001   | `unpack()`                    | Correct for Kahlua/Lua 5.1 (not `table.unpack`) |
| KAHL-I002   | `loadstring()`                | Correct for Kahlua/Lua 5.1 |
| KAHL-I003   | `Events.*.Add()`              | PZ event hook — verify event name spelling |

---

## Kahlua2 vs Standard Lua 5.1 Differences

Kahlua2 is not 100% compatible with PUC Lua 5.1. Known gaps:

- **No debug library** — `debug.*` is stripped from the runtime
- **No coroutine library** — coroutine scheduling not implemented
- **Sandboxed stdlib** — `io`, `os`, `package` are not exposed
- **Java object interop** — PZ methods are called with `:` (colon), not `.`
- **`instanceof(obj, "ClassName")`** — PZ-specific function for Java class checks
- **`luautils.*`** — PZ utility namespace (split, etc.)
- **`getCell()`, `getPlayer()`, etc.** — PZ global Java bridges

---

## Common PZ Lua Patterns

### Correct loop without continue
```lua
-- Lua has no continue; use this pattern
for i = 1, #items do
    local item = items[i]
    if shouldSkip(item) then
        -- body to execute when NOT skipping
    else
        processItem(item)
    end
end
```

### Correct varargs collection (Lua 5.1)
```lua
local function myFunc(...)
    local args = {...}         -- collect varargs
    local count = select('#', ...) -- count (handles nils)
    -- NOT: table.pack(...)
end
```

### Correct table unpacking (Lua 5.1)
```lua
local t = {10, 20, 30}
someFunc(unpack(t))        -- correct in Kahlua
-- NOT: someFunc(table.unpack(t))
```

### Safe bitwise operations
```lua
-- PZ does NOT have the bit library by default, but you can use arithmetic:
local function band(a, b)    -- AND via arithmetic
    local result = 0
    local bit = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then result = result + bit end
        a, b = math.floor(a / 2), math.floor(b / 2)
        bit = bit * 2
    end
    return result
end
```

### Checking Java object types
```lua
-- Correct PZ pattern
if instanceof(item, "InventoryItem") then
    -- ...
end
```

### File I/O in PZ (not io.*)
```lua
-- Server-side file writing
local writer = getModFileWriter("MyMod", "data.txt", true)
writer:write("hello\n")
writer:close()
```
