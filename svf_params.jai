SVF_Plugin_Params :: struct {
    #as using base: Params;

    cutoff_param: Frequency_Parameter;
    q_param: Float_Parameter;
    gain_param: Float_Parameter;
}

init_params :: (using plugin_params: *SVF_Plugin_Params) {
    init_param(*cutoff_param, "Cutoff", 20.0, 20000.0, 1000.0, 1000.0);
    register_param(plugin_params, *cutoff_param);

    init_param(*q_param, "Filter Q", 0.5, 10.0, 1.0, 0.7071);
    register_param(plugin_params, *q_param);

    init_param(*gain_param, "Drive", -18.0, 18.0, 0.0, 0.0);
    register_param(plugin_params, *gain_param);
}
