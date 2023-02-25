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
            print("Adding CLAP feature: %\n", feature);
            clap_features_char_ptrs[it] = feature.data;
        }
    }
    return *descriptor;
}

clap_create_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t, plugin_id: *char) -> *clap_plugin_t #c_call {
    new_context: Context;
    push_context new_context {
        str_plugin_id := StringHelpers.to_string(plugin_id);
        if (str_plugin_id != my_plugin_id) {
            print("Wrong plugin_id! Got: %, expected: %. Returning null!\n", str_plugin_id, my_plugin_id);
            return null;
        }
    
        return create_my_plugin(factory, host);
    }
}

// template<typename PluginType>
// static const clap_plugin *clap_create_plugin(const clap_plugin_factory *,
//                                              const clap_host *host,
//                                              const char *plugin_id) {
//     if (strcmp(plugin_id, PluginType::description.id))
//         return nullptr;

//     // From baconpaul: I know it looks like a leak right? but the
//     // clap-plugin-helpers basically take ownership and destroy the wrapper when
//     // the host destroys the underlying plugin (look at Plugin<h, l>::clapDestroy
//     // if you don't believe me!)
//     auto p = new PluginType(host);
//     return p->clapPlugin();
// }

plugin_factory := clap_plugin_factory_t.{clap_get_plugin_count,
                                         clap_get_plugin_descriptor,
                                         clap_create_plugin};

clap_init :: (plugin_path: *char) -> bool #c_call {
    new_context: Context;
    push_context new_context {
        print("INIT!\n");
    }
    return true;
}

clap_deinit :: () #c_call {
    new_context: Context;
    push_context new_context {
        print("DEINIT!\n");
    }
}

clap_get_factory :: (factory_id: *char) -> *void #c_call {
    new_context: Context;
    push_context new_context {
        print("get_factory!!\n");
    }
    return *plugin_factory;
}

#program_export
clap_entry := clap_plugin_entry_t.{CLAP_VERSION,
                                   clap_init,
                                   clap_deinit,
                                   clap_get_factory};;
