//
//  dummywrapper.h
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

#ifndef dummywrapper_h
#define dummywrapper_h

// Dummy file to help resolve header issues
// These are minimal definitions to help compile without the full whisper.cpp integration

// Audio format definitions
#define kAudioFormatMPEG4AAC 1
#define kAudioFormatMPEG4AAC_HE 2

// Define dummy whisper context and state
typedef struct whisper_context whisper_context;
typedef struct whisper_state whisper_state;

// Define whisper sampling strategy
enum whisper_sampling_strategy {
    WHISPER_SAMPLING_GREEDY,
    WHISPER_SAMPLING_BEAM_SEARCH,
};

// Dummy struct for whisper_token_data
typedef struct whisper_token_data {
    int dummy;
} whisper_token_data;

// Dummy struct for whisper_full_params
struct whisper_full_params {
    int dummy;
};

// Function prototypes to satisfy dependencies
whisper_context* whisper_init_from_file_with_params(const char* path, void* params);
void whisper_free(whisper_context* ctx);
struct whisper_full_params whisper_full_default_params(int strategy);
int whisper_full(whisper_context* ctx, struct whisper_full_params params, const float* samples, int n_samples);
void whisper_print_timings(whisper_context* ctx);
int whisper_full_n_segments(whisper_context* ctx);
const char* whisper_full_get_segment_text(whisper_context* ctx, int i);
whisper_token_data* whisper_get_timings(whisper_context* ctx);

#endif /* dummywrapper_h */