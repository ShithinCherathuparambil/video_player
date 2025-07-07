# Icons Assets

This folder contains icon assets for the Awesome Video Player app.

## Usage with String Extensions

You can use the string extensions to easily reference icons:

```dart
import 'package:lumeo/core/extensions/extensions.dart';

// PNG icons
Image.asset('play'.toIcon)                   // assets/icons/play.png
Image.asset('pause'.toIcon)                  // assets/icons/pause.png
Image.asset('stop'.toIcon)                   // assets/icons/stop.png

// Custom extensions
Image.asset('play'.toIconImage('svg'))       // assets/icons/play.svg
```

## Recommended Icons

- `play.png` - Play button icon
- `pause.png` - Pause button icon
- `stop.png` - Stop button icon
- `forward.png` - Fast forward icon
- `backward.png` - Rewind icon
- `volume.png` - Volume control icon
- `fullscreen.png` - Fullscreen toggle icon

## Icon Guidelines

- Use consistent style across all icons
- Provide multiple sizes (24x24, 32x32, 48x48)
- Use PNG with transparency
- Consider dark/light theme variants
