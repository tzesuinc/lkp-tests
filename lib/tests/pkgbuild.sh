#!/bin/bash

. $LKP_SRC/lib/debug.sh
. $LKP_SRC/lib/install.sh
. $LKP_SRC/lib/reproduce-log.sh

build_edk2()
{
	log_cmd cd "$srcdir/edk2"

	source edksetup.sh BaseTools

	git submodule init
	git submodule update --recursive || return

	log_cmd make -C BaseTools/Source/C || return

	# generate Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd
	log_cmd OvmfPkg/build.sh -a X64 -n 112
}

pack_edk2()
{
	cp_to_pkg "$srcdir/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd" "${pkgdir}/lkp/benchmarks/edk2/Build/OvmfX64/DEBUG_GCC5/FV"
}

pack_avocado_vt()
{
	local avocado_data_dir=$1
	local avocado_conf_file=/etc/avocado/avocado.conf

	pip3 install --break-system-packages avocado-framework
	pip3 install --break-system-packages git+https://github.com/avocado-framework/avocado-vt

	log_cmd mkdir -p "$(dirname $avocado_conf_file)"
	log_cmd mkdir -p "$avocado_data_dir"

	cat <<EOT > $avocado_conf_file
[datadir.paths]
data_dir = $avocado_data_dir
EOT

	log_cmd avocado vt-bootstrap --yes-to-all --vt-type qemu

	# reduce package size
	rm -rf $avocado_data_dir/avocado-vt/images/*
	find $avocado_data_dir/avocado-vt/virttest/test-providers.d -name .git -type d | xargs rm -rf

	cp_to_pkg "$avocado_conf_file"
	cp_to_pkg "$avocado_data_dir"
	cp_to_pkg /usr/lib/python3

	# /usr/local/lib/python3.11/dist-packages# ls -d avocado*
	# avocado  avocado_framework-107.0.egg-info  avocado_framework_plugin_vt-104.0.dist-info  avocado_vt
	cp_to_pkg /usr/local
}

# cp_to_pkg /usr/lib/python3
# cp_to_pkg "$srcdir/lkvs/KVM" "${pkgdir}/lkp/benchmarks/lkvs"
cp_to_pkg()
{
	local src="$1"
	local dst_dir="${2:-${pkgdir}$(dirname $src)}"

	log_cmd mkdir -p "$dst_dir"
	log_cmd cp -af $src "$dst_dir"
}
