#!/bin/bash

# Integration Test Runner for Video Player
# This script runs the video player integration tests on a connected device

echo "Running Video Player Integration Tests..."
echo ""

# Check if device ID is provided as argument
if [ -z "$1" ]; then
  echo "Available devices:"
  flutter devices
  echo ""
  echo "Usage: ./run_integration_test.sh <device-id>"
  echo "Example: ./run_integration_test.sh emulator-5554"
  echo ""
  echo "Or run on all devices:"
  echo "flutter test integration_test/video_player_test.dart -d all"
  exit 1
fi

DEVICE_ID=$1

echo "Running tests on device: $DEVICE_ID"
echo ""

# Run the integration test
flutter test integration_test/video_player_test.dart -d "$DEVICE_ID"

echo ""
echo "Integration test completed!"

