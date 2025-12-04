import 'package:flutter/material.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              'Agreement to Terms',
              'By downloading, installing, or using Lumeo Video Player ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Use License',
              'Permission is granted to use the App for personal, non-commercial purposes. This license does not include:\n\n'
              '• Any commercial use of the App\n'
              '• Modifying or copying the App\n'
              '• Attempting to reverse engineer the App\n'
              '• Removing any copyright or proprietary notices',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'User Responsibilities',
              'You are responsible for:\n\n'
              '• Ensuring you have the right to play the video content you access\n'
              '• Complying with all applicable laws and regulations\n'
              '• Maintaining the security of your device\n'
              '• Backing up your data as needed',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Content',
              'Lumeo Video Player does not provide, host, or distribute video content. The App is a media player that plays video files stored on your device or accessed through network streams you provide. You are solely responsible for the content you play.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Prohibited Uses',
              'You may not use the App:\n\n'
              '• To play copyrighted content without proper authorization\n'
              '• For any illegal purposes\n'
              '• To violate any applicable laws or regulations\n'
              '• To infringe upon the rights of others',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Disclaimer',
              'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Limitation of Liability',
              'IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF OR IN CONNECTION WITH YOUR USE OF THE APP.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Intellectual Property',
              'The App and its original content, features, and functionality are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Termination',
              'We reserve the right to terminate or suspend your access to the App at any time, without prior notice, for any reason, including breach of these Terms.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Changes to Terms',
              'We reserve the right to modify these Terms at any time. We will notify you of any changes by updating the "Last Updated" date. Your continued use of the App after such changes constitutes acceptance of the new Terms.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Contact Information',
              'If you have any questions about these Terms of Service, please contact us through the app settings or support channels.',
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

