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
jai build_clap.jai
```

You will likely need to adjust some of the constants
defined in `build_clap.jai` to work with your setup.

The build process will generate the plugin in a file called
`svf_clap_plugin.dll`. I'm planning to figure out how to
generate a file with the .clap extension, but for now,
you should be able to rename the file as such, copy it
into your plugins folder, and test it out in your DAW.

Currently, the plugin has only been tested on Windows,
though I imagine Linux builds would work as well.
