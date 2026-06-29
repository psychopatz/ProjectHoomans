---
name: mod-location-extractor
description: Extracts the local Steam Workshop directory path for a specified Project Zomboid mod. Use when you need to locate or inspect code/mechanics from another mod (e.g., Bandit mod).
---

# Mod Location Extractor

This skill provides a reliable way to find the physical file path of a installed Steam Workshop mod for Project Zomboid. It utilizes a custom script to search the Steam Workshop content directory for the requested mod folder and parses the `mod.info` to provide clear, sanitized details.

## When to use this skill

- When the user asks you to implement mechanics, look up files, or reference another installed mod (e.g., "implement bandit mod's mechanics").
- When you need to know the absolute directory path of a specific mod to examine its Lua source code or assets using tools like `view_file` or `find_by_name`.

## How to use it

Run the provided script using the `run_command` tool, passing the name of the mod as an argument. The script does a case-insensitive search.

**Example Command:**
```bash
bash /home/psychopatz/Zomboid/Workshop/DynamicTrading/.agent/skills/mod-location-extractor/scripts/find_mod.sh "bandit"
```

### Next Steps After Using

1. The script will output the matching mod directories along with their actual name, ID, and description parsed from `mod.info`.
2. **Multiple Results Handling:** If the script finds multiple matching mods and it's unclear which one the user intended, YOU MUST STOP AND ASK THE USER to clarify which specific mod they meant from the provided list, using the `notify_user` tool. Do not guess if there is significant ambiguity.
3. Once the correct path is confirmed, you can use your usual file analysis tools (`semble`,`find_by_name`, `grep_search`, `view_file`) targeting that specific output path to analyze the mod's architecture and source code.
