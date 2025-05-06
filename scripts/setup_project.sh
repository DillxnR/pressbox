#!/bin/bash

# Setup script for Pressbox

echo "Setting up Pressbox project..."

# Create necessary directories
echo "Creating required directories..."
mkdir -p "$HOME/Library/Application Support/Pressbox/models"

# Make whisper.cpp model accessible
if [ -d "dependencies/whisper.cpp" ]; then
    echo "Setting up Whisper.cpp..."
    # Clone whisper.cpp if it doesn't exist
    if [ ! -d "dependencies/whisper.cpp" ]; then
        echo "Cloning whisper.cpp repository..."
        mkdir -p dependencies
        git clone https://github.com/ggerganov/whisper.cpp.git dependencies/whisper.cpp
    fi
    
    # Download the small model
    MODEL_DIR="$HOME/Library/Application Support/Pressbox/models"
    MODEL_PATH="$MODEL_DIR/whisper-small.bin"
    
    if [ ! -f "$MODEL_PATH" ]; then
        echo "Downloading Whisper small model..."
        # Try to use curl
        if command -v curl &> /dev/null; then
            curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin" -o "$MODEL_PATH"
        # Try to use wget if curl is not available
        elif command -v wget &> /dev/null; then
            wget "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin" -O "$MODEL_PATH"
        else
            echo "Error: Neither curl nor wget is installed. Please install one of these tools and try again."
            exit 1
        fi
        
        if [ $? -eq 0 ]; then
            echo "Model downloaded successfully to $MODEL_PATH"
        else
            echo "Error: Failed to download the model."
            exit 1
        fi
    else
        echo "Whisper small model already exists at $MODEL_PATH"
    fi
else
    echo "Warning: whisper.cpp directory not found. You need to initialize the dependencies first."
    echo "Run: git clone https://github.com/ggerganov/whisper.cpp.git dependencies/whisper.cpp"
fi

echo "Setup complete!"
echo "You can now build and run the Pressbox application."
echo "Don't forget to configure your OpenAI API key in the app settings!"