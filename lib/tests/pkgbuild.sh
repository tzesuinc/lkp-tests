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

	# packages location
	#   debian: /usr/lib/python3/dist-packages/ and /usr/local/lib/python3.x/dist-packages/
	#   centos: /usr/lib/python3.x/site-packages/ and /usr/local/lib/python3.x/site-packages/
	cp_to_pkg /usr/lib/python3*

	# /usr/local/lib/python3.11/dist-packages# ls -d avocado*
	# avocado  avocado_framework-107.0.egg-info  avocado_framework_plugin_vt-104.0.dist-info  avocado_vt
	#
	# # find / -name pytest
	# /usr/local/bin/pytest
	# /usr/local/lib/python3.9/site-packages/pytest
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

update_submodules()
{
	git submodule update --init --recursive
}

build_qemu()
{
	local qemu_branch=$1
	local qemu_commit=$2
	local qemu_config=x86_64-softmmu

	[[ -n "$qemu_commit" ]] || return
	[[ -n "$qemu_branch" ]] || return

	local qemu_remote=${qemu_branch%%/*}

	log_cmd cd "$srcdir/$qemu_remote"

	log_cmd git checkout -q $qemu_commit || return

	update_submodules || return

	log_cmd ./configure --target-list="$qemu_config" --disable-docs --enable-kvm --prefix=${pkgdir} || return

	unset LDFLAGS
	log_cmd make -j $nr_cpu 2>&1
}

pack_qemu()
{
	local qemu_branch=$1
	[ -n "$qemu_branch" ] || return

	local qemu_remote=${qemu_branch%%/*}

	log_cmd cd "$srcdir/$qemu_remote"

	log_cmd make install V=1 || return

	# remove var/run dir as it conflicts with debian rootfs which has /var/run links to /run
	log_cmd cd $pkgdir

	log_cmd ls -lrt
	log_cmd ls -lrt var/run
	log_cmd rm -rf var

	# create /bin/kvm link that app like avocado list requires kvm bin
	log_cmd ln -s qemu-system-x86_64 bin/kvm
}
