// This code helps create a macOS app (bundle) for a CLAP plugin
create_clap_bundle :: (clap_exe_name: string,
                       clap_dylib_path: string,
                       bundle_id: string,
                       plugin_name: string,
                       plugin_version: string,
                       plugin_description: string) {
    clap_bundle_name := tprint("%.clap", clap_exe_name);
    macos_path, resources_path := make_app_bundle_subdirectories(clap_bundle_name);

    bundle_exe_path := tprint("%/%", macos_path, clap_exe_name);
    file_move(clap_dylib_path, bundle_exe_path);

    { // create bundle icon
        icns_output_path := tprint("%/%", resources_path, "clap.icns");
        convert_image_to_icns("macos_bundle/clap.icns", icns_output_path);
    }

    { // build and write plist
        builder: String_Builder;

        plist_start(*builder);
        plist_write_key_value(*builder, "CFBundleDevelopmentRegion", "English");
        plist_write_key_value(*builder, "CFBundleExecutable", clap_exe_name);
        plist_write_key_value(*builder, "CFBundleGetInfoString", plugin_description);
        plist_write_key_value(*builder, "CFBundleIconFile", "clap.icns");
        plist_write_key_value(*builder, "CFBundleIdentifier", bundle_id);
        plist_write_key_value(*builder, "CFBundleName", plugin_name);
        plist_write_key_value(*builder, "CFBundlePackageType", "BNDL");
        plist_write_key_value(*builder, "CFBundleSignature", "????");
        plist_write_key_value(*builder, "CFBundleShortVersionString", plugin_version);
        plist_write_key_value(*builder, "CFBundleVersion", plugin_version);
        plist_end(*builder);

        output := builder_to_string(*builder);
        write_entire_file(tprint("%/Contents/Info.plist", clap_bundle_name), output);

        free(output);
    }

    { // copy PkgInfo
        copy_file("macos_bundle/PkgInfo", tprint("%/Contents/PkgInfo", clap_bundle_name));
    }
}

make_app_bundle_subdirectories :: (app_bundle_name: string) -> macos_folder_path: string, resources_path: string {
    resources_path := tprint("%/Contents/Resources", app_bundle_name);
    macos_path     := tprint("%/Contents/MacOS", app_bundle_name);

    make_directory_if_it_does_not_exist(app_bundle_name);
    make_directory_if_it_does_not_exist(tprint("%/Contents", app_bundle_name));
    make_directory_if_it_does_not_exist(macos_path);
    make_directory_if_it_does_not_exist(resources_path);

    return macos_path, resources_path;
}

convert_image_to_icns :: (input_path: string, output_path: string) -> bool {
    // @TODO verify if the input image is 128x128 256x256 or 512x512 and scale the image accordingly if not
    // or at least give an error
    process_result, output, error := run_command("sips", "-s", "format", "icns", input_path, "--out", output_path);
    return process_result.exit_code == 0;
}

plist_start :: (builder: *String_Builder) {
    append(builder, PLIST_HEADER);

    append(builder, "<plist>\n");
    append(builder, "<dict>\n");
}

plist_end :: (builder: *String_Builder) {
    append(builder, "</dict>\n");
    append(builder, "</plist>\n");
}

plist_write_key_value :: (builder: *String_Builder, key: string, value: Any) -> success: bool {
    plist_write_key(builder, key);

    if      (value.type.type == Type_Info_Tag.BOOL)   plist_write_bool(builder,   << cast(*bool)   value.value_pointer);
    else if (value.type.type == Type_Info_Tag.STRING) plist_write_string(builder, << cast(*string) value.value_pointer);
    else return false;

    return true;
}

plist_write_key :: (builder: *String_Builder, key: string) {
    append(builder, "<key>");
    append(builder, key);
    append(builder, "</key>\n");
}

plist_write_string :: (builder: *String_Builder, str: string) {
    append(builder, "<string>");
    append(builder, str);
    append(builder, "</string>\n");
}

plist_write_bool :: (builder: *String_Builder, value: bool) {
    print_to_builder(builder, "<%/>", value);
}


#scope_file

PLIST_HEADER :: #string DONE
<?xml version="1.0" ?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
DONE

copy_files_recursively :: (source: string, dest: string) {
    paths: [2] string;
    paths[0] = source;
    paths[1] = dest;

    visitor :: (info: *File_Visit_Info, paths: [2] string) {
        relative_path := info.full_name;
        advance(*relative_path, paths[0].count);
        out_path := join(paths[1], "/", relative_path);
        make_directory_if_it_does_not_exist(path_strip_filename(out_path), recursive = true);
        copy_file(info.full_name, out_path);
    }

    res := visit_files(paths[0], true, paths, visitor);
    assert(res);
}


#scope_file
#import "Basic";
#import "Process";
#import "File";
#import "File_Utilities";
#import "String";
#import "POSIX";
