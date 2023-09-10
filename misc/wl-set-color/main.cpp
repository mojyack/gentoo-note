#include <sys/mman.h>
#include <unistd.h>

#include "assert.hpp"

#include "wlr-gamma-control-unstable-v1.h"

struct GammaData {
    zwlr_gamma_control_v1* gamma_control = nullptr;
    int                    table_fd;
    uint16_t*              data;
    size_t                 data_size;
};

auto close_gamma_data_mmap(GammaData& gamma_data) -> void {
    if(gamma_data.table_fd != -1) {
        close(gamma_data.table_fd);
        munmap(gamma_data.data, gamma_data.data_size);
        gamma_data.table_fd = -1;
    }
}

auto free_gamma_data(GammaData& gamma_data) {
    if(gamma_data.gamma_control != nullptr) {
        zwlr_gamma_control_v1_destroy(gamma_data.gamma_control);
        gamma_data.gamma_control = nullptr;
    }
    close_gamma_data_mmap(gamma_data);
}

struct Output {
    wl_output* data;
    uint32_t   name;
    GammaData  gamma_data;
};

struct Context {
    double color_red;
    double color_green;
    double color_blue;
    double gamma;

    std::vector<Output>            outputs;
    zwlr_gamma_control_manager_v1* gamma_control_manager;
    std::function<void()>          on_apply;
};

