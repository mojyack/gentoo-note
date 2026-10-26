# Nintendo Switch: upstream vs L4T benchmark

Oct 26, 2026 · @mojyack

## Abstract
The upstream stack matches or beats L4T everywhere. It is 1.20-1.61x faster in Vulkan, 1.06-1.11x in Xonotic, level or ahead in GL (1.00-1.03x) and within 2% on CPU and memory. On the current Khronos CTS it has no EGL or GLES 2.0/3.0/3.1 failure against L4T's 167.

## Stacks compared
Ran on the same hardware (HAC-001, Erista), same SD card, same charger.

|  | Upstream | Downstream (switchroot L4T) |
| --- | --- | --- |
| Kernel | Linux 7.3.0-next-20261023 + 220 Tegra210/Switch patches (release config, ThinLTO) | 4.9.140-l4t, L4T R32.3.1 |
| GPU kernel driver | nouveau | nvgpu |
| GL / GLES | Mesa 27.0.0-devel (nvc0 + tegra), OpenGL 4.3 core/compat, GLES 3.2 | NVIDIA 32.3.1, OpenGL 4.6, GLES 3.2 |
| Vulkan | Mesa NVK, Vulkan 1.3.363 | NVIDIA 32.3.1, Vulkan 1.1.85 |
| Userspace | Arch Linux ARM, sway (Wayland) | Ubuntu 24.04, KDE Plasma on X11 (kwin compositing on) |
| Boot firmware | hekate, our bl31 + upstream U-Boot | hekate, switchroot bl31 + U-Boot |

## Performance
Clocks pinned as:
- GPU 1785 MHz
- GPU 921.6 MHz
- EMC 1600 MHz

Results. Higher is better.
| Test | Upstream | L4T | Ratio |
| --- | --- | --- | --- |
| vkmark 2025.01, on-screen fullscreen | 2566 | 1592 | 1.61 |
| vkmark 2025.01, offscreen 1280x720 | 5372 | 4488 | 1.20 |
| glmark2 2023.01, on-screen fullscreen | 1744 | 1694 | 1.03 |
| glmark2 2023.01, offscreen 1280x720 | 3380 | 3380 | 1.00 |
| Xonotic 0.8.6 timedemo, 1920x1080 normal (fps) | 145.5 | 131.1 | 1.11 |
| Xonotic 0.8.6 timedemo, 1920x1080 ultra (fps) | 90.8 | 83.3 | 1.09 |
| Xonotic 0.8.6 timedemo, 1280x720 normal (fps) | 149.1 | 140.2 | 1.06 |
| CoreMark, 1 thread (iter/s) | 8012 | 8109 | 0.99 |
| CoreMark, 4 threads (iter/s) | 32521 | 32488 | 1.00 |
| glibc memset, tinymembench (MB/s) | 10657 | 10652 | 1.00 |
| glibc memcpy, tinymembench (MB/s) | 3971 | 4031 | 0.99 |

## Conformance
| API (cases) | Upstream ~~strikethrough text~~pass | Upstream fail | Upstream not supported | L4T pass | L4T fail | L4T not supported |
| --- | --- | --- | --- | --- | --- | --- |
| EGL (3,789) | 2,453 | 0 | 1,336 | 2,391 | 1 | 1,397 |
| GLES 2.0 (17,165) | 17,046 | 0 | 111 | 16,997 | 49 | 97 |
| GLES 3.0 (44,800) | 44,613 | 0 | 172 | 44,237 | 115 | 394 |
| GLES 3.1 (37,802) | 37,539 | 0 | 262 | 37,591 | 2 | 209 |
| Vulkan, 10% sample (321,858) | 131,323 | 141 | 190,394 | 42,259 | 722 | 278,877 |
