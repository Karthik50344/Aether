/// Source of "now". Injected so time-dependent code can be tested.
typedef Clock = DateTime Function();
