#!/bin/bash

# Script to download the Whisper small model for use with whisper.cpp

# Create directories
APP_SUPPORT_DIR="$HOME/Library/Application Support/Pressbox/models"
mkdir -p "$APP_SUPPORT_DIR"

echo "Downloading Whisper small model..."

# Download the model file
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
MODEL_PATH="$APP_SUPPORT_DIR/whisper-small.bin"

# Check if curl is available
if command -v curl &> /dev/null; then
    curl -L "$MODEL_URL" -o "$MODEL_PATH"
elif command -v wget &> /dev/null; then
    wget "$MODEL_URL" -O "$MODEL_PATH"
else
    echo "Error: Neither curl nor wget is installed. Please install one of these tools and try again."
    exit 1
fi

# Check if download was successful
if [ $? -eq 0 ]; then
    echo "Model downloaded successfully to $MODEL_PATH"
    echo "Size: $(du -h "$MODEL_PATH" | cut -f1)"
else
    echo "Error: Failed to download the model."
    exit 1
fi

echo "Whisper small model is ready to use with Pressbox!"