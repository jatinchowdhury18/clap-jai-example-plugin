#import "clap-jai";

clap_plugin_id :: "com.chowdsp.svf-plugin";
clap_plugin_name :: "Jai CLAP SVF";
clap_plugin_vendor :: "chowdsp";
clap_plugin_url :: "https://chowdsp.com";
clap_plugin_version :: "0.0.0";
clap_plugin_desc :: "Simple filter plugin made in Jai!";
clap_features :: *u8.[CLAP_PLUGIN_FEATURE_AUDIO_EFFECT.data, CLAP_PLUGIN_FEATURE_FILTER.data, null];

clap_plugin_descriptor :: clap_plugin_descriptor_t.{clap_version=CLAP_VERSION,
                                                    id=clap_plugin_id.data,
                                                    name=clap_plugin_name.data,
                                                    vendor=clap_plugin_vendor.data,
                                                    url=clap_plugin_url.data,
                                                    version=clap_plugin_version.data,
                                                    description=clap_plugin_desc.data,
                                                    features=clap_features.data};
