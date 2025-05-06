//
//  SummaryDetailView.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import SwiftUI

struct SummaryDetailView: View {
    let summary: String
    let transcript: String
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            Picker("View", selection: $selectedTab) {
                Text("Summary").tag(0)
                Text("Full Transcript").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text(summary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Full Transcript")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text(transcript)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
            
            HStack {
                Button("Copy to Clipboard") {
                    let textToCopy = selectedTab == 0 ? summary : transcript
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(textToCopy, forType: .string)
                }
                .padding()
                
                Spacer()
                
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .padding()
            }
            .padding(.horizontal)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SummaryDetailView(
        summary: "This is a sample summary of the transcribed audio. It would include key points and important information from the recording.",
        transcript: "This is a sample transcript of the audio recording. It would include all the spoken words captured during the recording session. The transcript can be quite lengthy compared to the summary, which is why we provide both views."
    )
}