/// String extensions for the Awesome Video Player app
extension StringExtensions on String {
  /// Returns the path to an image asset in the images folder
  /// 
  /// Usage:
  /// ```dart
  /// 'logo'.toPng // Returns 'assets/images/logo.png'
  /// 'icon_play'.toPng // Returns 'assets/images/icon_play.png'
  /// ```
  String get toPng => 'assets/images/$this.png';

  /// Returns the path to an image asset with custom extension
  /// 
  /// Usage:
  /// ```dart
  /// 'logo'.toImage('jpg') // Returns 'assets/images/logo.jpg'
  /// 'icon'.toImage('svg') // Returns 'assets/images/icon.svg'
  /// ```
  String toImage(String extension) => 'assets/images/$this.$extension';

  /// Returns the path to an icon asset in the icons folder
  /// 
  /// Usage:
  /// ```dart
  /// 'play'.toIcon // Returns 'assets/icons/play.png'
  /// 'pause'.toIcon // Returns 'assets/icons/pause.png'
  /// ```
  String get toIcon => 'assets/icons/$this.png';

  /// Returns the path to an icon asset with custom extension
  /// 
  /// Usage:
  /// ```dart
  /// 'play'.toIconImage('svg') // Returns 'assets/icons/play.svg'
  /// ```
  String toIconImage(String extension) => 'assets/icons/$this.$extension';

  /// Returns the path to a general asset
  /// 
  /// Usage:
  /// ```dart
  /// 'data.json'.toAsset // Returns 'assets/data.json'
  /// 'config.yaml'.toAsset // Returns 'assets/config.yaml'
  /// ```
  String get toAsset => 'assets/$this';

  /// Returns the path to an asset in a custom folder
  /// 
  /// Usage:
  /// ```dart
  /// 'video.mp4'.toAssetFolder('videos') // Returns 'assets/videos/video.mp4'
  /// 'font.ttf'.toAssetFolder('fonts') // Returns 'assets/fonts/font.ttf'
  /// ```
  String toAssetFolder(String folder) => 'assets/$folder/$this';
}
