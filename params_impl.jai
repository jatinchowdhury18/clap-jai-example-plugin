#import "Basic";
#import "clap-jai";

ParamHolder :: struct {
    ParamEntry :: struct {
        type: Type;
        data: *void;
    }

    param_list: [..] ParamEntry;
}

register_param :: (using params: *ParamHolder, param: *$T) {
    param.id = cast(u32) param_list.count;
    new_entry: ParamEntry;
    new_entry.type = T;
    new_entry.data = param;
    array_add(*param_list, new_entry);
}

param_holder_get_param_info :: (using params: *ParamHolder,
                                param_index: u32,
                                param_info: *clap_param_info_t) -> bool {
    param_entry := *param_list[param_index];
    // @TODO: better way to do this!!
    if !param_get_info(cast(*FloatParameter) param_entry.data, param_index, param_info) {
        return false;
    }

    param_info.cookie = *param_entry; // #TODO: think about better ways to handle cookies...
    return true;
}

param_holder_get_param_value :: (using params: *ParamHolder,
                                 param_id: clap_id,
                                 out_value: *float64) -> bool {
    param_entry := param_list[param_id];

    out_value[0] = (cast(*FloatParameter) param_entry.data).current_value;
    return true;
}

param_holder_param_value_to_text :: (using params: *ParamHolder,
                                     param_id: clap_id,
                                     value: float64,
                                     out_buffer: *char,
                                     out_buffer_capacity: u32) -> bool {
    // param_entry := param_list[param_id];

    value_str := tprint("%", value);
    memcpy(out_buffer, value_str.data, value_str.count);

    return true;
}

param_holder_param_text_to_value :: (using params: *ParamHolder,
                                     param_id: clap_id,
                                     param_value_text: *char,
                                     out_value: *float64) -> bool {
    // param_entry := param_list[param_id];
    value_str: string;
    value_str.data = param_value_text;
    value_str.count = c_style_strlen(param_value_text);

    out_value[0] = string_to_float64(value_str);

    return true;
}

FloatParameter :: struct {
    // info
    id: clap_id;
    name: string;
    module: string;

    // range
    min_value: float64;
    max_value: float64;
    default_value: float64;

    // value
    current_value: float64;
    modulation_amount: float64 = 0.0;
}

param_get_info :: (using param: *FloatParameter,
                   param_index: u32,
                   param_info: *clap_param_info_t) -> bool {
    if (param_index != id) {
        return false; // wrong parameter ID??
    }

    param_info.flags |= .CLAP_PARAM_IS_AUTOMATABLE;
    param_info.flags |= .CLAP_PARAM_IS_MODULATABLE;

    memcpy(param_info.name.data, name.data, name.count);
    memcpy(param_info.module.data, module.data, module.count);

    param_info.min_value = min_value;
    param_info.max_value = max_value;
    param_info.default_value = default_value;

    return true;
}
