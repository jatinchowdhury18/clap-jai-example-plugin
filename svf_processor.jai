SVF :: #import,file "dsp_svf.jai";
Gain :: #import,file "dsp_gain.jai";

SVF_Processor :: struct {
    #as using base: Audio_Processor;
    params: *SVF_Plugin_Params;

    filter: SVF.SVF(float32);
    gain: Gain.Smoothed_Gain(float32);
}

prepare_processor :: (using proc: *SVF_Processor, sample_rate: float64, max_block_size: u32, channel_count: u32) {
    SVF.prepare(*filter, cast(float32) sample_rate, channel_count);

    gain_linear := Math.pow(10.0, cast(float32) param_get_modulated_value(*params.gain_param) / 20.0);
    Gain.prepare(*gain, cast(float32) sample_rate, gain_linear, 0.05);
}

process_svf :: (proc: *Audio_Processor, buffers: *Process_Buffers) {
    using self := cast(*SVF_Processor) proc;

    // set up for in-place processing
    for ch: 0..buffers.num_in_channels-1 {
        channel_data_in := buffers.data_in[ch];
        channel_data_out := buffers.data_out[ch];

        if (channel_data_in != channel_data_out) {
            memcpy(channel_data_out, channel_data_in, size_of(float32) * buffers.num_samples);
        }
    }

    gain_linear := Math.pow(10.0, cast(float32) param_get_modulated_value(*params.gain_param) / 20.0);
    Gain.process(*gain,
                 *buffers.data_out,
                 buffers.num_in_channels,
                 buffers.num_samples,
                 gain_linear);

    SVF.set_parameters(*filter,
                       cast(float32) param_get_modulated_value(*params.cutoff_param),
                       cast(float32) param_get_modulated_value(*params.q_param));

    for ch: 0..buffers.num_in_channels-1 {
        channel_data := buffers.data_out[ch];

        for n: 0..buffers.num_samples-1 {
            channel_data[n] = SVF.process_sample(*filter, channel_data[n], ch);
        }
    }
}
