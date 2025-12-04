import 'package:flutter/material.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Last Updated',
              'December 2024',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Introduction',
              'Lumeo Video Player ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our video player application.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Information We Collect',
              'Lumeo Video Player operates entirely on your device. We do not collect, transmit, or store any personal information or video data on external servers. All video files and playback data remain on your device.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Local Data Storage',
              'The app stores the following data locally on your device:\n\n'
              '• Playback positions and watch history\n'
              '• Favorite video lists\n'
              '• App settings and preferences\n'
              '• Video thumbnails (cached locally)\n\n'
              'This data is stored using your device\'s local storage and is never transmitted outside your device.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Permissions',
              'Lumeo Video Player may request the following permissions:\n\n'
              '• Storage Access: To read and play video files from your device\n'
              '• Biometric Authentication: To secure the app with fingerprint or face recognition (optional)\n\n'
              'All permissions are used solely for app functionality and are not shared with third parties.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Third-Party Services',
              'Lumeo Video Player uses the following third-party libraries:\n\n'
              '• Better Player: For video playback\n'
              '• VLC Player: For advanced format support\n'
              '• Photo Manager: For accessing media files\n\n'
              'These libraries operate locally on your device and do not transmit data externally.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Data Security',
              'We implement appropriate security measures to protect your local data. However, since all data is stored on your device, you are responsible for maintaining the security of your device.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Children\'s Privacy',
              'Lumeo Video Player does not knowingly collect information from children. The app is designed to be used by individuals of all ages, but all data remains on the device.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us through the app settings or support channels.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

