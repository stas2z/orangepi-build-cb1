# DO NOT EDIT THIS FILE
#
# Please edit /boot/orangepiEnv.txt to set supported parameters
#

# default values
setenv load_addr "0x45000000"
setenv rootdev "/dev/mmcblk0p1"
setenv verbosity "1"
setenv rootfstype "ext4"
setenv console "both"
setenv docker_optimizations "off"
setenv bootlogo "false"
setenv emmc_max_frequency "0x5f5e100"
setenv debug_uart "ttyS0"

# Print boot source
#itest.b *0x10028 == 0x00 && echo "U-boot loaded from SD"
#itest.b *0x10028 == 0x02 && echo "U-boot loaded from eMMC or secondary SD"
#itest.b *0x10028 == 0x03 && echo "U-boot loaded from SPI"

echo "Boot script loaded from ${devtype}"

if test -e ${devtype} ${devnum} ${prefix}orangepiEnv.txt; then
	load ${devtype} ${devnum} ${load_addr} ${prefix}orangepiEnv.txt
	env import -t ${load_addr} ${filesize}
fi

if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=${debug_uart},115200 console=tty1"; fi
if test "${console}" = "serial"; then setenv consoleargs "console=${debug_uart},115200"; fi
if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.orangepi ${consoleargs}"; fi

# get PARTUUID of first partition on SD/eMMC it was loaded from
# mmc 0 is always mapped to device u-boot (2016.09+) was loaded from
if test "${devtype}" = "mmc"; then part uuid mmc 0:1 partuuid; fi

setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 loglevel=${verbosity} ubootpart=${partuuid} disp_reserve=${disp_reserve} ${extraargs} ${extraboardargs}"

if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi

#load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
#fdt addr -c ${fdt_addr_r}
#fdt addr ${fdt_addr_r}
#fdt resize 65536

fdt set disp boot_fb0 ${boot_fb0}
fdt set disp boot_disp <${boot_disp}>
fdt set disp boot_disp1 <${boot_disp1}>
fdt set disp boot_disp2 <${boot_disp2}>
fdt set disp tv_vdid <${tv_vdid}>

fdt set disp fb0_width <${fb0_width}>
fdt set disp fb0_height <${fb0_height}>

fdt set mmc0 cap-sd-highspeed
#fdt set mmc0 sd-uhs-sdr50
#fdt set mmc0 sd-uhs-ddr50
#fdt set mmc0 sd-uhs-sdr104

if test "${mmc_bootdev}" = "2"; then

	if test "${emmc_max_frequency}" = "0x5f5e100"; then

		fdt set /soc/sdmmc@04022000 cap-mmc-highspeed
		fdt set /soc/sdmmc@04022000 mmc-ddr-1_8v
		fdt set /soc/sdmmc@04022000 mmc-hs200-1_8v
		fdt set /soc/sdmmc@04022000 mmc-hs400-1_8v
	fi

	echo "Set emmc_max_frequency to ${emmc_max_frequency}"
	fdt set /soc/sdmmc@04022000 max-frequency <${emmc_max_frequency}>
fi

for overlay_file in ${user_overlays}; do
        if load ${devtype} ${devnum} ${load_addr} ${prefix}overlay-user/${overlay_file}.dtbo; then
                echo "Applying user provided DT overlay ${overlay_file}.dtbo"
                fdt apply ${load_addr} || setenv overlay_error "true"
        fi
done

load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}uInitrd
load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}uImage

bootm ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}

# Recompile with:
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
