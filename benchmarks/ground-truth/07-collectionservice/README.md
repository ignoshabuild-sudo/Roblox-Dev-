# 07 — CollectionService

Tag-based object management for grouping and identifying instances at runtime.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-tag-objects.luau` | server | Add a tag to an object and find all tagged objects |
| 02 | `02-react-to-tag.luau` | server | Listen for when objects get a specific tag added |
| 03 | `03-tag-based-damage.luau` | server | Apply damage multiplier to all objects with a "Boss" tag |

## Key APIs

- `CollectionService:AddTag(instance, tag)`
- `CollectionService:GetTagged(tag)`
- `CollectionService:GetInstanceAddedSignal(tag)`
- `CollectionService:HasTag(instance, tag)`

## Common Pitfalls
- Tags are case-sensitive
- `GetInstanceAddedSignal` only fires for future additions, not existing
- Tags persist across sessions if the instance is saved
