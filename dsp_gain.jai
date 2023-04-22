#import "Basic";
Math :: #import "Math";

Smoothed_Gain :: struct ($SampleType: Type) {
    // parameter
    current_gain : SampleType = 0.0;
    target_gain : SampleType = 0.0;

    // smoothing
    smoothing_increment : SampleType = 0.0;
    smoothing_countdown : u32 = 0;
    smoothing_time_samples : u32 = 0;
    sample_rate : SampleType = 48000.0;

    // smoothing_data : [..] SampleType; // In Jai we dn't need this
}

prepare :: (using gain: *Smoothed_Gain($T),
            fs: T,
            initial_value: T,
            smoothing_time_seconds: T) {
    current_gain = initial_value;
    target_gain = initial_value;

    smoothing_increment = 0.0;
    smoothing_countdown = 0;
    sample_rate = fs;
    smoothing_time_samples = cast(u32) (smoothing_time_seconds * fs);
}

process :: (using gain: *Smoothed_Gain($T), buffer: *[..] *T, num_channels: u32, num_samples: u32, new_target: T) {
    target_gain = new_target;
    if (target_gain != current_gain) {
        smoothing_countdown = smoothing_time_samples;
        smoothing_increment = (target_gain - current_gain) / cast(T) smoothing_countdown;
    }

    smoothed_gain_data : [..] T;
    array_resize(*smoothed_gain_data, num_samples, false); // TODO: check that the allocator is correct here!!

    smooth_data_index : u32 = 0;
    while (smoothing_countdown > 0 && smooth_data_index < num_samples) {
        smoothed_gain_data[smooth_data_index] = current_gain;
        smooth_data_index += 1;
        current_gain += smoothing_increment;
    }

    if (smoothing_countdown == 0) {
        // Optimize me!
        for n: smooth_data_index..num_samples-1 {
            smoothed_gain_data[n] = target_gain;
        }
    }

    for ch: 0..num_channels-1 {
        channel_data := (<<buffer)[ch];
        for n: 0..num_samples-1 {
            channel_data[n] = channel_data[n] * smoothed_gain_data[n];
        }
    }
}
