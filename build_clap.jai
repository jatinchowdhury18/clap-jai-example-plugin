#import "Basic";
#import "Compiler";
#import "File_Utilities";

plugin_file_name :: "jai_clap_plugin";

#run build();
// #run copy_file(tprint("%/%.jai", #filepath, plugin_file_name),
//                tprint("/c/Program Files/Common Files/CLAP/%.clap", plugin_file_name));

build :: () {
    w := compiler_create_workspace();

    target_options := get_build_options(w);
    target_options.output_executable_name = plugin_file_name;
    target_options.output_type = .DYNAMIC_LIBRARY; // specifies output to be a dynamic library

    extra_import_paths: [2] string;
    extra_import_paths[0] = "D:/Code/jai/modules/";
    extra_import_paths[1] = "D:/Code/jai/jatin/modules";
    target_options.import_path = extra_import_paths;

    format := *context.print_style.default_format_struct;
    format.use_newlines_if_long_form = true;
    format.indentation_width = 3;  // A silly indentation width, but we are setting these parameters to show off.
    // print("The Build_Options for Workspace % is: %\n", w, target_options);

    set_build_options(target_options, w);

    add_build_file(tprint("%/clap_entry.jai", #filepath), w);


    set_build_options_dc(.{do_output=false});  // No executable for this workspace.
}
