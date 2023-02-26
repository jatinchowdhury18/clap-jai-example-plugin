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
    params: Params;

    // move to audio processor...
    AUDIO_THREAD_TEMPORARY_STORAGE_SIZE :: 1000;
    audio_thread_storage_buf: [AUDIO_THREAD_TEMPORARY_STORAGE_SIZE] u8;
    audio_thread_temporary_storage: Temporary_Storage;
    audio_thread_context: Context;

    // extensions
    audio_ports_ext :: clap_plugin_audio_ports_t.{
        audio_ports_count,
        audio_ports_get
    };
    params_ext :: clap_plugin_params_t.{
        params_count,
        params_get_info,
        params_get_value,
        params_value_to_text,
        params_text_to_value,
        params_flush
    };
}

ProcessContext :: struct {
    data_in: [..] *float;
    data_out: [..] *float;
    num_in_channels: u32;
    num_out_channels: u32;
    num_samples: u32;
}

create_process_context :: (clap_buffer_in: *clap_audio_buffer_t,
                           clap_buffer_out: *clap_audio_buffer_t,
                           num_samples: u32,
                           sample_offset: u32 = 0) -> ProcessContext {
    process_context: ProcessContext;

    // dynamic allocations, but this is real-time safe because we're using Temporary_Storage
    array_resize(*process_context.data_in, clap_buffer_in.channel_count, false); 
    array_resize(*process_context.data_out, clap_buffer_out.channel_count, false);

    process_context.num_samples = num_samples;
    process_context.num_in_channels = clap_buffer_in.channel_count;
    process_context.num_out_channels = clap_buffer_out.channel_count;
    
    for channel_idx: 0..clap_buffer_in.channel_count-1 {
        process_context.data_in[channel_idx] = clap_buffer_in.data32[channel_idx] + sample_offset;
    }
    for channel_idx: 0..clap_buffer_out.channel_count-1 {
        process_context.data_out[channel_idx] = clap_buffer_out.data32[channel_idx] + sample_offset;
    }

    return process_context;
}

process_audio :: (plugin: *MyPlugin, process_context: *ProcessContext) {
    for ch: 0..process_context.num_in_channels-1 {
        channel_data_in := process_context.data_in[ch];
        channel_data_out := process_context.data_out[ch];

        for n: 0..process_context.num_samples-1 {
            channel_data_out[n] = 0.25 * channel_data_in[n];
        }
    }
}

create_my_plugin :: (factory: *clap_plugin_factory_t, host: *clap_host_t) -> *clap_plugin_t {
    using self := New(MyPlugin);
    host_proxy.host = host;

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

plugin_init :: (clap_plugin: *clap_plugin_t) -> bool #c_call {
    using self := plugin_from_self(clap_plugin);

    host_jai_context = *host_proxy.host_jai_context;
    host_jai_context.logger = Context_Base.default_logger;
    host_jai_context.allocator = Context_Base.default_allocator;
    host_jai_context.print_style = Print_Style.{};

    audio_thread_temporary_storage.data = audio_thread_storage_buf.data;
    audio_thread_temporary_storage.size = AUDIO_THREAD_TEMPORARY_STORAGE_SIZE;
    audio_thread_context.temporary_storage = *audio_thread_temporary_storage;

    push_context self.host_jai_context {
        log("Initializing host proxy!\n");
        host_proxy_init(*self.host_proxy, true);
    }

    return true;
}

