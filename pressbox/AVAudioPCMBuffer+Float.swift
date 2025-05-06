//
//  AVAudioPCMBuffer+Float.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import AVFoundation

extension AVAudioPCMBuffer {
    func convertToFloatArray() -> [Float] {
        let channelCount = Int(format.channelCount)
        let frameCount = Int(frameLength)
        
        // Get the channel data
        guard let data = floatChannelData else {
            return []
        }
        
        // If stereo, we'll average the channels
        if channelCount > 1 {
            var floatArray = [Float](repeating: 0.0, count: frameCount)
            
            // Average the channels
            for frame in 0..<frameCount {
                var sum: Float = 0.0
                for channel in 0..<channelCount {
                    sum += data[channel][frame]
                }
                floatArray[frame] = sum / Float(channelCount)
            }
            
            return floatArray
        } else {
            // For mono, just return the single channel
            var floatArray = [Float](repeating: 0.0, count: frameCount)
            
            for frame in 0..<frameCount {
                floatArray[frame] = data[0][frame]
            }
            
            return floatArray
        }
    }
    
    func resampleTo(sampleRate: Double) -> AVAudioPCMBuffer? {
        guard format.sampleRate != sampleRate else {
            return self // No need to resample
        }
        
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: format.channelCount)
        
        guard let converter = AVAudioConverter(from: format, to: outputFormat!),
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(Double(frameLength) * sampleRate / format.sampleRate)) else {
            return nil
        }
        
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return self
        }
        
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            print("Error resampling: \(error)")
            return nil
        }
        
        return outputBuffer
    }
    
    func convertToMono() -> AVAudioPCMBuffer? {
        guard format.channelCount > 1 else {
            return self // Already mono
        }
        
        let monoFormat = AVAudioFormat(standardFormatWithSampleRate: format.sampleRate, channels: 1)
        
        guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat!, frameCapacity: frameLength) else {
            return nil
        }
        
        // Get channel data
        guard let inputData = floatChannelData,
              let outputData = monoBuffer.floatChannelData else {
            return nil
        }
        
        let channelCount = Int(format.channelCount)
        let frameCount = Int(frameLength)
        
        // Average all channels into mono
        for frame in 0..<frameCount {
            var sum: Float = 0.0
            for channel in 0..<channelCount {
                sum += inputData[channel][frame]
            }
            outputData[0][frame] = sum / Float(channelCount)
        }
        
        monoBuffer.frameLength = frameLength
        
        return monoBuffer
    }
}