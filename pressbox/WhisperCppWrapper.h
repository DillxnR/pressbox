//
//  WhisperCppWrapper.h
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

#ifndef WhisperCppWrapper_h
#define WhisperCppWrapper_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// This is the Objective-C wrapper class for whisper.cpp
@interface WhisperCppWrapper : NSObject

/**
 * Initialize a whisper model
 * @param modelPath Path to the ggml model file (e.g., "whisper-small.bin")
 * @return YES if initialization was successful, NO otherwise
 */
- (BOOL)initializeModel:(NSString *)modelPath;

/**
 * Transcribe audio from a given file path
 * @param audioPath Path to the audio file to transcribe
 * @return NSString containing the transcription or nil if transcription failed
 */
- (nullable NSString *)transcribeAudio:(NSString *)audioPath;

/**
 * Transcribe audio from raw PCM audio data
 * @param audioData NSData containing raw PCM audio (16-bit, 16kHz, mono)
 * @param sampleRate Sample rate of the audio data
 * @param numChannels Number of channels in the audio data
 * @return NSString containing the transcription or nil if transcription failed
 */
- (nullable NSString *)transcribeAudio:(NSData *)audioData 
                       withSampleRate:(int)sampleRate
                          numChannels:(int)numChannels;

/**
 * Get the last error message if any operation failed
 * @return NSString containing the error message or nil if no error
 */
- (nullable NSString *)lastErrorMessage;

/**
 * Check if the whisper model is initialized and ready
 * @return YES if the model is initialized, NO otherwise
 */
- (BOOL)isModelInitialized;

@end

NS_ASSUME_NONNULL_END

#endif /* WhisperCppWrapper_h */