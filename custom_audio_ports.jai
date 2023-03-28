Custom_Audio_Ports :: struct {
    #as using base: Audio_Ports;
}

custom_audio_ports_init :: (using self: *Custom_Audio_Ports, ports_ext: **Audio_Ports) {
    clap_ext = clap_plugin_audio_ports_t.{
        count=clap_audio_ports_count,
        get=audio_ports_get
    };
    (<<ports_ext) = self;
}

audio_ports_get :: (plugin: *clap_plugin_t, index: u32, is_input: bool, info: *clap_audio_port_info_t) -> bool #c_call {
    input_str :: "Input\0";
    output_str :: "Output\0";
    clap_audio_ports_get(plugin, index, is_input, info);
    if index == 0 {
        if is_input {
            memcpy(info.name.data, input_str.data, input_str.count);
        } else {
            memcpy(info.name.data, output_str.data, output_str.count);
        }
    }
    return true;
}
