#import "Basic";
#import "Compiler";
#import "File_Utilities";

// TODO: figure out how to change the extension of the generated file from .dll to .clap

// TODO: figure out how to make these command-line arguments
main_file :: "svf_plugin.jai";
plugin_file_name :: "svf_clap_plugin";
extra_module_paths :: string.["D:/Code/jai/jatin/modules"];
release_build :: true;

#run build();

build :: () {
    w := compiler_create_workspace();

    target_options := get_build_options(w);
    target_options.output_executable_name = plugin_file_name;
    target_options.output_type = .DYNAMIC_LIBRARY; // specifies output to be a dynamic library

    if release_build {
        target_options.optimization_level = .RELEASE; // specifies the optimization level to be .RELEASE
    } else {
        target_options.optimization_level = .DEBUG;   // specifies the optimization level to be .DEBUG
    }

    import_paths: [..] string;
    array_add(*import_paths, ..target_options.import_path);
    array_add(*import_paths, ..extra_module_paths);
    target_options.import_path = import_paths;

    set_build_options(target_options, w);
    add_build_file(tprint("%/%", #filepath, main_file), w);

    set_build_options_dc(.{do_output=false});  // No executable for this workspace.
}
