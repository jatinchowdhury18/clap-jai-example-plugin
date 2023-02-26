#import "Basic";
#import "clap-jai";

clap_host_proxy :: struct {
    host: *clap_host_t;

    host_jai_context: Context;

    host_log: *clap_host_log_t;
    thread_check: *clap_host_thread_check_t;
    thread_pool: *clap_host_thread_pool_t;
    audio_ports: *clap_host_audio_ports_t;
    audio_ports_config: *clap_host_audio_ports_config_t;
    note_ports: *clap_host_note_ports_t;
    host_latency: *clap_host_latency_t;
    host_gui: *clap_host_gui_t;
    host_timer_support: *clap_host_timer_support_t;
    host_posix_fd_support: *clap_host_posix_fd_support_t;
    host_params: *clap_host_params_t;
    host_state: *clap_host_state_t;
    host_note_name: *clap_host_note_name_t;
    host_voice_info: *clap_host_voice_info_t;
    host_tail: *clap_host_tail_t;

    // draft extensions TODO:
    // clap_host_resource_directory_t
    // clap_host_track_info_t
    // clap_host_remote_control_t
    // clap_host_context_menu_t
    // clap_host_preset_load_t
}

clap_logger :: (message: string, data: *void, info: Log_Info) {
    log_severity : clap_log_severity = .CLAP_LOG_INFO;
    if (info.common_flags == .ERROR) {
        log_severity = .CLAP_LOG_ERROR;
    } else if (info.common_flags == .WARNING) {
        log_severity = .CLAP_LOG_WARNING;
    } else if (info.common_flags == .VERBOSE_ONLY || info.common_flags == .VERY_VERBOSE_ONLY) {
        log_severity = .CLAP_LOG_DEBUG;
    }

    trimmed_message: string;
    trimmed_message.data = message.data;
    if (message[message.count - 1] == #char "\n") {
        trimmed_message.count = message.count - 1;
    } else {
        trimmed_message.count = message.count;
    }

    host_proxy := cast(*clap_host_proxy) data;
    log_string := tprint("%\0", trimmed_message);
    host_proxy.host_log.log(cast(*clap_host_t) host_proxy.host, log_severity, log_string.data);
    
    // @TODO: figure out how we can call reset_temporary_storage() to reclaim the memory from log_string...
}

host_proxy_init :: (using host_proxy: *clap_host_proxy, verbose: bool = false) {
    if verbose {
        log("Querying host extensions...\n");
    }
    host_log = host_proxy_get_extension(host, clap_host_log_t, CLAP_EXT_LOG, verbose);
    if (host_log != null) {
        host_jai_context.logger = clap_logger;
        host_jai_context.logger_data = host_proxy;
    }

    thread_check = host_proxy_get_extension(host, clap_host_thread_check_t, CLAP_EXT_THREAD_CHECK, verbose);
    thread_pool = host_proxy_get_extension(host, clap_host_thread_pool_t, CLAP_EXT_THREAD_POOL, verbose);
    audio_ports = host_proxy_get_extension(host, clap_host_audio_ports_t, CLAP_EXT_AUDIO_PORTS, verbose);
    audio_ports_config = host_proxy_get_extension(host, clap_host_audio_ports_config_t, CLAP_EXT_AUDIO_PORTS_CONFIG, verbose);
    note_ports = host_proxy_get_extension(host, clap_host_note_ports_t, CLAP_EXT_NOTE_PORTS, verbose);
    host_latency = host_proxy_get_extension(host, clap_host_latency_t, CLAP_EXT_LATENCY, verbose);
    host_gui = host_proxy_get_extension(host, clap_host_gui_t, CLAP_EXT_GUI, verbose);
    host_timer_support = host_proxy_get_extension(host, clap_host_timer_support_t, CLAP_EXT_TIMER_SUPPORT, verbose);
    host_posix_fd_support = host_proxy_get_extension(host, clap_host_posix_fd_support_t, CLAP_EXT_POSIX_FD_SUPPORT, verbose);
    host_params = host_proxy_get_extension(host, clap_host_params_t, CLAP_EXT_PARAMS, verbose);
    host_state = host_proxy_get_extension(host, clap_host_state_t, CLAP_EXT_STATE, verbose);
    host_note_name = host_proxy_get_extension(host, clap_host_note_name_t, CLAP_EXT_NOTE_NAME, verbose);
    host_voice_info = host_proxy_get_extension(host, clap_host_voice_info_t, CLAP_EXT_VOICE_INFO, verbose);
    host_tail = host_proxy_get_extension(host, clap_host_tail_t, CLAP_EXT_TAIL, verbose);
}

host_proxy_get_extension :: (host: *clap_host_t, $ExtentionType: Type, id: string, verbose: bool = false) -> *ExtentionType {
    id_str: string;
    id_str.data = id.data;
    id_str.count = id.count - 1;
    if verbose {
        log("Querying host extension: %\n", id_str);
    }

    if host.get_extension == null {
        if verbose log("Tried to get host extension \"%\", but host does not support get_extension!\n", id_str);
        return null;
    }

    extension_ptr := cast(*ExtentionType) host.get_extension(host, id.data);

    if verbose {
        if extension_ptr != null {
            log("Host extension \"%\": FOUND!\n", id_str);
        } else {
            log("Host extension \"%\": NOT FOUND!\n", id_str);
        }
    }

    return extension_ptr;
}
