#!/bin/bash

. $LKP_SRC/lib/debug.sh
. $LKP_SRC/lib/install.sh
. $LKP_SRC/lib/reproduce-log.sh

pip3_install()
{
	local package=$1

	local options
	pip3 install -h | grep -q break-system-packages && options="--break-system-packages"

	pip3 install $options $package
}

build_pahole()
{
	log_cmd cd "${srcdir}/pahole"

	mkdir build
	cd build

	log_cmd mkdir -p $pkgdir/usr
	log_cmd cmake -D__LIB=lib -DCMAKE_INSTALL_PREFIX=$pkgdir/usr ..
	log_cmd make install
}

build_dropwatch()
{
	cd $srcdir/dropwatch

	# when use latest 1.5.4 in Debian 10, compile error:
	# configure: error: libreadline is required
	# ==> ERROR: A failure occurred in build().
	#    Aborting...
	# so, keeps 1.5.3 in Debian 10/Debian 11.
	local distro=$(basename $rootfs)
	if [[ "$distro" =~ "debian-12" ]]; then
		git checkout v1.5.4 || return
	else
		git checkout v1.5.3 || return
	fi

	./autogen.sh || return
	./configure --prefix=$benchmark_path/$pkgname/dropwatch || return
	make || return
	make install
}

build_iproute2()
{
	cd $srcdir/iproute2-next

	./configure || return
	make || return
	DESTDIR=$benchmark_path/$pkgname/iproute2-next make install
}

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

	pip3_install avocado-framework
	pip3_install git+https://github.com/avocado-framework/avocado-vt

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
