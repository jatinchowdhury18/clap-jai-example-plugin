#import "Basic";
#import "Compiler";
File :: #import "File";

main_file :: "svf_plugin.jai";

#run build();

build :: () {
    w := compiler_create_workspace();

    target_options := get_build_options(w);
    target_options.output_type = .DYNAMIC_LIBRARY; // specifies output to be a dynamic library

    import_paths: [..] string;
    array_add(*import_paths, ..target_options.import_path);
    plugin_file_name := "";
    cli_args := target_options.compile_time_command_line;
    for arg, idx: cli_args {
        if arg == "-import_dir" {
            array_add(*import_paths, cli_args[idx + 1]);
        } else if arg == "-exe" {
            plugin_file_name = cli_args[idx + 1];
            target_options.output_executable_name = plugin_file_name;
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

    // rename file from .dll to .clap
    // we're probably going to need to do something
    // a little different on Linux and MacOS
    #if OS == .WINDOWS {
        dll_file := tprint("%.dll", plugin_file_name);
        clap_file := tprint("%.clap", plugin_file_name);
        File.file_delete(clap_file);
        File.file_move(dll_file, clap_file);
    } else #if OS == .MACOS {
        dll_file := tprint("%.dylib", plugin_file_name);
        clap_file := tprint("macos_bundle/svf-clap-plugin.clap/Contents/MacOS/%", plugin_file_name);
        File.file_delete(clap_file);
        File.file_move(dll_file, clap_file);
    }
}

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
        //   case .FILE;
        //     message_file := cast(*Message_File) message;
        //     print("  Loading file '%'.\n", message_file.fully_pathed_filename);
            
        //   case .IMPORT;
        //     import := cast(*Message_Import) message;
        //     print("  Importing module '%'.\n", import.module_name);

          case .COMPLETE;
            break;
        }
    }
}
