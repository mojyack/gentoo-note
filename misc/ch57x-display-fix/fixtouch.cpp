#include <iostream>
#include <sstream>
#include <string>

#include <fcntl.h>
#include <linux/uinput.h>
#include <unistd.h>

template <class... Args>
auto build_string(Args... args) -> std::string {
    auto ss = std::stringstream();
    (ss << ... << args);
    return ss.str();
}

template <class... Args>
auto warn(Args... args) -> void {
    (std::cerr << ... << args) << std::endl;
}

template <class... Args>
auto dynamic_assert(const bool cond, Args... args) -> void {
    if(!cond) {
        warn(args...);
        exit(1);
    }
}

class Error {
  private:
    std::string what;

  public:
    auto cstr() const -> const char* {
        return what.data();
    }

    operator bool() const {
        return !what.empty();
    }

    Error() = default;
    Error(std::string_view what) : what(what) {}
};

template <class T>
class Result {
  private:
    std::variant<T, Error> data;

  public:
    auto as_value() -> T& {
        return std::get<T>(data);
    }

    auto as_value() const -> const T& {
        return std::get<T>(data);
    }

    auto as_error() const -> Error {
        return std::get<Error>(data);
    }

    auto unwrap() -> T& {
        if(!std::holds_alternative<T>(data)) {
            throw std::runtime_error(as_error().cstr());
        }
        return as_value();
    }

    auto unwrap() const -> const T& {
        if(!std::holds_alternative<T>(data)) {
            throw std::runtime_error(as_error().cstr());
        }
        return as_value();
    }

    operator bool() const {
        return std::holds_alternative<T>(data);
    }

    Result(T data) : data(std::move(data)) {}

    Result(const Error error = Error()) : data(error) {}
};

template <class T>
auto unwrap(Result<T>&& result) -> T& {
    if(!result) {
        warn(result.as_error().cstr());
        exit(1);
    }
    return result.as_value();
}

auto open_uinput_device(const char* const path, bool grab = true) -> Result<int> {
    const auto fd = open(path, O_RDONLY);
    if(fd == -1) {
        return Error(build_string("open(", path, ") failed: ", errno));
    }
    if(grab) {
        if(ioctl(fd, EVIOCGRAB, 1) != 0) {
            return Error(build_string("ioctl() failed: ", errno));
        }
    }
    return fd;
}

template <size_t bits>
constexpr auto bits_to_bytes = (bits - 1) / 8 + 1;

template <int event, size_t max>
auto get_uinput_device_event_bits(const int fd) -> Result<std::array<std::byte, bits_to_bytes<max>>> {
    auto result = std::array<std::byte, bits_to_bytes<max>>();
    if(ioctl(fd, EVIOCGBIT(event, result.size()), result.data()) != result.size()) {
        return Error(build_string("ioctl() failed: ", errno));
    }
    return result;
}

template <size_t size>
auto check_bit(const std::array<std::byte, size>& data, const int n) -> bool {
    return (int(data[n / 8]) & (1 << (n % 8))) != 0;
}

