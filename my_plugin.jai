#import "Basic";
#import "clap-jai";

my_plugin_id :: "com.chowdsp.clap-jai-plugin";

MyPlugin :: struct {
    host: *clap_host_t;
    plugin: clap_plugin_t;
}

create_my_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t) -> *clap_plugin_t {
    plugin: *MyPlugin = alloc(size_of(MyPlugin)); 
    plugin.host = host;
    plugin.plugin.desc = factory.get_plugin_descriptor(factory, 0);
    plugin.plugin.plugin_data = *plugin;
    plugin.plugin.init = plugin_init;
    plugin.plugin.destroy = plugin_destroy;
    plugin.plugin.activate = plugin_activate;
    plugin.plugin.deactivate = plugin_deactivate;
    plugin.plugin.start_processing = plugin_start_processing;
    plugin.plugin.stop_processing = plugin_stop_processing;
    plugin.plugin.reset = plugin_reset;
    plugin.plugin.process = plugin_process;
    plugin.plugin.get_extension = plugin_get_extension;
    plugin.plugin.on_main_thread = plugin_on_main_thread;
    
    return *plugin.plugin;
}

plugin_init :: (plugin: *clap_plugin_t) -> bool #c_call {
    self := cast(*MyPlugin) plugin;

    // self.host.init(self.host); // load up extensions...

    // self.ensureMainThread("clap_plugin.init");
    return true;
}

plugin_destroy :: (plugin: *clap_plugin_t) -> void #c_call {
    self := cast(*MyPlugin) plugin;
    // self.ensureMainThread("clap_plugin.destroy");

    // if (self._isGuiCreated) {
    //    if (l >= CheckingLevel::Minimal)
    //       self._host.pluginMisbehaving("host forgot to destroy the gui");
    //    clapGuiDestroy(plugin);
    // }

    // self.runCallbacksOnMainThread();

    new_context: Context;
    push_context new_context {
        free(self);
    }
}

plugin_activate :: (plugin: *clap_plugin_t, sample_rate: float64, min_frames_count: u32, max_frames_count: u32) -> bool #c_call {
    new_context: Context;
    push_context new_context {
        print("Initializing plugin with sample rate %, and max block size %\n", sample_rate, max_frames_count);
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
    return null;
}

plugin_on_main_thread :: (plugin: *clap_plugin_t) -> void #c_call {
}
