#!/bin/sh

# luna firmware upgrade  script
# $1 image destination (0 or 1) 
# Kernel and root file system images are assumed to be located at the same directory named uImage and rootfs respectively
# ToDo: use arugements to refer to kernel/rootfs location.

k_img="uImage"
r_img="rootfs"
c_img="custconf"
img_ver="fwu_ver"
img_sh="fwu.sh"
md5_cmp="md5.txt"
md5_cmd="/bin/md5sum"
#md5 run-time result
md5_tmp="md5_tmp" 
md5_rt_result="md5_rt_result.txt"
new_fw_ver="new_fw_ver.txt"
cur_fw_ver="cur_fw_ver.txt"
env_sw_ver="env_sw_ver.txt"
hw_ver_file="hw_ver"
skip_hwver_check="/tmp/skip_hwver_check"
single_part=0

# For YueMe framework
framework_img="framework.img"
framework_sh="framework.sh"
framework_upgraded=0

custconf_upgrade=0
if 
	cat /var/config/lastgood.xml | grep 'Value Name="ONUTYPE_CHECK_SWITCH" Value="1"'
then
###################Onu type Compare####################
	tar -xf $2 $img_ver 
	UpgradeOnuType=$(sed -n 2p $img_ver)
	echo ONU type Compare in...
	echo "will upgrade onu type : $UpgradeOnuType"
	if cat /proc/onu_type | grep $UpgradeOnuType; then 
		echo "onu type is the same........"
	else
		echo "onu type is not the same........"
		reboot
		exit 1
	fi  
elif 
	cat /var/config/lastgood.xml | grep 'Value Name="ONUTYPE_CHECK_SWITCH" Value="0"'
then
	echo "Switch ONUTYPE_CHECK_SWITCH is 0 , skip the onu check........"
else
###################Onu type Compare####################
	tar -xf $2 $img_ver 
	UpgradeOnuType=$(sed -n 2p $img_ver)
	echo ONU type Compare in...
	echo "will upgrade onu type : $UpgradeOnuType"
	if cat /proc/onu_type | grep $UpgradeOnuType; then 
		echo "onu type is the same........"
	else
		echo "onu type is not the same........"
		reboot
		exit 1
	fi  
fi

# Stop this script upon any error
# set -e

if [ "`tar -tf $2 $framework_sh`" = "$framework_sh" ] && [ "`tar -tf $2 $framework_img`" = "$framework_img" ]; then
    echo "Updaing framework from $2"
    tar -xf $2 $framework_sh
    grep $framework_sh $md5_cmp > $md5_tmp
    $md5_cmd $framework_sh > $md5_rt_result
    diff $md5_rt_result $md5_tmp

    if [ $? != 0 ]; then 
        echo "$framework_sh md5_sum inconsistent, aborted image updating !"
        exit 1
    fi

    # Run firmware upgrade script extracted from image tar ball
    sh $framework_sh $2
    framework_upgraded=1
fi

if [ "`tar -tf $2 $k_img`" = '' ] && [ $framework_upgraded = 1 ]; then
    echo "No uImage for upgrading, skip"
    exit 2
fi
if [ "`tar -tf $2 $c_img`" = "$c_img" ]; then
    custconf_upgrade=1
fi
echo "Updating image $1 with file $2"

# Find out kernel/rootfs mtd partition according to image destination

:<<!
k_mtd="/dev/"`cat /proc/mtd | grep -w \"k"$1"\" | sed 's/:.*$//g'`
r_mtd="/dev/"`cat /proc/mtd | grep -w \"r"$1"\" | sed 's/:.*$//g'`
k_mtd_size=`cat /proc/mtd | grep -w \"k"$1"\" | sed 's/^.*: //g' | sed 's/ .*$//g'`
r_mtd_size=`cat /proc/mtd | grep -w \"r"$1"\" | sed 's/^.*: //g' | sed 's/ .*$//g'`

echo "kernel image is located at $k_mtd"
echo "rootfs image is located at $r_mtd"
!

if 
        cat /proc/mtd | grep "\"k1\""
then    
        kname="k"$1""
        rname="r"$1""
		frameworkname="framework"$(($1+1))""
else
		single_part=1
        kname="k0"
        rname="r0"
		frameworkname="framework1"
fi
k_mtd="/dev/"`cat /proc/mtd | grep -w "$kname" | sed 's/:.*$//g'`
r_mtd="/dev/"`cat /proc/mtd | grep -w "$rname" | sed 's/:.*$//g'`
k_mtd_size=`cat /proc/mtd | grep -w "$kname" | sed 's/^.*: //g' | sed 's/ .*$//g'`
r_mtd_size=`cat /proc/mtd | grep -w "$rname" | sed 's/^.*: //g' | sed 's/ .*$//g'`
echo "kernel image is located at $k_mtd size $k_mtd_size"
echo "rootfs image is located at $r_mtd size $r_mtd_size"

if [ $custconf_upgrade = 1 ]; then
	c_mtd="/dev/"`cat /proc/mtd | grep "$frameworkname" | sed 's/:.*$//g'`
	c_mtd_size=`cat /proc/mtd | grep "$frameworkname" | sed 's/^.*: //g' | sed 's/ .*$//g'`
	echo "custconf image is located at $c_mtd size $c_mtd_size"
