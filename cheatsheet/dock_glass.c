#include <ptrauth.h>

void dock_call_tail(void *tail_raw, void *global, void *global_plus_8, void *helper_raw, void *ret) {
    void *tail = ptrauth_sign_unauthenticated(tail_raw, ptrauth_key_asia, 0);
    void *helper = ptrauth_sign_unauthenticated(helper_raw, ptrauth_key_asia, 0);
    asm volatile("" : "+r"(tail), "+r"(helper));
    asm volatile(
        "mov x0, %[global]\n"
        "mov x1, %[global8]\n"
        "mov x2, %[helper]\n"
        "mov x8, %[ret]\n"
        "blr %[tail]\n"
        :
        : [tail] "r"(tail), [global] "r"(global), [global8] "r"(global_plus_8), [helper] "r"(helper), [ret] "r"(ret)
        : "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9", "x10", "x11", "x12", "x13", "x14", "x15", "x16", "x17", "x19", "x20", "x30", "memory", "cc"
    );
}

void dock_call_glass(void *glass_raw, void *variant, void *ret) {
    asm volatile(
        "mov x0, %[variant]\n"
        "mov x8, %[ret]\n"
        "blr %[glass]\n"
        :
        : [glass] "r"(glass_raw), [variant] "r"(variant), [ret] "r"(ret)
        : "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8", "x9", "x10", "x11", "x12", "x13", "x14", "x15", "x16", "x17", "x30", "memory", "cc"
    );
}
