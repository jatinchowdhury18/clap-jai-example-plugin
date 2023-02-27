#import "Basic";
#import "clap-base"(Plugin_Type=SVF_Plugin,
                    plugin_id=clap_plugin_id,
                    PLUGIN_CREATOR=create_plugin,
                    PLUGIN_DESCRIPTOR_GETTER=get_descriptor);
#import "clap-jai";

clap_plugin_id :: "com.chowdsp.svf-plugin";
clap_features :: *u8.[CLAP_PLUGIN_FEATURE_AUDIO_EFFECT.data, null];

SVF_Plugin :: struct {
    #as using base: Plugin_Base;
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

    return *self.clap_plugin;
}

plugin_init :: (using plugin: *SVF_Plugin) {
    log("Initializing plugin!\n");
    // audio_thread_temporary_storage.data = audio_thread_storage_buf.data;
    // audio_thread_temporary_storage.size = AUDIO_THREAD_TEMPORARY_STORAGE_SIZE;
    // audio_thread_context.temporary_storage = *audio_thread_temporary_storage;
}

plugin_activate :: (using plugin: *SVF_Plugin, sample_rate: float64, max_block_size: u32) {
    log("Activating plugin!\n");
}


