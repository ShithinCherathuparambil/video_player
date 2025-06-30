#!/usr/bin/env dart

import 'dart:io';

/// Performance optimization script for Flutter video player app
/// This script removes debug print statements and optimizes performance issues
void main() async {
  print('🚀 Starting Performance Optimization...');
  
  final libDir = Directory('lib');
  final testDir = Directory('test');
  
  if (!libDir.existsSync()) {
    print('❌ lib directory not found. Run this script from the project root.');
    exit(1);
  }
  
  int printStatementsRemoved = 0;
  int filesOptimized = 0;
  
  // Process lib directory
  await processDirectory(libDir, (file, content) {
    final result = optimizeFile(content);
    printStatementsRemoved += result.printStatementsRemoved;
    if (result.wasModified) {
      filesOptimized++;
      file.writeAsStringSync(result.optimizedContent);
    }
  });
  
  // Process test directory
  if (testDir.existsSync()) {
    await processDirectory(testDir, (file, content) {
      final result = optimizeTestFile(content);
      if (result.wasModified) {
        filesOptimized++;
        file.writeAsStringSync(result.optimizedContent);
      }
    });
  }
  
  print('✅ Performance optimization completed!');
  print('📊 Summary:');
  print('   - Files optimized: $filesOptimized');
  print('   - Print statements removed: $printStatementsRemoved');
  print('   - Performance improvements applied');
}

Future<void> processDirectory(Directory dir, Function(File, String) processor) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        processor(entity, content);
      } catch (e) {
        print('⚠️  Error processing ${entity.path}: $e');
      }
    }
  }
}

class OptimizationResult {
  final String optimizedContent;
  final bool wasModified;
  final int printStatementsRemoved;
  
  OptimizationResult(this.optimizedContent, this.wasModified, this.printStatementsRemoved);
}

OptimizationResult optimizeFile(String content) {
  String optimized = content;
  bool wasModified = false;
  int printStatementsRemoved = 0;
  
  // Remove print statements (but keep debugPrint for debug builds)
  final printRegex = RegExp(r'^\s*print\([^)]*\);\s*$', multiLine: true);
  final printMatches = printRegex.allMatches(optimized);
  printStatementsRemoved = printMatches.length;
  
  if (printStatementsRemoved > 0) {
    optimized = optimized.replaceAll(printRegex, '');
    wasModified = true;
  }
  
  // Replace print with debugPrint for conditional logging
  final printCallRegex = RegExp(r'print\(([^)]+)\);');
  if (printCallRegex.hasMatch(optimized)) {
    optimized = optimized.replaceAllMapped(printCallRegex, (match) {
      return 'assert(() { debugPrint(${match.group(1)}); return true; }());';
    });
    wasModified = true;
  }
  
  // Fix deprecated withOpacity calls
  if (optimized.contains('.withOpacity(')) {
    optimized = optimized.replaceAllMapped(
      RegExp(r'\.withOpacity\(([^)]+)\)'),
      (match) => '.withValues(alpha: ${match.group(1)})',
    );
    wasModified = true;
  }
  
  // Fix deprecated WillPopScope
  if (optimized.contains('WillPopScope')) {
    optimized = optimized.replaceAll('WillPopScope', 'PopScope');
    optimized = optimized.replaceAll('onWillPop:', 'canPop: false, onPopInvoked: (didPop) async {');
    wasModified = true;
  }
  
  // Add const constructors where missing
  final constRegex = RegExp(r'(\w+)\(\s*([^)]*)\s*\)(?!\s*\{)');
  // This is a simplified version - more complex logic would be needed for full optimization
  
  return OptimizationResult(optimized, wasModified, printStatementsRemoved);
}

OptimizationResult optimizeTestFile(String content) {
  String optimized = content;
  bool wasModified = false;
  
  // Remove unused imports in test files
  final unusedImports = [
    "import 'package:mockito/mockito.dart';",
    "import 'package:flutter_test/flutter_test.dart';",
    "import '../helpers/test_helpers.dart';",
  ];
  
  for (final import in unusedImports) {
    if (optimized.contains(import) && !_isImportUsed(optimized, import)) {
      optimized = optimized.replaceAll('$import\n', '');
      wasModified = true;
    }
  }
  
  return OptimizationResult(optimized, wasModified, 0);
}

bool _isImportUsed(String content, String import) {
  // Simplified check - would need more sophisticated analysis for production
  final packageName = RegExp(r"'([^']+)'").firstMatch(import)?.group(1);
  if (packageName == null) return true;
  
  final className = packageName.split('/').last.split('.').first;
  return content.contains(className);
}
