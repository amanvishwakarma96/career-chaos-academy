# Animation Performance Guidelines

## Goals
Motion should make Career Chaos Academy feel cinematic without blocking play or hurting low-end devices.

## Rules
- Keep route transitions under 350 ms.
- Keep scene transitions under 550 ms.
- Use preloaded raster images for backgrounds and characters.
- Keep Lottie JSON files small, loop-free for one-shot rewards, and below 100 KB where possible.
- Avoid stacking more than one heavy animation over a parallax background.
- Always respect `AnimationService.instance.reducedMotion`.

## Reduced Motion
Reduced motion must disable:
- Lottie playback
- background parallax
- character shake
- dramatic zoom
- route movement transitions
- typing animation

A static icon or fully revealed text should be shown instead.

## Low-End Android Profile
Test manually using:
- Android emulator with 2 GB RAM
- 60 Hz display
- Battery saver enabled
- Debug paints disabled

Check that:
- choice taps respond immediately
- dialogue can be skipped
- mini-game submit is not delayed by animations
- scene loading shows progress instead of a blank screen
