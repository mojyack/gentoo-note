#include <sys/reboot.h>
#include <unistd.h>

int main() {
    sync();
    reboot(RB_AUTOBOOT);
    return 0;
}
