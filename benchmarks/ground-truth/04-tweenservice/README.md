# 04 — TweenService

Smooth property animations using `TweenService`. Used for UI transitions,
object movement, color changes, and visual polish.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-basic-tween-position.luau` | client | Move a GUI element from one position to another |
| 02 | `02-tween-with-easing.luau` | client | Tween a part's transparency with a custom easing style |
| 03 | `03-sequence-tweens.luau` | client | Chain multiple tweens using `Completed` event |

## Key APIs

- `TweenService:Create(instance, tweenInfo, properties)`
- `TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)`
- `Tween:Play()`
- `Tween:Pause()` / `Tween:Cancel()`
- `Tween.Completed` event

## Structural Patterns

### Basic Tween
```luau
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tween = TweenService:Create(guiElement, tweenInfo, {Position = targetPosition})
tween:Play()
```

### Chained Tweens
```luau
local tween1 = TweenService:Create(obj, info1, props1)
local tween2 = TweenService:Create(obj, info2, props2)
tween1:Play()
tween1.Completed:Wait()
tween2:Play()
```

## Common Pitfalls
- `TweenService` is typically used client-side (for visual effects)
- `TweenInfo.new` arguments must be in correct order
- EasingStyle and EasingDirection must be valid `Enum` values
- Tweens only work on Instances with the properties being animated
- Forgetting to call `:Play()` — tweens don't auto-play
