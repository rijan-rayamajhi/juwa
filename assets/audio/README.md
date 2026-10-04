# Juwa audio

All audio is bundled locally. No runtime downloads or external audio services.

## Third-party sound effects: CC0

Author: Kenney (Kenney Vleugels), https://kenney.nl.
Retrieved 2026-09-28. The original pack license texts are in `licenses/`.

| Bundled asset | Original file | Source |
| --- | --- | --- |
| sfx/click.wav | Audio/click_003.ogg (1 ms fades + 50 ms silent tail added) | https://kenney.nl/assets/interface-sounds |
| sfx/reel_stop.wav | Audio/chip-lay-1.ogg | https://kenney.nl/assets/casino-audio |
| sfx/wheel_tick.wav | Audio/chips-collide-1.ogg | https://kenney.nl/assets/casino-audio |

These packs are published under CC0 1.0. The files were converted from Ogg to
44.1 kHz mono PCM WAV for consistent iOS/Android support. Kenney's license allows
personal and commercial projects and does not require credit.
License: https://creativecommons.org/publicdomain/zero/1.0/

## Original procedural compositions and effects

`music/{lobby,fortune,fish,vampire,wheel,plinko}.m4a` and
`sfx/{win,big_win,drop,peg,error,reel_loop}.wav` were composed/synthesized for this
project with `tools/generate_audio.py`. They contain no external samples, existing
recordings, or quoted melodies. The source generator is included for editing and
regeneration; it requires Python, NumPy, and ffmpeg.

Music: 16-bar instrumental loops, 34–49 seconds each. Pitched instruments, bass,
soft percussion and wrapped stereo delay are synthesized mathematically. Musical
styles: lobby lounge, bright Fortune keys, aquatic Fish bells, minor-key Vampire
pads, rhythmic Wheel keys, and magical Plinko bells. Music playback fades in and
is mixed below event sounds. The original PCM loop boundary is periodic; AAC
encoder padding may vary by device decoder.

## Controls and event mapping

- Music setting: background soundtrack only.
- Vibration setting: haptic feedback only (independent of sound).
- Sound setting: button and game effects, including reel motor.
- App inactive/background: silence music, reels, and active effects.
- Navigation: stop the previous scene's music and restore the lobby on return.
- Reel motor starts on spin, stops on completion/quick-stop/exit.
- Reel stops, wheel pointer crossings, Plinko releases/impacts/landings, wins and
  insufficient-balance errors each have their own cue.
- Rapid impacts are throttled and each effect has at most three simultaneous voices.
- On iOS the ambient audio category respects the device's silent switch.
