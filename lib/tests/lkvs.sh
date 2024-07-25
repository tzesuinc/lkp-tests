#!/bin/bash

. $LKP_SRC/lib/debug.sh
. $LKP_SRC/lib/reproduce-log.sh
. $LKP_SRC/lib/env.sh

build_libipt()
{
    cd $BENCHMARK_ROOT/$testcase/libipt && cmake . && make install
}

build_lkvs()
{
    [[ -f $BENCHMARK_ROOT/$testcase/lkvs/BM/$test/Makefile ]] || return 0

    cd $BENCHMARK_ROOT/$testcase/lkvs/BM/$test || return

    make --keep-going || {
        echo "$test make fail"
        return 1
    }

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

runtests()
{
    cd $BENCHMARK_ROOT/$testcase/lkvs/BM || return

    if [[ $(type -t "fixup_${test//-/_}") = function ]]; then
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
                log_cmd cd workload-xsave
                log_cmd mkdir build
                log_cmd cd build
                log_cmd cmake ..
                log_cmd make
                available_workloads=$(./yogini 2>&1 | grep "Available workloads" | cut -d: -f 2 | xargs)
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
