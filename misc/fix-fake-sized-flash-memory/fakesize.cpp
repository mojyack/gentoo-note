// env:
// faketarget: target device file e.g. /dev/sda
// fakesize:   faked disk size in bytes e.g. 32*1024*1024*1024 for 32GiB
//
// example:
// % clang++ -shared -o fakesize.so fakesize.cpp
// % export LD_PRELOAD=$PWD/fakesize.so
// % export faketarget=/dev/sdX
// % export fakesize=$((32*1024*1024*1024))
// % sgdisk ... /dev/sdX

#include <string>

#include <dlfcn.h>
#include <fcntl.h>
#include <linux/fs.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

namespace {
#define unpack_argp(type)            \
    va_list args;                    \
    type    argp;                    \
    va_start(args, request);         \
    argp = (type)va_arg(args, type); \
    va_end(args);

auto get_filename_from_fd(const int fd) -> std::string {
    auto       fdpath = std::string("/proc/self/fd/") + std::to_string(fd);
    auto       buf    = std::string(PATH_MAX, '\0');
    const auto len    = readlink(fdpath.data(), buf.data(), buf.size());
    if(len != -1) {
        buf.resize(len);
        return buf;
    } else {
        return "";
    }
}

using ioctl_t = typeof(int((int, int, void*)))*;

auto resolve_ioctl(int fd, int request, ...) -> int;

auto real_ioctl = (ioctl_t)resolve_ioctl;

auto resolve_ioctl(int fd, int request, ...) -> int {
    real_ioctl = (int (*)(int, int, void*))dlsym(RTLD_NEXT, "ioctl");
    unpack_argp(void*);
    return real_ioctl(fd, request, argp);
}
} // namespace

extern "C" {
int ioctl(int fd, unsigned long request, ...) {
    do {
        if(request != BLKGETSIZE && request != BLKGETSIZE64) {
            break;
        }
        const auto faketarget_str = getenv("faketarget");
        if(faketarget_str == NULL) {
            printf("faketarget not set");
            exit(1);
        }
        const auto target = get_filename_from_fd(fd);
        if(target.empty() || target != faketarget_str) {
            break;
        }
        auto block_size = 0;
        if(real_ioctl(fd, BLKSSZGET, &block_size) != 0) {
            printf("cannot get block size");
            break;
        }
        const auto fakesize_str = getenv("fakesize");
        if(fakesize_str == NULL) {
            printf("fakesize not set");
            exit(1);
        }
        const auto fakesize = atoll(fakesize_str);
        if(fakesize == 0) {
            break;
        }
        printf("faking size to %lld\n", fakesize);
        if(request == BLKGETSIZE) {
            unpack_argp(long*);
            *argp = fakesize / block_size;
        } else {
            unpack_argp(size_t*);
            *argp = fakesize;
        }
        errno = 0;
        return 0;
    } while(0);

    unpack_argp(void*);

    return real_ioctl(fd, request, argp);
}
}
