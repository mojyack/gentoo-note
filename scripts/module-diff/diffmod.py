import subprocess
import os
import sys

get = os.path.dirname(__file__) + "/kernel-module-name/get-64"

def exec(command):
    result = subprocess.run(command, stdout=subprocess.PIPE)
    return result.stdout.decode("utf-8")

def get_module_name(path):
    return exec([get, path]).rstrip()

modules_built = []
if len(sys.argv) >= 2:
    module_dir = sys.argv[1]
else:
    kernel_version = exec(["uname", "-r"]).rstrip()
    module_dir = f"/lib/modules/{kernel_version}/kernel"

for m in exec(["find", module_dir, "-name", "*.ko"]).split('\n'):
    if len(m) == 0:
        continue
    modules_built.append(get_module_name(m))

modules_loaded = []
for m in exec(["lsmod"]).split('\n')[1:]:
    if len(m) == 0:
        continue
    modules_loaded.append(m[:m.find(' ')])

modules_not_used = modules_built
modules_not_built = []
for m in modules_loaded:
    try:
        modules_not_used.remove(m)
    except ValueError:
        modules_not_built.append(m)

print("these modules are built but not used:")
for m in modules_not_used:
    print(f"    {m}")

print("these modules are loaded but not built")
for m in modules_not_built:
    print(f"    {m}")