plugin_destroy :: (plugin: *clap_plugin_t) -> void #c_call {
    self := plugin_from_self(plugin);

    // if (self._isGuiCreated) {
    //    if (l >= CheckingLevel::Minimal)
    //       self._host.pluginMisbehaving("host forgot to destroy the gui");
    //    clapGuiDestroy(plugin);
    // }

    // self.runCallbacksOnMainThread();

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
    self := plugin_from_self(plugin);
    push_context self.audio_thread_context {
        context.allocator = temp;

        {
            out_events := process.out_events;
            // @TODO: push UI events to output queue...
        }

        num_samples := process.frames_count;
        events := process.in_events;
        num_events := events.size(events);
        current_event_index : u32 = 0;
        next_event_time := num_samples;

        if num_events > 0 { // get timestamp of first event
            next_event_time = events.get(events, 0).time;
        }

        process_event :: (events: *clap_input_events_t,
                          current_event_index: *u32,
                          next_event_time: *u32,
                          num_events: u32,
                          num_samples: u32,
                          sample_offset: u32) {
            event := events.get(events, (<<current_event_index));
            // process_clap_event...

            (<<current_event_index) += 1;
            if (<<current_event_index) < num_events {
                (<<next_event_time) = events.get(events, (<<current_event_index)).time;
            } else {
                (<<next_event_time) = num_samples;
            }
        }

        get_num_samples_to_process :: (events: *clap_input_events_t,
                                       current_event_index: *u32,
                                       num_events: u32,
                                       n: u32,
                                       num_samples: u32) -> u32 {
            samples_until_end_of_block := num_samples - n;
            if num_events == 0 {
                return samples_until_end_of_block;
            }

            samples_until_next_event := samples_until_end_of_block;
            for event_index: (<<current_event_index)..num_events-1 {
                event := events.get(events, event_index);
                if (event.time < n + CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES) {
                    // this event is within the resolution size, so we don't need to split
                    continue;
                }

                if (event.space_id != CLAP_CORE_EVENT_SPACE_ID) {
                    continue; // never split for events that are not in the core namespace
                }

                // For now we're only splitting the block on parameter events
                // so we can get sample-accurate automation, and transport events.
                if (event.type == CLAP_EVENT_PARAM_VALUE ||
                    event.type == CLAP_EVENT_PARAM_MOD ||
                    event.type == CLAP_EVENT_TRANSPORT)
                {
                    samples_until_next_event = event.time - n;
                    break;
                }
            }

            // the number of samples left is less than
            // CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES so let's just
            // process the rest of the block
            if samples_until_end_of_block <= CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES {
                return samples_until_end_of_block;
            }

            // process up until the next event, rounding up to the nearest multiple
            // of CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES
            num_small_blocks := (samples_until_next_event + CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES - 1) / CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES;
            return min(num_small_blocks * CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES, samples_until_end_of_block);
        }

        CLAP_PROCESS_EVENTS_RESOLUTION_SAMPLES :: 64; // @TODO: make this configurable
        n : u32 = 0;
        while n < num_samples {
            num_samples_to_process := get_num_samples_to_process(events, *current_event_index, num_events, n, num_samples);
            
            // process the events in this sub-block
            while (next_event_time < n + num_samples_to_process && current_event_index < num_events) {
                process_event(events, *current_event_index, *next_event_time, num_events, num_samples, n);
            }

            process_context := create_process_context(process.audio_inputs, process.audio_outputs, num_samples_to_process, n);
            process_audio(self, *process_context);

            // add output events to out-going queue...

            n += num_samples_to_process;
        }

        // process any leftover events
        while current_event_index < num_events {
            process_event(events, *current_event_index, *next_event_time, num_events, num_samples, num_samples);
        }

        return .CLAP_PROCESS_CONTINUE;
    }
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
        } else if (id_cstr == CLAP_EXT_AUDIO_PORTS) {
            log("Plugin extension %: FOUND!", id_str);
            return *self.audio_ports_ext;
        }
        
        log("Plugin extension %: NOT FOUND!", id_str);
    }

    return null;
}

plugin_on_main_thread :: (plugin: *clap_plugin_t) -> void #c_call {
}

// @TODO: figure out how we can put the extension
// implementations in other files...
audio_ports_count :: (plugin: *clap_plugin_t, is_input: bool) -> u32 #c_call {
    return 1; // @TODO?
}

audio_ports_get :: (plugin: *clap_plugin_t, index: u32, is_input: bool, info: *clap_audio_port_info_t) -> bool #c_call {
    if index == 0 {
        info.flags |= CLAP_AUDIO_PORT_IS_MAIN;
    }
    
    info.in_place_pair = CLAP_INVALID_ID; // @TODO

    info.channel_count = 2;
    info.port_type = CLAP_PORT_STEREO.data;

    return true;
}

//=======================================================
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
