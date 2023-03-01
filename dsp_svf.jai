#import "Basic";
Math :: #import "Math";

SVF :: struct ($SampleType: Type) {

    // parameters
    // cutoff_frequency: SampleType;
    // resonance: SampleType;
    // gain: SampleType;

    // coefficients
    a1: SampleType;
    a2: SampleType;
    a3: SampleType;
    ak: SampleType;
    // k0A: SampleType;
    // Asq: SampleType;

    // state variables
    ic1eq: [..] SampleType;
    ic2eq: [..] SampleType;

    // SampleType g0, k0, A, sqrtA; // parameter intermediate values

    sample_rate : SampleType = 44100.0;
}

prepare :: (using svf: *SVF($T), fs: T, channel_count: u32) {
    sample_rate = fs;

    array_resize(*ic1eq, cast(s64) channel_count); // will initialize to 0
    array_resize(*ic2eq, cast(s64) channel_count);

    reset(svf);
}

reset :: (using svf: *SVF($T)) {
    memset(ic1eq.data, 0, ic1eq.count * size_of(T));
    memset(ic2eq.data, 0, ic2eq.count * size_of(T));
}

set_parameters :: (using svf: *SVF($T), fc: T, q_value: T) {
    w := Math.PI * fc / sample_rate;
    g := Math.tan(w);

    k := 1.0 / q_value;
    // k0A = k0; // * A

    gk := g + k;
    a1 = 1.0 / (1.0 + g * gk);
    a2 = g * a1;
    a3 = g * a2;
    ak = gk * a1;
}

process_sample :: (using svf: *SVF($T), x: T, channel_index: u32) -> T {
    s1 := ic1eq[channel_index];
    s2 := ic2eq[channel_index];

    v3 := x - s2;
    v0 := a1 * v3 - ak * s1;
    v1 := a2 * v3 + a1 * s1;
    v2 := a3 * v3 + a2 * s1 + s2;

    // update state
    ic1eq[channel_index] = 2 * v1 - s1;
    ic2eq[channel_index] = 2 * v2 - s2;

    return v2; // lowpass-only    // return std::make_tuple (v0, v1, v2);
}
