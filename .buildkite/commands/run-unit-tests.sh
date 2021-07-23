#!/bin/bash

set -e

echo "--- 📦 Downloading Build Artifacts"
buildkite-agent artifact download build-products.tar .
tar -xf build-products.tar
echo "--- 🧪 Testing"
bundle install
bundle exec fastlane test_without_building name:WordPressUnitTests try_count:3
