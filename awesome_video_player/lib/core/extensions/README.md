# String Extensions for Asset Paths

This module provides convenient string extensions for handling asset paths in the Awesome Video Player app.

## Installation

Import the extensions in your Dart files:

```dart
import 'package:lumeo/core/extensions/extensions.dart';
```

## Available Extensions

### 1. `.toPng` - PNG Images

Converts a string to a PNG image path in the `assets/images/` folder.

```dart
// Usage
'logo'.toPng                    // Returns: 'assets/images/logo.png'
'splash_background'.toPng       // Returns: 'assets/images/splash_background.png'
'app_icon'.toPng               // Returns: 'assets/images/app_icon.png'

// In widgets
Image.asset('logo'.toPng)
Image.asset('background'.toPng)
```

### 2. `.toImage(extension)` - Custom Image Extensions

Converts a string to an image path with a custom file extension.

```dart
// Usage
'banner'.toImage('jpg')         // Returns: 'assets/images/banner.jpg'
'logo'.toImage('svg')          // Returns: 'assets/images/logo.svg'
'background'.toImage('webp')    // Returns: 'assets/images/background.webp'

// In widgets
Image.asset('photo'.toImage('jpg'))
// For SVG (requires flutter_svg package)
// SvgPicture.asset('icon'.toImage('svg'))
```

### 3. `.toIcon` - Icon Assets

Converts a string to an icon path in the `assets/icons/` folder.

```dart
// Usage
'play'.toIcon                   // Returns: 'assets/icons/play.png'
'pause'.toIcon                  // Returns: 'assets/icons/pause.png'
'stop'.toIcon                   // Returns: 'assets/icons/stop.png'

// In widgets
Image.asset('play'.toIcon)
ImageIcon(AssetImage('volume'.toIcon))
```

### 4. `.toIconImage(extension)` - Custom Icon Extensions

Converts a string to an icon path with a custom file extension.

```dart
// Usage
'play'.toIconImage('svg')       // Returns: 'assets/icons/play.svg'
'pause'.toIconImage('jpg')      // Returns: 'assets/icons/pause.jpg'

// In widgets
// SvgPicture.asset('play'.toIconImage('svg'))
```

### 5. `.toAsset` - General Assets

Converts a string to a general asset path.

```dart
// Usage
'data.json'.toAsset            // Returns: 'assets/data.json'
'config.yaml'.toAsset          // Returns: 'assets/config.yaml'
'readme.txt'.toAsset           // Returns: 'assets/readme.txt'

// Loading data
String jsonData = await rootBundle.loadString('config.json'.toAsset);
```

### 6. `.toAssetFolder(folder)` - Custom Asset Folders

Converts a string to an asset path in a custom folder.

```dart
// Usage
'intro.mp4'.toAssetFolder('videos')     // Returns: 'assets/videos/intro.mp4'
'roboto.ttf'.toAssetFolder('fonts')     // Returns: 'assets/fonts/roboto.ttf'
'sound.wav'.toAssetFolder('audio')      // Returns: 'assets/audio/sound.wav'

// Nested folders
'config.json'.toAssetFolder('data/settings')  // Returns: 'assets/data/settings/config.json'
```

## Practical Examples

### Image Loading

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PNG images
        Image.asset('logo'.toPng),
        Image.asset('background'.toPng),
        
        // Custom extensions
        Image.asset('banner'.toImage('jpg')),
        
        // Icons
        Image.asset('play'.toIcon),
        ImageIcon(AssetImage('volume'.toIcon)),
      ],
    );
  }
}
```

### Background Images

```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('background'.toPng),
      fit: BoxFit.cover,
    ),
  ),
  child: YourContent(),
)
```

### Preloading Images

```dart
Future<void> preloadImages(BuildContext context) async {
  await precacheImage(AssetImage('splash'.toPng), context);
  await precacheImage(AssetImage('logo'.toPng), context);
  await precacheImage(AssetImage('background'.toImage('jpg')), context);
}
```

### Dynamic Asset Loading

```dart
Widget buildIcon(String iconName) {
  return Image.asset(iconName.toIcon);
}

// Usage
buildIcon('play')    // Loads assets/icons/play.png
buildIcon('pause')   // Loads assets/icons/pause.png
```

## Asset Structure

Make sure your assets are organized in the following structure:

```
assets/
├── images/
│   ├── logo.png
│   ├── background.png
│   ├── splash_background.png
│   └── banner.jpg
├── icons/
│   ├── play.png
│   ├── pause.png
│   ├── stop.png
│   └── volume.png
├── data/
│   └── config.json
└── fonts/
    └── custom_font.ttf
```

## pubspec.yaml Configuration

Ensure your `pubspec.yaml` includes the asset folders:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/data/
    - assets/config/
```

## Benefits

1. **Type Safety**: Reduces typos in asset paths
2. **Consistency**: Standardized asset path structure
3. **Maintainability**: Easy to refactor asset locations
4. **Developer Experience**: Autocomplete and IntelliSense support
5. **Readability**: Clean, readable code

## Testing

The extensions are fully tested. Run tests with:

```bash
flutter test test/core/extensions/string_extensions_test.dart
```
