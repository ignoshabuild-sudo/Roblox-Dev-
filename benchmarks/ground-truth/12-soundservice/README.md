# 12 — SoundService / Sounds

Audio playback and management for music, SFX, and ambient sounds.

## Expected Ground-Truth Scripts (2–3 scripts)

| # | Script | Context | Description |
|---|--------|---------|-------------|
| 01 | `01-play-sound.luau` | client | Create and play a Sound object |
| 02 | `02-sound-with-fade.luau` | client | Play a sound with volume fade in/out |
| 03 | `03-background-music.luau` | client | Loop background music with SoundService |

## Key APIs

- `Instance.new("Sound")`
- `Sound:Play()`, `Sound:Pause()`, `Sound:Stop()`
- `Sound.Volume`, `Sound.PlaybackSpeed`, `Sound.Looped`
- `SoundService:PlayLocalSound(sound)`

## Common Pitfalls
- Sounds must have a valid `SoundId` (rbxassetid://...)
- Sound objects need to be parented to a part or SoundService to play
- Looped sounds need `Sound.Looped = true`
- Client-side sounds should use local Sound objects or SoundService
