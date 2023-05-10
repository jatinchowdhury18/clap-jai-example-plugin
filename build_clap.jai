#import "Basic";
#import "Compiler";
File :: #import "File";

#if OS == .MACOS {
    Bundler :: #import,file "macos_bundle/clap_bundler.jai";
}

main_file :: "svf_plugin.jai";
plugin_exe_name :: "svf_clap_plugin";
Config :: #import,file "plugin_config.jai";

#run build();

build :: () {
    w := compiler_create_workspace();

    target_options := get_build_options(w);
    target_options.output_type = .DYNAMIC_LIBRARY; // specifies output to be a dynamic library
    target_options.output_executable_name = plugin_exe_name;

    import_paths: [..] string;
    array_add(*import_paths, ..target_options.import_path);
    cli_args := target_options.compile_time_command_line;
    for arg, idx: cli_args {
        if arg == "-import_dir" {
            array_add(*import_paths, cli_args[idx + 1]);
        } else if arg == "-release" {
            set_optimization(*target_options, .OPTIMIZED);
            target_options.stack_trace = false;
        } else if arg == "-quiet" {
            target_options.text_output_flags = 0;
        } else if arg == "-x64" {
            target_options.backend = .X64;
        } else if arg == "-llvm" {
            target_options.backend = .LLVM;
        }
    }
    target_options.import_path = import_paths;

    set_build_options(target_options, w);

    compiler_begin_intercept(w);
    add_build_file(tprint("%/%", #filepath, main_file), w);
    message_loop();
    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});  // No executable for this workspace.

    #if OS == .WINDOWS {
        dll_file := tprint("%.dll", plugin_exe_name);
        clap_file := tprint("%.clap", plugin_exe_name);
        File.file_delete(clap_file);
        File.file_move(dll_file, clap_file);
    } else #if OS == .MACOS {
        dll_file := tprint("%.dylib", plugin_exe_name);
        clap_file := tprint("%.clap", plugin_exe_name);
        File.delete_directory(clap_file);
        Bundler.create_clap_bundle(plugin_exe_name,
                                   dll_file,
                                   Config.clap_plugin_id,
                                   Config.clap_plugin_name,
                                   Config.clap_plugin_version,
                                   Config.clap_plugin_desc);
    }
}

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
          // case .FILE;
          //   message_file := cast(*Message_File) message;
          //   print("  Loading file '%'.\n", message_file.fully_pathed_filename);
            
          // case .IMPORT;
          //   import := cast(*Message_Import) message;
          //   print("  Importing module '%'.\n", import.module_name);

          case .COMPLETE;
            break;
        }
    }
}
