#pragma once
#include <iostream>

struct Location {
    const char* file;
    const int   line;
};

template <class... Args>
auto warn(Args... args) -> void {
    (std::cerr << ... << args) << std::endl;
}

template <class... Args>
[[noreturn]] auto line_panic(const Location location, Args&&... args) -> void {
    warn("error at ", location.file, ":", location.line, " ", std::forward<Args>(args)...);
    exit(1);
}

template <class... Args>
auto line_assert(const bool cond, const Location location, Args&&... args) -> void {
    if(!cond) {
        line_panic(location, std::forward<Args>(args)...);
    }
}

#define PANIC(...) line_panic({__FILE__, __LINE__} __VA_OPT__(, ) __VA_ARGS__);
#define DYN_ASSERT(cond, ...) line_assert((cond), {__FILE__, __LINE__} __VA_OPT__(, ) __VA_ARGS__);

