#import "Basic";
#import "Compiler";
#import "File_Utilities";

// TODOs:
// - make the script more general:
//   - parameter for name of plugin executable
//   - parameter for name of .jai file to compile
//   - parameter for release build
// - better handling of module paths!
// - figure out how to change the extension of the generated file from .dll to .clap

plugin_file_name :: "svf_clap_plugin";

#run build();

build :: () {
    w := compiler_create_workspace();

    target_options := get_build_options(w);
    target_options.output_executable_name = plugin_file_name;
    target_options.output_type = .DYNAMIC_LIBRARY; // specifies output to be a dynamic library

    extra_import_paths: [2] string;
    extra_import_paths[0] = "D:/Code/jai/modules/";
    extra_import_paths[1] = "D:/Code/jai/jatin/modules";
    target_options.import_path = extra_import_paths;

    // format := *context.print_style.default_format_struct;
    // format.use_newlines_if_long_form = true;
    // format.indentation_width = 3;
    // print("The Build_Options for Workspace % is: %\n", w, target_options);

    set_build_options(target_options, w);

    add_build_file(tprint("%/svf_plugin.jai", #filepath), w);

    set_build_options_dc(.{do_output=false});  // No executable for this workspace.
}
