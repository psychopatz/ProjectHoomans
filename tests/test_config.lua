-- Standalone fallback used when a test is invoked directly with `lua`.
-- The Python runner discovers the newest packaged runtime and overrides these
-- values through the environment, so normal version upgrades need no test edits.
return {
    projectHoomansRuntime = "42.20",
    psychopatzCoreRuntime = "42.19",
    psychopatzCoreRepository = "../psychopatzCore",
}
