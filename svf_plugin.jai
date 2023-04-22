#import "Basic";
#import "clap-jai";
#import,file "plugin_config.jai";
#import "clap-jai-plugin-base"(Plugin_Type=SVF_Plugin,
                               plugin_id=clap_plugin_id,
                               PLUGIN_CREATOR=create_plugin,
                               PLUGIN_DESCRIPTOR_GETTER=get_descriptor);
#load "custom_audio_ports.jai";
#load "svf_params.jai";
#load "svf_processor.jai";

// TODO:
// dynamic channel count
// reset()
// GUI??

SVF_Plugin :: struct {
    #as using base: Plugin_Base;

    // audio processor
    audio_processor: SVF_Processor;

    // clap extensions
    custom_audio_ports: Custom_Audio_Ports;
    params: SVF_Plugin_Params;
    state_save_load: Plugin_State;
    plugin_ui: Plugin_Gui;
}

get_descriptor :: (factory: *clap_plugin_factory_t, idx: u32) -> *clap_plugin_descriptor_t #c_call {
    return *clap_plugin_descriptor;
}

create_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t) -> *clap_plugin_t {
    using self:= New(SVF_Plugin); // will be deleted via Plugin_Base in destroy_plugin

    plugin_base_init(self, factory, host);
    initialize_plugin = plugin_init;
    activate = plugin_activate;
    custom_audio_ports_init(*custom_audio_ports, *clap_audio_ports_ext);
    clap_params_ext = *params;
    clap_state_ext = *state_save_load;
    clap_gui_ext = *plugin_ui;

    return *self.clap_plugin;
}

plugin_init :: (using plugin: *SVF_Plugin) {
    log("Initializing plugin!\n");

    init_params(*params);

    audio_processor.params = *params;
    audio_processor.derived = *audio_processor;
    audio_processor.process_audio = process_svf;
}

plugin_activate :: (using plugin: *SVF_Plugin, sample_rate: float64, max_block_size: u32) -> s64 {
    log("Activating plugin!\n");

    // TODO: channel count is hard-coded to "2" here!
    prepare_processor(*audio_processor, sample_rate, max_block_size, 2);

    // allocate 20x the max block size to use for audio thread temp storage
    // TODO: figure how to make a compile-time check for this...
    return 20 * max_block_size;
}