namespace {
auto parse_double(const char* const str) -> double {
    const auto r = strtod(str, NULL);
    DYN_ASSERT(errno == 0);
    return r;
}
auto create_gamma_table(const uint32_t table_size) -> std::pair<int, uint16_t*> {
    auto filename = std::array<char, 32>();
    sprintf(filename.data(), "darker-%u", getpid());
    auto fd = memfd_create(filename.data(), 0);
    DYN_ASSERT(fd >= 0);
    DYN_ASSERT(ftruncate(fd, table_size) == 0);

    auto data = (uint16_t*)mmap(NULL, table_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    DYN_ASSERT(data != MAP_FAILED);
    return {fd, data};
}

auto fill_gamma_table(uint16_t* const table, const uint32_t ramp_size, const double rw, const double gw, const double bw, const double gamma) -> void {
    const auto r = table;
    const auto g = r + ramp_size;
    const auto b = g + ramp_size;
    for(auto i = 0u; i < ramp_size; i += 1) {
        const auto e = 1. * i / (ramp_size - 1);

        r[i] = UINT16_MAX * pow(e * rw, 1.0 / gamma);
        g[i] = UINT16_MAX * pow(e * gw, 1.0 / gamma);
        b[i] = UINT16_MAX * pow(e * bw, 1.0 / gamma);
    }
}

// wayland stuff
auto empty_callback() -> void {
    return;
}

// zwlr_gamma_control_manager_v1
auto zwlr_gamma_control_v1_gamma_size(void* const data, zwlr_gamma_control_v1* const gamma_control, const uint32_t size) -> void {
    auto& ctx = *std::bit_cast<Context*>(data);
    for(auto& o : ctx.outputs) {
        if(o.gamma_data.gamma_control == gamma_control) {
            close_gamma_data_mmap(o.gamma_data);

            const auto [fd, mem]   = create_gamma_table(size * 3 * 2);
            o.gamma_data.table_fd  = fd;
            o.gamma_data.data      = mem;
            o.gamma_data.data_size = size * 3 * 2;

            // apply gamma table
            fill_gamma_table(mem, size, ctx.color_red, ctx.color_green, ctx.color_blue, ctx.gamma);
            lseek(fd, 0, SEEK_SET);
            zwlr_gamma_control_v1_set_gamma(gamma_control, fd);
            ctx.on_apply();
            return;
        }
    }
}

auto zwlr_gamma_control_v1_failed(void* const /*data*/, zwlr_gamma_control_v1* const /*gamma_control_v1*/) -> void {
    printf("control failed\n");
}

auto gamma_control_v1_listener = zwlr_gamma_control_v1_listener{
    .gamma_size = zwlr_gamma_control_v1_gamma_size,
    .failed     = zwlr_gamma_control_v1_failed,
};

// output
auto output_geometry(void* const data, wl_output* const output, const int32_t x, const int32_t y, const int32_t physical_width, const int32_t physical_height, const int32_t subpixel, const char* const make, const char* const model, const int32_t transform) -> void {
    auto& ctx = *std::bit_cast<Context*>(data);
    // static const auto match = std::array{"DO NOT USE - RTK", "WISECOCO"};
    static const auto match = std::array{"Dell Inc.", "DELL P2317H"};

    if(strcmp(make, match[0]) == 0 && strcmp(model, match[1]) == 0) {
        for(auto i = ctx.outputs.begin(); i < ctx.outputs.end(); i += 1) {
            if(i->data == output) {
                const auto gamma_control = zwlr_gamma_control_manager_v1_get_gamma_control(ctx.gamma_control_manager, output);
                zwlr_gamma_control_v1_add_listener(gamma_control, &gamma_control_v1_listener, data);
                i->gamma_data.gamma_control = gamma_control;
            }
        }
    }
}

auto output_listener = wl_output_listener{
    .geometry = output_geometry,
    .mode     = (decltype(wl_output_listener::mode))empty_callback,
};

// registory
auto registry_global(void* const data, wl_registry* const registry, const uint32_t name, const char* const interface, const uint32_t version) -> void {
    auto& ctx = *std::bit_cast<Context*>(data);
    if(strcmp(interface, wl_output_interface.name) == 0) {
        const auto output = (wl_output*)wl_registry_bind(registry, name, &wl_output_interface, WL_OUTPUT_GEOMETRY_SINCE_VERSION);
        ctx.outputs.push_back({output, name});
        wl_output_add_listener(output, &output_listener, data);
    } else if(strcmp(interface, zwlr_gamma_control_manager_v1_interface.name) == 0) {
        const auto gamma_control_manager = (zwlr_gamma_control_manager_v1*)(wl_registry_bind(registry, name, &zwlr_gamma_control_manager_v1_interface, 1));
        ctx.gamma_control_manager        = gamma_control_manager;
    }
    // auto& self = *std::bit_cast<Registry*>(data);
    // self.bind_interface(interface, version, id);
}

auto registry_global_remove(void* const data, wl_registry* const registry, const uint32_t name) -> void {
    auto& ctx = *std::bit_cast<Context*>(data);
    for(auto i = ctx.outputs.begin(); i < ctx.outputs.end(); i += 1) {
        if(i->name == name) {
            wl_output_destroy(i->data);
            free_gamma_data(i->gamma_data);
            ctx.outputs.erase(i);
            return;
        }
    }
    // auto& self = *std::bit_cast<Registry*>(data);
    // self.unbind_interface(id);
}

auto registry_listener = wl_registry_listener{
    .global        = registry_global,
    .global_remove = registry_global_remove,
};

} // namespace

auto main(int argc, char* argv[]) -> int {
    auto r = 0.0;
    auto g = 0.0;
    auto b = 0.0;
    auto c = 0.0;
    if(argc == 3) {
        r = parse_double(argv[1]) / 100;
        g = r;
        b = r;
        c = parse_double(argv[2]) / 100;
    } else if(argc == 5) {
        r = parse_double(argv[1]) / 100;
        g = parse_double(argv[2]) / 100;
        b = parse_double(argv[3]) / 100;
        c = parse_double(argv[4]) / 100;
    } else {
        return 1;
    }

    auto display = wl_display_connect(nullptr);
    DYN_ASSERT(display != nullptr);
    auto registry = wl_display_get_registry(display);
    DYN_ASSERT(registry != nullptr);

    auto finish         = false;
    auto context        = Context();
    context.color_red   = r;
    context.color_green = g;
    context.color_blue  = b;
    context.gamma       = c;
    context.on_apply    = [display, &finish]() {
        struct Done {
            static auto done(void* data, wl_callback*, uint32_t) {
                *(bool*)data = true;
            }
        };
        static const auto listener = wl_callback_listener{.done = Done::done};
        const auto        sync     = wl_display_sync(display);
        wl_callback_add_listener(sync, &listener, &finish);
    };

    wl_registry_add_listener(registry, &registry_listener, &context);

    while(wl_display_dispatch(display) >= 0 && !finish) {
    }

    // whe do we need this?
    usleep(30000);

    wl_display_disconnect(display);

    return 0;
}
