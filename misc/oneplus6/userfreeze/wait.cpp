#include <fcntl.h>
#include <linux/uinput.h>
#include <unistd.h>

auto main(const int argc, const char* argv[]) -> int {
    if(argc != 2) {
        return 1;
    }
    const auto fd = open(argv[1], O_RDONLY);
    if(fd == -1) {
        return 1;
    }
    if(ioctl(fd, EVIOCGRAB, 1) != 0) {
        return 1;
    }

    auto event = input_event();
    if(read(fd, &event, sizeof(event)) != sizeof(event)) {
        return 1;
    }
    return 0;
}
