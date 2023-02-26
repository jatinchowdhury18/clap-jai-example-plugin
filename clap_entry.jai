#import "clap-jai";
#import "Basic";
#import,file "my_plugin.jai";

clap_get_plugin_count :: (factory: *clap_plugin_factory_t) -> u32 #c_call {
    return 1;
}

clap_features :: string.["audio-effect\0"]; // not sure if we _need_ to do this, but I'm going to append null char for C-compatibility
clap_features_char_ptrs: [clap_features.count + 1] *char; // we need an extra entry in the array (which will be null) for C-compatibility

descriptor := clap_plugin_descriptor_t.{CLAP_VERSION, // version
                                        my_plugin_id.data, // my_plugin_id.data, // id
                                        "Jai-Clap", // name
                                        "chowdsp", // vendor
                                        "https://chowdsp.com", // url
                                        "", // manual url
                                        "", // support url
                                        "0.0.0", // version
                                        "CLAP plugin made with Jai!", // description
                                        clap_features_char_ptrs.data};

clap_get_plugin_descriptor :: (factory: *clap_plugin_factory_t, idx: u32) -> *clap_plugin_descriptor_t #c_call {
    new_context: Context;
    push_context new_context {
        for feature, it : clap_features {
            clap_features_char_ptrs[it] = feature.data;
        }
    }
    return *descriptor;
}

clap_create_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t, plugin_id: *char) -> *clap_plugin_t #c_call {
    new_context: Context;
    push_context new_context {
        str_plugin_id := to_string(plugin_id);
        if (str_plugin_id != my_plugin_id) {
            print("Wrong plugin_id! Got: %, expected: %. Returning null!\n", str_plugin_id, my_plugin_id);
            return null;
        }
    
        return create_my_plugin(factory, host);
    }
}

plugin_factory := clap_plugin_factory_t.{clap_get_plugin_count,
                                         clap_get_plugin_descriptor,
                                         clap_create_plugin};

clap_init :: (plugin_path: *char) -> bool #c_call {
    return true;
}

clap_deinit :: () #c_call {
}

clap_get_factory :: (factory_id: *char) -> *void #c_call {
    return *plugin_factory;
}

#program_export
clap_entry := clap_plugin_entry_t.{CLAP_VERSION,
                                   clap_init,
                                   clap_deinit,
                                   clap_get_factory};;
