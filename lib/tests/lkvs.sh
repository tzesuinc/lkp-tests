#!/bin/bash

. $LKP_SRC/lib/debug.sh
. $LKP_SRC/lib/reproduce-log.sh
. $LKP_SRC/lib/env.sh

build_libipt()
{
	cd $BENCHMARK_ROOT/$testcase/libipt && cmake . && make install
}

build_lkvs_tools()
{
	log_cmd cd $BENCHMARK_ROOT/$testcase/lkvs/BM/tools || return

	log_cmd make --keep-going || {
		echo "tools make fail"
		return 1
	}

	return 0
}

build_lkvs()
{
	build_lkvs_tools || return

	[[ -f $BENCHMARK_ROOT/$testcase/lkvs/BM/$test/Makefile ]] || return 0

	cd $BENCHMARK_ROOT/$testcase/lkvs/BM/$test || return

	if [[ $test = workload-xsave ]]; then
		log_cmd mkdir build
		log_cmd cd build
		log_cmd cmake ..
	fi

	log_cmd make --keep-going || {
		echo "$test make fail"
		return 1
	}

	[[ $test = ras ]] && log_cmd make install

	return 0
}

fixup_tdx_compliance()
{
	log_cmd insmod tdx-compliance/tdx-compliance.ko
	echo all > /sys/kernel/debug/tdx/tdx-tests
	log_cmd cat /sys/kernel/debug/tdx/tdx-tests
}

fixup_splitlock()
{
	cat /proc/cpuinfo | grep -q split_lock_detect || die "split_lock_detect not supported on current CPU"
}

fixup_rapl_server()
{
	log_cmd modprobe -v intel_rapl_msr
}

alias fixup_rapl_client=fixup_rapl_server

runtests()
{
	# for glxgears on centos, which is located at /usr/lib64/mesa/glxgears
	export PATH="$PATH:/usr/lib64/mesa"
	# libipt.so.2 is installed in /usr/local/lib
	export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

	cd $BENCHMARK_ROOT/$testcase/lkvs/BM || return

	if [[ $(type -t "fixup_${test//-/_}") =~ (alias|function) ]]; then
		fixup_${test//-/_} || return
	fi

	if [[ -f $test/tests ]]; then
		log_cmd ./runtests -f $test/tests
	else
		case $test in
			cstate-client)
				log_cmd ./runtests -f cstate/tests-client
				;;
			cstate-server)
				log_cmd ./runtests -f cstate/tests-server
				;;
			fred)
				log_cmd insmod fred/fred_test_driver.ko
				# No doc about how to get the test result after loading the module
				;;
			guest-test)
				log_cmd ./runtests -f guest-test/guest.test_launcher.sh
				;;
			prefetchi)
				log_cmd prefetchi/prefetchi
				;;
			rapl-client)
				log_cmd ./runtests -f rapl/tests-client
				;;
			rapl-server)
				log_cmd ./runtests -f rapl/tests-server
				;;
			th)
				log_cmd ./runtests -c "th/th_test 1"
				log_cmd ./runtests -c "th/th_test 2"
				;;
			workload-xsave)
				log_cmd cd $test/build || die "fail to cd build dir"
				local available_workloads=$(./yogini 2>&1 | grep "Available workloads" | cut -d: -f 2 | xargs)
				log_cmd ../start_test.sh -1 100 $available_workloads
				;;
			topology-client)
				log_cmd ./runtests -f topology/tests-client
				;;
			topology-server)
				log_cmd ./runtests -f topology/tests-server
				;;
			*)
				die "unknown $test"
				;;
		esac
	fi
}
