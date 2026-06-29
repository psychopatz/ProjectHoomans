---
name: skill-creator
description: Creates new skills for the agent following standard conventions and folder structure. Use when asked to create, define, or document a new skill.
---

# Skill Creator

This skill provides step-by-step guidance, conventions, and patterns the agent should follow when creating new skills. A skill helps standardise capabilities, providing necessary context and instructions to perform repeatable tasks.

## When to use this skill

- Use this when the user specifically asks you to "create a skill", "add a skill", or teach you a new capability.
- This is helpful for ensuring all generated skills conform to the expected uniform directory structure and formatting conventions.

## How to use it

### 1. Identify the Skill Context

- Determine the appropriate name for the skill (lowercase, hyphens for spaces).
- Formulate a clear third-person description containing keywords that help you recognize when the skill should be applied in the future (e.g., "Generates unit tests for Python code using pytest conventions").

### 2. Set Up the Folder Structure

- Identify the correct root skill directory in the workspace (commonly `.agent/skills/` or within a specific sub-project like `Contents/mods/ModName/.agent/skills/`).
- Create a folder for the skill: `.agent/skills/<skill-name>/`
- *Optional*: If the skill requires them, create additional directories for `scripts/`, `examples/`, or `resources/`.

### 3. Create the SKILL.md File

Create the main instruction file inside the skill's folder: `.agent/skills/<skill-name>/SKILL.md`.
Every `SKILL.md` file MUST start with YAML frontmatter:

```yaml
---
name: <skill-name>
description: <A clear description of what the skill does and when to use it.>
---
```

### 4. Write the Skill Instructions

Structure the body of the `SKILL.md` document clearly so that it's easy for an agent to parse and follow in the future.

Include the following sections:

- **`# <Human Readable Skill Name>`**: A brief introduction to the skill.
- **`## When to use this skill`**: Bullet points detailing exactly when the skill applies.
- **`## How to use it`**: Step-by-step instructions, constraints, and patterns the agent must follow. Provide code references, examples, and any specific caveats they need to be aware of.

### 5. Validate

- Ensure the file is saved as `SKILL.md` (exactly matching the casing).
- Ensure the YAML frontmatter is present at the very top of the file.
- Confirm that the description clearly outlines when the agent should trigger the skill.
