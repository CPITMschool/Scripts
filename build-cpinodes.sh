#!/bin/bash

# Quick build script for cpinodes
# This script builds the cpinodes binary from the source directory

set -e

echo "Building cpinodes..."

cd cpinodes-source

# Build for Linux
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ../cpinodes ./cmd/cpinodes

cd ..

echo "✓ Build complete: cpinodes ($(du -h cpinodes | cut -f1))"
echo ""
echo "Run: ./cpinodes"
