#!/bin/sh

cd $(dirname $0)
export LTPROOT=${LTPROOT:-"$PWD"}
echo $LTPROOT | grep -q testscripts
if [ $? -eq 0 ]; then
	cd ..
	export LTPROOT=${PWD}
fi

export TMPDIR=/tmp/netpan-$$
mkdir -p $TMPDIR
CMDFILE=${TMPDIR}/network.tests
VERBOSE="no"

export PATH="${PATH}:${LTPROOT}/testcases/bin"

usage()
{
	echo "Usage: $0 OPTIONS"
	echo "  -6    IPv6 tests"
	echo "  -m    multicast tests"
	echo "  -n    NFS tests"
	echo "  -r    RPC tests"
	echo "  -s    SCTP tests"
	echo "  -t    TCP/IP command tests"
	echo "  -a    Application tests (HTTP, SSH, DNS)"
	echo "  -e    Interface stress tests"
	echo "  -b    Stress tests with malformed ICMP packets"
	echo "  -i    IPsec ICMP stress tests"
	echo "  -T    IPsec TCP stress tests"
	echo "  -U    IPsec UDP stress tests"
	echo "  -R    route stress tests"
	echo "  -M    multicast stress tests"
	echo "  -F    network features tests (TFO, vxlan, etc.)"
	echo "  -f x  where x is a runtest file"
	echo "  -V|v  verbose"
	echo "  -h    print this help"
}

TEST_CASES=

while getopts 6mnrstaebiTURMFf:Vvh OPTION
do
	case $OPTION in
	6) TEST_CASES="$TEST_CASES net.ipv6 net.ipv6_lib";;
	m) TEST_CASES="$TEST_CASES net.multicast" ;;
	n) TEST_CASES="$TEST_CASES net.nfs" ;;
	r) TEST_CASES="$TEST_CASES net.rpc" ;;
	s) TEST_CASES="$TEST_CASES net.sctp" ;;
	t) TEST_CASES="$TEST_CASES net.tcp_cmds" ;;
	a) TEST_CASES="$TEST_CASES net_stress.appl";;
	e) TEST_CASES="$TEST_CASES net_stress.interface";;
	b) TEST_CASES="$TEST_CASES net_stress.broken_ip";;
	i) TEST_CASES="$TEST_CASES net_stress.ipsec_icmp";;
	T) TEST_CASES="$TEST_CASES net_stress.ipsec_tcp";;
	U) TEST_CASES="$TEST_CASES net_stress.ipsec_udp";;
	R) TEST_CASES="$TEST_CASES net_stress.route";;
	M) TEST_CASES="$TEST_CASES net_stress.multicast";;
	F) TEST_CASES="$TEST_CASES net.features";;
	f) TEST_CASES=${OPTARG} ;;
	V|v) VERBOSE="yes";;
	h) usage; exit 0 ;;
	*) echo "Error: invalid option..."; usage; exit 1 ;;
	esac
done

if [ "$OPTIND" -eq 1 ]; then
	echo "Error: option is required"
	usage
	exit 1
fi

TST_TOTAL=1
TCID="network_settings"

. test_net.sh

# Reset variables.
# Don't break the tests which are using 'testcases/lib/cmdlib.sh'
export TCID=
export TST_LIB_LOADED=

rm -f $CMDFILE

for t in $TEST_CASES; do
	cat  ${LTPROOT}/runtest/$t >> $CMDFILE
done

cd $TMPDIR

if [ ${VERBOSE} = "yes" ]; then
	echo "Network parameters:"
	echo " - ${LHOST_IFACES} local interface (MAC address: ${LHOST_HWADDRS})"
	echo " - ${RHOST_IFACES} remote interface (MAC address: ${RHOST_HWADDRS})"

	cat $CMDFILE
	${LTPROOT}/ver_linux
	echo ""
	echo ${LTPROOT}/bin/ltp-pan -e -l /tmp/netpan.log -S -a ltpnet -n ltpnet -f $CMDFILE
fi

${LTPROOT}/bin/ltp-pan -e -l /tmp/netpan.log -S -a ltpnet -n ltpnet -f $CMDFILE

if [ $? -eq "0" ]; then
	echo ltp-pan reported PASS
else
	echo ltp-pan reported FAIL
fi