fi

if [ -f $skip_hwver_check ]; then
    echo "Skip HW_VER check!!"
else
    img_hw_ver=`tar -xf $2 $hw_ver_file -O`
    mib_hw_ver=`flash get HW_HWVER | sed s/HW_HWVER=//g`
    if [ "$img_hw_ver" = "skip" ]; then
        echo "skip HW_VER check!!"
    else
        echo "img_hw_ver=$img_hw_ver mib_hw_ver=$mib_hw_ver"
        if [ "$img_hw_ver" != "$mib_hw_ver" ]; then
            echo "HW_VER $img_hw_ver inconsistent, aborted image updating !"
            exit 1
        fi
    fi
fi

# Extract img_ver
tar -xf $2 $img_ver -O | md5sum | sed 's/-/'$img_ver'/g' > $md5_rt_result
# Check integrity
grep $img_ver $md5_cmp > $md5_tmp
diff $md5_rt_result $md5_tmp

if [ $? != 0 ]; then
    echo "$img_ver""md5_sum inconsistent, aborted image updating !"
    exit 1
fi

# Extract hw_ver_file
tar -xf $2 $hw_ver_file -O | md5sum | sed 's/-/'$hw_ver_file'/g' > $md5_rt_result
# Check integrity
grep $hw_ver_file $md5_cmp > $md5_tmp
diff $md5_rt_result $md5_tmp

if [ $? != 0 ]; then
    echo "$hw_ver_file""md5_sum inconsistent, aborted image updating !"
    exit 1
fi

# Extract img_sh
tar -xf $2 $img_sh -O | md5sum | sed 's/-/'$img_sh'/g' > $md5_rt_result
# Check integrity
grep $img_sh $md5_cmp > $md5_tmp
diff $md5_rt_result $md5_tmp

if [ $? != 0 ]; then
    echo "$img_sh""md5_sum inconsistent, aborted image updating !"
    exit 1
fi

# Extract kernel image
tar -xf $2 $k_img -O | md5sum | sed 's/-/'$k_img'/g' > $md5_rt_result
# Check integrity
grep $k_img $md5_cmp > $md5_tmp
diff $md5_rt_result $md5_tmp

if [ $? != 0 ]; then
    echo "$k_img""md5_sum inconsistent, aborted image updating !"
    exit 1
fi

# Extract rootfs image
tar -xf $2 $r_img -O | md5sum | sed 's/-/'$r_img'/g' > $md5_rt_result
# Check integrity
grep $r_img $md5_cmp > $md5_tmp
diff $md5_rt_result $md5_tmp

if [ $? != 0 ]; then
    # rm $r_img
    echo "$r_img""md5_sum inconsistent, aborted image updating !"
    exit 1
fi

# Extract custconf image
if [ $custconf_upgrade = 1 ]; then
# Extract rootfs image
    tar -xf $2 $c_img -O | md5sum | sed 's/-/'$c_img'/g' > $md5_rt_result
# Check integrity
    grep $c_img $md5_cmp > $md5_tmp
    diff $md5_rt_result $md5_tmp

    if [ $? != 0 ]; then
        echo "$c_img""md5_sum inconsistent, aborted image updating !"
        exit 1
    fi
fi

if [ $custconf_upgrade = 1 ]; then
    echo "Integrity of $k_img, $r_img & $c_img is okay."
else
    echo "Integrity of $k_img & $r_img is okay."
fi

date_vlan10_flag=191129
date_vlan10_0=$(sed -n 1p /etc/version | awk -F"-" '{print $2}')
date_vlan10_1=$(sed -n 1p /etc/version | awk -F"-" '{print $3}')
if echo $date_vlan10_0 | grep -q '[^0-9]'
then
	echo "$date_vlan10_0 is not a num,please input num"
	if echo $date_vlan10_1 | grep -q '[^0-9]'
	then
			echo "$date_vlan10_1 is not a num,please input num"
	else
		date_vlan10=$date_vlan10_1
	fi
else
	date_vlan10=$date_vlan10_0
fi
if cat /var/config/lastgood.xml | grep "Name=\"LAN_VLAN_ID1\" Value=\"9\""; then 
	if [ $date_vlan10 -le $date_vlan10_flag ];then
		echo $date_vlan10 is less than $date_vlan10_flag,should set LAN_VLAN_ID1 to 3003 now...
		flash set LAN_VLAN_ID1 3003
	fi
fi
if cat /var/config/lastgood.xml | grep "Name=\"LAN_VLAN_ID2\" Value=\"10\""; then 
	if [ $date_vlan10 -le $date_vlan10_flag ];then
		echo $date_vlan10 is less than $date_vlan10_flag,should set LAN_VLAN_ID2 to 3004 now...
		flash set LAN_VLAN_ID2 3004
	fi
fi

echo "Firware version check okay."
flash set SUPPORT_ZTE_IPHOST 0
sleep 1

