#import "Basic";
#import "clap-plugin-base"(Plugin_Type=SVF_Plugin,
                           plugin_id=clap_plugin_id,
                           PLUGIN_CREATOR=create_plugin,
                           PLUGIN_DESCRIPTOR_GETTER=get_descriptor);
#import "clap-jai";
#load "custom_audio_ports.jai";
#load "svf_params.jai";
#load "svf_processor.jai";

clap_plugin_id :: "com.chowdsp.svf-plugin";
clap_features :: *u8.[CLAP_PLUGIN_FEATURE_AUDIO_EFFECT.data, CLAP_PLUGIN_FEATURE_FILTER.data, null];

SVF_Plugin :: struct {
    #as using base: Plugin_Base;

    // audio processor
    audio_thread_ctx: Audio_Thread_Context;
    audio_processor: SVF_Processor;

    // clap extensions
    custom_audio_ports: Custom_Audio_Ports;
    params: SVF_Plugin_Params;
    state_save_load: Plugin_State;
}

plugin_name :: "Jai CLAP SVF\0";
clap_plugin_descriptor :: clap_plugin_descriptor_t.{clap_version=CLAP_VERSION,
                                                    id=clap_plugin_id.data,
                                                    name="Jai CLAP SVF",
                                                    vendor="chowdsp",
                                                    url="https://chowdsp.com",
                                                    version="0.0.0",
                                                    description="Simple filter plugin made in Jai!",
                                                    features=clap_features.data};

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

    return *self.clap_plugin;
}

plugin_init :: (using plugin: *SVF_Plugin) {
    log("Initializing plugin!\n");

    init_params(*params);

    init_audio_thread_context(*audio_thread_ctx);
    audio_processor.params = *params;
    audio_processor.derived = *audio_processor;
    audio_processor.process_audio = process_svf;
}

plugin_activate :: (using plugin: *SVF_Plugin, sample_rate: float64, max_block_size: u32) {
    log("Activating plugin!\n");
    prepare_processor(*audio_processor, sample_rate, max_block_size, 2);
}
