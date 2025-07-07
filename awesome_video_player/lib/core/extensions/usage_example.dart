import 'package:flutter/material.dart';
import 'package:lumeo/core/extensions/string_extensions.dart';

/// Example usage of String extensions for asset paths
class AssetPathExample extends StatelessWidget {
  const AssetPathExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Path Extensions Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'String Extensions for Asset Paths',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // PNG Images
            _buildSection(
              'PNG Images (.toPng)',
              [
                _buildExample('logo'.toPng, 'logo'.toPng),
                _buildExample('splash_background'.toPng, 'splash_background'.toPng),
                _buildExample('app_icon'.toPng, 'app_icon'.toPng),
              ],
            ),
            
            // Custom Image Extensions
            _buildSection(
              'Custom Extensions (.toImage)',
              [
                _buildExample('banner'.toImage('jpg'), 'banner'.toImage('jpg')),
                _buildExample('logo'.toImage('svg'), 'logo'.toImage('svg')),
                _buildExample('background'.toImage('webp'), 'background'.toImage('webp')),
              ],
            ),
            
            // Icons
            _buildSection(
              'Icons (.toIcon)',
              [
                _buildExample('play'.toIcon, 'play'.toIcon),
                _buildExample('pause'.toIcon, 'pause'.toIcon),
                _buildExample('stop'.toIcon, 'stop'.toIcon),
              ],
            ),
            
            // Custom Asset Folders
            _buildSection(
              'Custom Folders (.toAssetFolder)',
              [
                _buildExample('intro.mp4'.toAssetFolder('videos'), 'intro.mp4'.toAssetFolder('videos')),
                _buildExample('roboto.ttf'.toAssetFolder('fonts'), 'roboto.ttf'.toAssetFolder('fonts')),
                _buildExample('config.json'.toAssetFolder('data'), 'config.json'.toAssetFolder('data')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...examples,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExample(String code, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const Text(' → '),
          Expanded(
            flex: 3,
            child: Text(
              result,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

/// Practical usage examples in widgets
class PracticalUsageExamples {
  // Example 1: Using in Image.asset()
  static Widget logoImage() {
    return Image.asset('logo'.toPng);
  }

  // Example 2: Using in AssetImage()
  static Widget backgroundContainer() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('background'.toPng),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Example 3: Using with custom extensions
  static Widget svgIcon() {
    // Note: You'd need flutter_svg package for this
    // return SvgPicture.asset('play_button'.toImage('svg'));
    return Container(); // Placeholder
  }

  // Example 4: Using in precacheImage
  static Future<void> precacheImages(BuildContext context) async {
    await precacheImage(AssetImage('splash'.toPng), context);
    await precacheImage(AssetImage('logo'.toPng), context);
    await precacheImage(AssetImage('background'.toImage('jpg')), context);
  }

  // Example 5: Dynamic asset loading
  static Widget dynamicIcon(String iconName) {
    return Image.asset(iconName.toIcon);
  }

  // Example 6: Loading configuration files
  static Future<String> loadConfig() async {
    // Note: You'd need rootBundle from services
    // return await rootBundle.loadString('app_config'.toAssetFolder('config').toImage('json'));
    return 'config data'; // Placeholder
  }
}
