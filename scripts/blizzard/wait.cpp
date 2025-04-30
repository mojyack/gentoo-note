#include <array>
#include <vector>

#include <fcntl.h>
#include <linux/uinput.h>
#include <poll.h>
#include <stdio.h>
#include <unistd.h>

#define ensure(cond)                                  \
    if(!(cond)) {                                     \
        printf("assertion failed at %d\n", __LINE__); \
        return 1;                                     \
    }

namespace {
auto is_wakeup_event(const input_event& event) -> bool {
    // printf("event %d %d %d\n", event.type, event.code, event.value);
    const static auto ignore_events = std::array{
        input_event{.type = EV_SYN, .code = SYN_REPORT, .value = 0},
        input_event{.type = EV_SW, .code = SW_LID, .value = 1}, // lid close
    };
    for(const auto& ignore : ignore_events) {
        if(ignore.type == event.type && ignore.code == event.code && ignore.value == event.value) {
            return false;
        }
    }
    return true;
}
} // namespace

auto main(const int argc, const char* const* argv) -> int {
    ensure(argc >= 2);
    auto fds = std::vector<pollfd>(argc - 1);
    for(auto i = 1; i < argc; i += 1) {
        const auto fd = open(argv[i], O_RDONLY);
        ensure(fd >= 0);
        ensure(ioctl(fd, EVIOCGRAB, 1) == 0);
        fds[i - 1] = pollfd{.fd = fd, .events = POLLIN};
    }
    auto event  = input_event();
    auto finish = false;
    while(!finish) {
        ensure(poll(fds.data(), fds.size(), -1) > 0);
        for(auto& pfd : fds) {
            if(pfd.revents & POLLIN) {
                ensure(read(pfd.fd, &event, sizeof(event)) == sizeof(event));
                finish |= is_wakeup_event(event);
            }
        }
    }
    return 0;
}
