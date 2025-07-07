# Images Assets

This folder contains image assets for the Awesome Video Player app.

## Usage with String Extensions

You can use the string extensions to easily reference images:

```dart
import 'package:lumeo/core/extensions/extensions.dart';

// PNG images
Image.asset('logo'.toPng)                    // assets/images/logo.png
Image.asset('splash_background'.toPng)       // assets/images/splash_background.png
Image.asset('app_icon'.toPng)               // assets/images/app_icon.png

// Custom extensions
Image.asset('banner'.toImage('jpg'))         // assets/images/banner.jpg
Image.asset('logo'.toImage('svg'))          // assets/images/logo.svg
```

## Recommended Images

- `splash_logo.png` - Logo for splash screen
- `app_icon.png` - Main app icon
- `background.png` - Background images
- `placeholder.png` - Placeholder for missing images

## Image Guidelines

- Use PNG for images with transparency
- Use JPG for photos and complex images
- Use SVG for scalable vector graphics
- Optimize images for mobile devices
- Consider different screen densities (1x, 2x, 3x)
