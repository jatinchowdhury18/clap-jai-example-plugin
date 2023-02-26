#import "Basic";
#import "clap-jai";
#import,file "host_proxy.jai";

my_plugin_id :: "com.chowdsp.clap-jai-plugin";

MyPlugin :: struct {
    host_proxy: clap_host_proxy;
    plugin: clap_plugin_t;
    host_jai_context: *Context;
}

create_my_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t) -> *clap_plugin_t {
    self: *MyPlugin = alloc(size_of(MyPlugin));  // this memory will be freed in plugin_destroy
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
    new_ctx: Context;
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
    return null;
}

plugin_on_main_thread :: (plugin: *clap_plugin_t) -> void #c_call {
}
