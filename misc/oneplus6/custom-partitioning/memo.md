OP6 has 6 UFS LUs(logical units), 106 partitions in total.  
I wondered which of these partitions were really necessary to run mainline Linux, so I experimented.  
And finally, I could reduce the number of partitions to 26.  
This is a note of what I learned in the process.

If you are going to be reckless and try this, you must back up all your disks first.

# bootloaders
Before linux, there are 3 stages of boot.  
## PBL
Primary Boot Loader(PBL) is a first stage.  
This is written inside the SoC and cannot be changed.  
PBL reads the next step, XBL, from the configured disk(sdb or sdc) and starts it.  
If XBL is not found, it will activate EDL mode and wait for a connection.
## XBL
Extensible Boot Loader(XBL) is stored in sdb or sdc.  
XBL reads the next step, ABL, from sde and starts it.  
If ABL is not found, it will prompt `any key to shutdown` and halt.
## ABL
Android Boot Loader(ABL) is stored in sde.  
ABL reads the `boot` partition from sde and boots Linux in it.  
During the process, it checks the `devinfo` partition and refuses to boot an unsigned boot image if the bootloader is not unlocked.  
If a valid boot image is not found, the device will go into fastboot mode.

# A/B slot
All system partitions exist in two versions: one with _a at the end and one with _b at the end.  
Which one is used depends on whether XBL was booted from `xbl_a` or `xbl_b`.  
Which xbl is used can be configured with ufs-utils(https://github.com/westerndigitalcorporation/ufs-utils):
```
# use xbl_a
% ufs-utils attr -t 0 -w 1 -p /dev/bsg/ufs-bsg0
# use xbl_b
% ufs-utils attr -t 0 -w 2 -p /dev/bsg/ufs-bsg0
```
It can also be set from the Firehose command:
```
# use xbl_a
firehose% <?xml version="1.0" ?><data><setbootablestoragedrive value="1" /></data>
# use xbl_b
firehose% <?xml version="1.0" ?><data><setbootablestoragedrive value="2" /></data>
```

# Partition type code
Most partitions are identified by their type code.  
Therefore, when you create a new partition, you must set the correct type code.  
Also, it seems that partitions belonging to the inactive slot will have their type code set to `77036CD4-03D5-42BB-8ED1-37E5A88BAA34`.

# Partition attributes
In GPT, all partitions have 64-bit attributes.  
The important bits in Android are the 12 bits from bit-48 to bit-59.
```
595857565554535251504948
0 0 0 0 0 0 0 0 0 0 0 0
              ^ ^ ^ ^ ACTIVE
                ^SLOT ACTIVE
          ^SUCCESS
        ^UNBOOTABLE
^ ^ ^ ^RETRY COUNT
```
The 4 bits from bit-48 to bit-51 indicate whether that partition is active. In particular, bit-50 indicates whether the slot (a/b) is the currently used slot.  
bit-56 to bit-59 is a boot retry count.  
I am not sure what the remaining three bits mean, but it seems like they should all be set to 1.  
Bit 54 is set by the OS when the OS boots successfully, indicating to the bootloader that the slot is operational.  
If this bit is not set, the bootloader may automatically change the configuration to use a different slot.  
Bit 55 indicates that the partition is not available. If this bit is set, the bootloader will ignore that partition.

For example:
```
% sgdisk -i 6 /dev/sde
Partition GUID code: 20117F86-E985-4357-B9EE-374BC1D8487D (Android boot 2)
Partition unique GUID: 41888D5E-8E0F-4B5A-96FF-7BEA25C12CA1
First sector: 3584 (at 14.0 MiB)
Last sector: 19967 (at 78.0 MiB)
Partition size: 16384 sectors (64.0 MiB)
Attribute flags: 007F000000000000
Partition name: 'boot_a'
```
One byte from 48 bits from the attribute 0x007F000000000000 is 0x7F.
0x7F is 0b01111111, so ACTIVE=1111, SUCCESS=1, UNBOOTABLE=0.

# Deletable partitions
## sda
The partitions in sda can be deleted except for `reserve1`.  
It seems that `reserve1` is used to store the bootloader logs.  
The device will boot without it, but the bootloader will run very slowly.  
The `reserve1` partition can be moved to another LU other than sda. The type code of the partition does not seem to matter, only whether its name is `reserve1` or not.  
As noted below, if you do not patch the `vbmeta` partition in sde, ABL will refuse to boot when the `system` partition has been resized or deleted, resulting in this `Failed to load/authenticate boot image: Load Error` odd error.

## sdb sdc
These LUs store xbl.  
If only one stot will be used, one can be erased.  
There are two partitions in the LU, `xbl` and `xbl_config`, but there seems to be data hidden outside the partitions, so simply copying the partitions did not work.  
If you want to swap sdb and sdc, you have to clone the entire LU.
## sdd
This LU has a `cdt` partition and a `ddr` partition.  
These seem to store RAM settings and are essential for boot.  
It is possible to recreate the partition table, but the `cdt` and `ddr` partitions must be placed on a fixed sector.
## sde
This LU has so many partitions, but many of them are not essential to boot.  
The essential partitions are:  
```
aop_a         # ?
tz_a          # trustzone
hyp_a         # hypervisor
abl_a         # abl
keymaster_a   # for android verified boot?
boot_a        # boot image
cmnlib_a      # for android verified boot?
cmnlib64_a    # for android verified boot?
devcfg_a      # ?
qupfw_a       # ?
vbmeta_a      # for android verified boot?
dtbo_a        # dtbo. usually erased, but it has to exist.
storsec_a     # ?
devinfo       # bootloader unlock state
boot_b        # without this, fastboot will fail. so put a dummy. size can be one sector.
```
These partitions are position-independent as long as the size, type code, and label match.  
To change the `system` partition in sda, the `vbmeta` partition needs to be patched. See https://github.com/libxzr/vbmeta-disable-verification
## sdf
This LU has modem configurations.  
The device can boot without it, but the modem will not work.  
Also, the position of the partitions is fixed.  
