#!/bin/bash
set -e

echo "Cleaning build..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Building Android APKs (split per ABI, release, analyze size)..."
flutter build apk --release --split-per-abi --analyze-size

echo "Building Android App Bundle (AAB, analyze size)..."
flutter build appbundle --release --analyze-size

echo "Building iOS (release)..."
flutter build ios --release

echo "All builds complete. Check the build/outputs/ and analyze-size .json files for size breakdowns." 