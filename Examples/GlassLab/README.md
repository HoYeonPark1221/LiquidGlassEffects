# GlassLab

A playground for [LiquidGlassEffects](../..): pick any of the 24 variants and 53 subvariants, change the shape and tint, drag the glass over a backdrop or your own image, and copy the Swift that produces it.

```sh
swift run
```

Use macOS 26 or later: that is where the real glass exists. The window opens on macOS 14 and 15, but you only see the blur fallback there, so there is little to look at, and CI builds the demo on macOS 26 only. Keep the window active, because glass renders flat in an inactive one.

To build a double-clickable `GlassLab.app`, run `Scripts/make-demo-app.sh` from the repository root.

## Recording the tour

`GLASSLAB_AUTOPILOT=1 swift run` plays a looping tour with no controls, the one in the README. `GLASSLAB_STOP=3` stays on one stop of it, and `GLASSLAB_FRAME_FILE=/tmp/frame` draws exactly the frame number written in that file, so a script can step through the tour and screenshot each frame.