auto create_virtual_device(const int pfd) -> int {
    const auto vfd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if(vfd == -1) {
        return Error(build_string("open(/dev/uinput) failed: ", errno));
    }

    // other events
    const auto events = unwrap(get_uinput_device_event_bits<0, EV_MAX>(pfd));

    auto inherit_all_events = [pfd, vfd, &events]<int event, size_t max, int setbit>() -> void {
        if(!check_bit(events, event)) {
            return;
        }

        dynamic_assert(ioctl(vfd, UI_SET_EVBIT, event) == 0, "ioctl() failed");

        if constexpr(max != 0) {
            const auto keys = unwrap(get_uinput_device_event_bits<event, max>(pfd));
            for(auto i = size_t(0); i < max; i += 1) {
                if(check_bit(keys, i)) {
                    dynamic_assert(ioctl(vfd, setbit, i) == 0, "ioctl() failed");
                }
            }
        }
    };

    inherit_all_events.template operator()<EV_SYN, 0, 0>();
    inherit_all_events.template operator()<EV_KEY, KEY_MAX, UI_SET_KEYBIT>();
    // inherit_all_events.template operator()<EV_REL, REL_MAX, UI_SET_RELBIT>();
    inherit_all_events.template operator()<EV_ABS, ABS_MAX, UI_SET_ABSBIT>();
    inherit_all_events.template operator()<EV_MSC, MSC_MAX, UI_SET_MSCBIT>();
    // inherit_all_events.template operator()<EV_SW, SW_MAX, UI_SET_SWBIT>();
    // inherit_all_events.template operator()<EV_LED, LED_MAX, UI_SET_LEDBIT>();
    // inherit_all_events.template operator()<EV_SND, SND_MAX, UI_SET_SNDBIT>();
    // inherit_all_events.template operator()<EV_REP, 0, 0>();
    // inherit_all_events.template operator()<EV_FF, FF_MAX, UI_SET_FFBIT>();
    // inherit_all_events.template operator()<EV_PWR, 0, 0>();
    // inherit_all_events.template operator()<EV_FF_STATUS, 0, 0>();

    auto setup = uinput_setup{
        .id = {
            .bustype = BUS_USB,
            .vendor  = 0,
            .product = 0,
            .version = 1,
        },
        .name           = "wch.cn CH57x",
        .ff_effects_max = 0,
    };
    dynamic_assert(ioctl(vfd, UI_DEV_SETUP, &setup) == 0, "ioctl() failed", errno);

    // ABS setup
    const auto abs_events = unwrap(get_uinput_device_event_bits<EV_ABS, ABS_MAX>(pfd));
    for(auto i = ABS_X; i < ABS_MAX; i += 1) {
        if(check_bit(abs_events, i)) {
            auto abs = uinput_abs_setup{.code = uint16_t(i), .absinfo = {}};
            dynamic_assert(ioctl(pfd, EVIOCGABS(i), &abs.absinfo) == 0, "ioctl() failed");
            dynamic_assert(ioctl(vfd, UI_ABS_SETUP, &abs) == 0, "ioctl() failed");
        }
    }

    dynamic_assert(ioctl(vfd, UI_DEV_CREATE) == 0, "ioctl() failed");

    return vfd;
}

auto fix_x_coordinate(const double v) -> double {
    auto r = double();
    if(v < 0.05) {
        r = v + (v / 0.05) * 0.02;
    } else if(v < 0.20) {
        r = v + (1 - (v - 0.05) / (0.20 - 0.05)) * 0.02;
    } else if(v < 0.80) {
        r = v;
    } else {
        r = v - ((v - 0.80) / 0.20) * 0.02;
    }
    // printf("X: %f -> %f\n", v, r);
    return r;
}

auto fix_y_coordinate(const double v) -> double {
    return v;
}

auto watcher(const int pfd, const int vfd) {
    auto event = input_event();
loop:
    if(read(pfd, &event, sizeof(event)) != sizeof(event)) {
        if(errno == ENODEV) {
            // device disconnected
            return;
        } else {
            warn("read() failed: ", errno);
            return;
        }
    }

    constexpr auto max_x = 2048.0;
    constexpr auto max_y = 2048.0;
    if(event.type == EV_ABS) {
        if(event.code == ABS_X || event.code == ABS_MT_POSITION_X) {
            event.value = max_x * fix_x_coordinate(event.value / max_x);
        } else if(event.code == ABS_Y || event.code == ABS_MT_POSITION_Y) {
            event.value = max_y * fix_y_coordinate(event.value / max_y);
        }
    }

    if(write(vfd, &event, sizeof(event)) != sizeof(event)) {
        warn("write() failed: ", errno);
        return;
    }
    goto loop;
}

auto main(const int argc, const char* const argv[]) -> int {
    if(argc != 2) {
        return 1;
    }

    const auto path = build_string("/dev/input/", argv[1]);

    try {
        const auto pfd = unwrap(open_uinput_device(path.data(), true));
        const auto vfd = create_virtual_device(pfd);
        watcher(pfd, vfd);
    } catch(const std::exception& e) {
        warn(e.what());
    }

    return 0;
}
