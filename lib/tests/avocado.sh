#!/bin/bash

. $LKP_SRC/lib/reproduce-log.sh
. $LKP_SRC/lib/debug.sh
. $LKP_SRC/lib/env.sh
. $LKP_SRC/lib/upload.sh

avocado_conf_file="/etc/avocado/avocado.conf"
avocado_data_dir="/lkp/benchmarks/avocado/data"
avocado_result_dir="/tmp/avocado/result"

setup_conf()
{
	[[ -f $avocado_conf_file ]] || return

	log_cmd mkdir -p "$avocado_result_dir" || return

	# After test finished, upload $base_dir which includes all testting info.
	cat <<EOT >> $avocado_conf_file
logs_dir = $avocado_result_dir
EOT
}

run_test()
{
	local config_file=$1

	if [[ $config_file ]]; then
		log_cmd avocado run --vt-config $config_file 2>&1
	else
		echo "$group total tests $(avocado list | grep \.$group\. | wc -l)"
		# avocado-vt type_specific.io-github-autotest-qemu.blockdev_commit_backing_file
		# avocado-vt io-github-autotest-qemu.vlan.vlan_connective_test
		# avocado-vt type_specific.lkvs.boot_check.vm.16G.208_cpu
		local test
		log_cmd avocado list | grep \.$group\. | cut -d' ' -f2 | while read test; do
			log_cmd avocado run $test 2>&1
		done
	fi
}

setup_env()
{
	# required for lkvs
	lsmod | grep tun || modprobe tun

	# resolve libvirtd service issue
	# 	libvirtd[9640]: libvirt version: 9.0.0, package: 9.0.0-4+deb12u1 (Debian)
	# 	libvirtd[9640]: invalid argument: Failed to parse user 'libvirt-qemu'
	# 	libvirtd[9640]: Initialization of QEMU state driver failed: invalid argument: Failed to parse user 'libvirt-qemu'
	#	libvirtd[9640]: Driver state initialization failed
	addgroup --system libvirt-qemu
	adduser --system --ingroup libvirt-qemu --home /var/lib/libvirt --no-create-home --shell /bin/false libvirt-qemu

	log_cmd systemctl restart libvirtd || return
	# sleep enough time to avoid the failure of later net-define
	sleep 300
	log_cmd systemctl status libvirtd

	# create virbr0 interface that is a virtual network bridge
	log_cmd virsh net-define /usr/share/libvirt/networks/default.xml || return
	log_cmd virsh net-start default

	# The standard package for Open vSwitch on Debian is named openvswitch-switch, while avocado-vt requires to restart the openvswitch service
	log_cmd mv /lib/systemd/system/openvswitch-switch.service /lib/systemd/system/openvswitch.service
	log_cmd sed -i 's/openvswitch-switch/openvswitch/g' /lib/systemd/system/openvswitch.service
	# to recognize the new service file
	log_cmd systemctl daemon-reload
}

install_lkvs_tests()
{
	cat <<EOT > $avocado_data_dir/avocado-vt/virttest/test-providers.d/lkvs.ini
[provider]
uri: file:///lkp/benchmarks/lkvs

[qemu]
subdir: KVM/qemu
EOT

	# to install the lkvs tests actually
	log_cmd avocado vt-bootstrap --vt-no-downloads --vt-type qemu

	avocado list | grep lkvs | sort > $avocado_result_dir/tests
}