killall cwmpClient
killall spppd
killall vsntp
killall dnsmasq
killall udhcpd
killall udhcpc
killall monitord
killall igmpproxy
killall igmp_pid
killall cwmp
killall wscd-wlan0
killall mini_upnpd
killall smbd
killall upnpmd_cp
killall iwcontrol
killall loopback
killall systemd
killall pondetect
#killall configd
killall ecmh
killall radvd
killall inetd

sync
sleep 2
echo 3 > /proc/sys/vm/drop_caches
sleep 1

ps
cat /proc/meminfo
sleep 2

tar -xf $2 $k_img
string="`ls -l | grep $k_img`"
mtd_size_dec="`printf %d 0x$k_mtd_size`"
img_size_dec="`expr substr "$string" 34 100 | sed 's/^ *//g' | sed 's/ .*$//g'`"
expr "$img_size_dec" \< "$mtd_size_dec" > /dev/null
if [ $? != 0 ]; then
	echo "uImage size too big($img_size_dec) !"
	echo "3" > /var/firmware_upgrade_status
	exit 1
fi
tar -xf $2 $r_img
string="`ls -l | grep $r_img`"
mtd_size_dec="`printf %d 0x$r_mtd_size`"
img_size_dec="`expr substr "$string" 34 100 | sed 's/^ *//g' | sed 's/ .*$//g'`"
expr "$img_size_dec" \< "$mtd_size_dec" > /dev/null
if [ $? != 0 ]; then
	echo "rootfs size too big($img_size_dec) !"
	echo "3" > /var/firmware_upgrade_status
	exit 1
fi
if [ $custconf_upgrade = 1 ]; then
	tar -xf $2 $c_img
	string="`ls -l | grep $c_img`"
	mtd_size_dec="`printf %d 0x$c_mtd_size`"
	img_size_dec="`expr substr "$string" 34 100 | sed 's/^ *//g' | sed 's/ .*$//g'`"
	expr "$img_size_dec" \< "$mtd_size_dec" > /dev/null
	if [ $? != 0 ]; then
		echo "custconf size too big($img_size_dec) !"
		echo "3" > /var/firmware_upgrade_status
		exit 1
	fi
fi

tempversion=$(cat $img_ver | sed -n 1p | awk '{printf $1}')
echo "version: $tempversion"

# Write image version information 
if [ $single_part = 0 ]; then
	nv setenv sw_version"$1" $tempversion
else
	echo "is single partion so set double ver"
	nv setenv sw_version0 $tempversion
	nv setenv sw_version1 $tempversion
fi

nv getenv sw_version0
nv getenv sw_version1
	
#echo 80 > /proc/luna_watchdog/kick_wdg_time	

if [ $custconf_upgrade = 1 ]; then
	echo "uImage\rootfs\custconf size check okay, start updating ..."
else
	echo "Both uImage and rootfs size check okay, start updating ..."
fi

if [ $single_part != 0 ]; then
	echo 0 > /proc/luna_watchdog/watchdog_flag
else
	echo 80 > /proc/luna_watchdog/kick_wdg_time
fi

# Erase kernel partition 
#flash_eraseall $k_mtd
flash_erase $k_mtd 0 0
# Write kernel partition
echo "Writing $k_img to $k_mtd"
cp $k_img $k_mtd;rm  $k_img
sleep 2

# Erase rootfs partition 
#flash_eraseall $r_mtd
flash_erase $r_mtd 0 0
# Write rootfs partition
echo "Writing $r_img to $r_mtd"
cp $r_img $r_mtd
sleep 2

if [ $custconf_upgrade = 1 ]; then
	# Erase rootfs partition 
	#flash_eraseall $c_mtd
	flash_erase $c_mtd 0 0
	# Write rootfs partition
	echo "Writing $c_img to $c_mtd"
	cp $c_img $c_mtd
fi

if [ $single_part != 0 ]; then
	echo 1 > /proc/luna_watchdog/watchdog_flag	
	echo 80 > /proc/luna_watchdog/kick_wdg_time			#need >62
	echo "will set watch dog kick time to 80s"
fi

# Clean up temporary files
rm -f $md5_cmp $md5_tmp $md5_rt_result $img_ver $env_sw_ver $r_img $2 $c_img

date_after=190813
date_before=190611
date_0=$(sed -n 1p /etc/version | awk -F"-" '{print $2}')
date_1=$(sed -n 1p /etc/version | awk -F"-" '{print $3}')
if echo $date_0 | grep -q '[^0-9]'
then
	echo "$date_0 is not a num,please input num"
	if echo $date_1 | grep -q '[^0-9]'
	then
			echo "$date_1 is not a num,please input num"
	else
		date=$date_1
	fi
else
	date=$date_0
fi
if cat /var/config/lastgood_hs.xml | grep "Name=\"PON_MODE\" Value=\"1\""; then 
	echo "GPON........"
	if [ $date -ge $date_before ];then
		if [ $date -lt $date_after ];then
			echo $date is less than $date_after and lager than $date_before,should set sw_active and sw_commit now...
			nv setenv sw_active $1
			nv setenv sw_commit $1
		fi
	fi
else
	echo "EPON........"
fi

# Post processing (for future extension consideration)
echo "Successfully updated image $1!!"

