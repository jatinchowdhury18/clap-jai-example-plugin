SVF :: #import,file "dsp_svf.jai";

SVF_Processor :: struct {
    #as using base: Audio_Processor;
    params: *SVF_Plugin_Params;

    filter: SVF.SVF(float32);
}

prepare_processor :: (using proc: *SVF_Processor, sample_rate: float64, max_block_size: u32, channel_count: u32) {
    SVF.prepare(*filter, cast(float32) sample_rate, channel_count);
}

process_svf :: (proc: *Audio_Processor, buffers: *Process_Buffers) {
    using self := cast(*SVF_Processor) proc;

    SVF.set_parameters(*filter,
                       cast(float32) param_get_modulated_value(*params.cutoff_param),
                       cast(float32) param_get_modulated_value(*params.q_param));

    for ch: 0..buffers.num_in_channels-1 {
        channel_data_in := buffers.data_in[ch];
        channel_data_out := buffers.data_out[ch];

        for n: 0..buffers.num_samples-1 {
            channel_data_out[n] = SVF.process_sample(*filter, channel_data_in[n], ch); // gain * channel_data_in[n];
        }
    }
}
