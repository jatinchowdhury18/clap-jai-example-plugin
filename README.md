# CLAP/Jai Example Plugin

An example audio effect CLAP plugin made with the Jai 
programming language.

Currently the plugin is a simple State Variable Filter effect.

Working:
- Audio ports
- Parameters (with automation and modulation)
- DSP

Not yet working:
- State saving/loading
- GUI

## Building

Building the plugin depends on the
[`clap-jai`](https://github.com/jatinchowdhury18/clap-jai)
and
[`clap-jai-plugin-base`](https://github.com/jatinchowdhury18/clap-jai-plugin-base)
modules.

To build, you can run:
```bash
jai -import_dir path/to/modules -exe svf_clap_plugin build_clap.jai
```

The build process will generate the plugin in a file called
`svf_clap_plugin.clap`. You should be able to copy it
into your plugins folder and test it out in your DAW.

Currently, the plugin has only been tested on Windows,
though I imagine Linux builds would work as well.
