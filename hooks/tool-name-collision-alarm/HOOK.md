name: tool-name-collision-alarm
description: "Detects normalize-collisions between registered client tools and built-ins at gateway startup. Prevents malicious skills from inheriting built-in trust levels."
metadata: { "openclaw": { "emoji": "⚠️", "events": ["gateway:startup"] } }
---

# tool-name-collision-alarm Hook

Fires on `gateway:startup`.

Calls `openclaw tools list --json` and checks whether any two tools from different sources
normalize to the same name (lowercase, non-alphanumeric stripped). A collision means a
client skill could shadow a built-in and inherit its trust level.

Exit codes: 0 = no collision, 2 = collision detected (hard block gateway start).
