#import "Basic";
#import "clap-jai";
#import,file "host_proxy.jai";
#import,file "params_impl.jai";

my_plugin_id :: "com.chowdsp.clap-jai-plugin";

Params :: struct {
    #as using params_holder: ParamHolder;

    float_param := FloatParameter.{name = "test_param",
                                  min_value = 0.0,
                                   max_value = 1.0,
                                   default_value = 0.5,
                                   current_value = 0.5};
}

MyPlugin :: struct {
    host_proxy: clap_host_proxy;
    plugin: clap_plugin_t;
    host_jai_context: *Context;
    params: Params; // @TODO: register params

    // extensions
    params_ext :: clap_plugin_params_t.{
        params_count,
        params_get_info,
        params_get_value,
        params_value_to_text,
        params_text_to_value,
        params_flush
    };
}

create_my_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t) -> *clap_plugin_t {
    self := New(MyPlugin);
    using self;
    host_proxy.host = host;
    
    host_jai_context = *host_proxy.host_jai_context;
    host_jai_context.logger = Context_Base.default_logger;
    host_jai_context.allocator = Context_Base.default_allocator;
    host_jai_context.print_style = Print_Style.{};

    plugin.desc = factory.get_plugin_descriptor(factory, 0);
    plugin.plugin_data = self;
    plugin.init = plugin_init;
    plugin.destroy = plugin_destroy;
    plugin.activate = plugin_activate;
    plugin.deactivate = plugin_deactivate;
    plugin.start_processing = plugin_start_processing;
    plugin.stop_processing = plugin_stop_processing;
    plugin.reset = plugin_reset;
    plugin.process = plugin_process;
    plugin.get_extension = plugin_get_extension;
    plugin.on_main_thread = plugin_on_main_thread;

    register_param(*self.params, *self.params.float_param);
    
    return *plugin;
}

plugin_from_self :: (plugin: *clap_plugin_t) -> *MyPlugin #c_call {
    return cast(*MyPlugin) plugin.plugin_data;
}

plugin_init :: (plugin: *clap_plugin_t) -> bool #c_call {
    self := plugin_from_self(plugin);

    push_context self.host_jai_context {
        log("Initializing host proxy!\n");
        host_proxy_init(*self.host_proxy, true);
    }

    // self.ensureMainThread("clap_plugin.init");

    return true;
}

plugin_destroy :: (plugin: *clap_plugin_t) -> void #c_call {
    self := plugin_from_self(plugin);
    // self.ensureMainThread("clap_plugin.destroy");

    // if (self._isGuiCreated) {
    //    if (l >= CheckingLevel::Minimal)
    //       self._host.pluginMisbehaving("host forgot to destroy the gui");
    //    clapGuiDestroy(plugin);
    // }

    // self.runCallbacksOnMainThread();

    // new_context: Context;
    push_context self.host_jai_context {
        free(self);
    }
}

plugin_activate :: (plugin: *clap_plugin_t, sample_rate: float64, min_frames_count: u32, max_frames_count: u32) -> bool #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        log("Initializing plugin with sample rate %, and max block size %\n", sample_rate, max_frames_count);
    }

    return true;
}

plugin_deactivate :: (plugin: *clap_plugin_t) -> void #c_call {
}

plugin_start_processing :: (plugin: *clap_plugin_t) -> bool #c_call {
    return true;
}

plugin_stop_processing :: (plugin: *clap_plugin_t) -> void #c_call {
}

plugin_reset :: (plugin: *clap_plugin_t) -> void #c_call {
}

plugin_process :: (plugin: *clap_plugin_t, process: *clap_process_t) -> clap_process_status #c_call {
    return .CLAP_PROCESS_CONTINUE;
}

plugin_get_extension :: (plugin: *clap_plugin_t, id: *char) -> *void #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        id_cstr: string;
        id_cstr.data = id;
        id_cstr.count = c_style_strlen(id) + 1;
        id_str := to_string(id);
        log("Host queried for plugin extension %\n", id_str);
        
        if (id_cstr == CLAP_EXT_PARAMS) {
            log("Plugin extension %: FOUND!", id_str);
            return *self.params_ext;
        }
        
        log("Plugin extension %: NOT FOUND!", id_str);
    }

    return null;
}

plugin_on_main_thread :: (plugin: *clap_plugin_t) -> void #c_call {
}

// @TODO: figure out how we can put the extension
// implementations in other files...
params_count :: (plugin: *clap_plugin_t) -> u32 #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        log("Host asked for params count...\n");
        return cast(u32) self.params.param_list.count;
    }
}

params_get_info :: (plugin: *clap_plugin_t, param_index: u32, param_info: *clap_param_info_t) -> bool #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        return param_holder_get_param_info(*self.params, param_index, param_info);
    }
}

params_get_value :: (plugin: *clap_plugin_t, param_id: clap_id, out_value: *float64) -> bool #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        return param_holder_get_param_value(*self.params, param_id, out_value);
    }
}

params_value_to_text :: (plugin: *clap_plugin_t, param_id: clap_id, value: float64, out_buffer: *char, out_buffer_capacity: u32) -> bool #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        return param_holder_param_value_to_text(*self.params, param_id, value, out_buffer, out_buffer_capacity);
    }
}

params_text_to_value :: (plugin: *clap_plugin_t, param_id: clap_id, param_value_text: *char, out_value: *float64) -> bool #c_call {
    self := plugin_from_self(plugin);
    push_context self.host_jai_context {
        return param_holder_param_text_to_value(*self.params, param_id, param_value_text, out_value);
    }
}

params_flush :: (plugin: *clap_plugin_t, in: *clap_input_events_t, out: *clap_output_events_t) -> void #c_call {
}
