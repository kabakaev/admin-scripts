#!/usr/bin/python3

# Script subtracts one list of sub/networks from another.
# It may be used to configure openvpn ccd client rouring table,
# wneh it is required to route all traffic via tunnel, except some networks.

quiet = True

# list of (bigger) networks that should be routed
routed_str_list = [
    '0.0.0.0/0',
]

# list of (smaller) subnetworks that should not be routed via the tunnel
excluded_str_list = [
    # taken from https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
    #Address Block 	Name 	RFC 	Allocation Date 	Termination Date 	Source 	Destination 	Forwardable 	Globally Reachable 	Reserved-by-Protocol 
    '0.0.0.0/8', #	"This host on this network"	[RFC1122], Section 3.2.1.3	1981-09	N/A	True	False	False	False	True
    '10.0.0.0/8', #	Private-Use	[RFC1918]	1996-02	N/A	True	True	True	False	False
    '100.64.0.0/10', #	Shared Address Space	[RFC6598]	2012-04	N/A	True	True	True	False	False
    '127.0.0.0/8', #	Loopback	[RFC1122], Section 3.2.1.3	1981-09	N/A	False [1]	False [1]	False [1]	False [1]	True
    '169.254.0.0/16', #	Link Local	[RFC3927]	2005-05	N/A	True	True	False	False	True
    '172.16.0.0/12', #	Private-Use	[RFC1918]	1996-02	N/A	True	True	True	False	False
    '192.0.0.0/24', # [2]	IETF Protocol Assignments	[RFC6890], Section 2.1	2010-01	N/A	False	False	False	False	False
    '192.0.0.0/29', #	IPv4 Service Continuity Prefix	[RFC7335]	2011-06	N/A	True	True	True	False	False
    '192.0.0.8/32', #	IPv4 dummy address	[RFC7600]	2015-03	N/A	True	False	False	False	False
    '192.0.0.9/32', #	Port Control Protocol Anycast	[RFC7723]	2015-10	N/A	True	True	True	True	False
    '192.0.0.10/32', #	Traversal Using Relays around NAT Anycast	[RFC8155]	2017-02	N/A	True	True	True	True	False
    '192.0.0.170/32', #, 192.0.0.171/32	NAT64/DNS64 Discovery	[RFC7050], Section 2.2	2013-02	N/A	False	False	False	False	True
    '192.0.2.0/24', #	Documentation (TEST-NET-1)	[RFC5737]	2010-01	N/A	False	False	False	False	False
    '192.31.196.0/24', #	AS112-v4	[RFC7535]	2014-12	N/A	True	True	True	True	False
    '192.52.193.0/24', #	AMT	[RFC7450]	2014-12	N/A	True	True	True	True	False
    '192.88.99.0/24', #	Deprecated (6to4 Relay Anycast)	[RFC7526]	2001-06	2015-03					
    '192.168.0.0/16', #	Private-Use	[RFC1918]	1996-02	N/A	True	True	True	False	False
    '192.175.48.0/24', #	Direct Delegation AS112 Service	[RFC7534]	1996-01	N/A	True	True	True	True	False
    '198.18.0.0/15', #	Benchmarking	[RFC2544]	1999-03	N/A	True	True	True	False	False
    '198.51.100.0/24', #	Documentation (TEST-NET-2)	[RFC5737]	2010-01	N/A	False	False	False	False	False
    '203.0.113.0/24', #	Documentation (TEST-NET-3)	[RFC5737]	2010-01	N/A	False	False	False	False	False
    '240.0.0.0/4', #	Reserved	[RFC1112], Section 4	1989-08	N/A	False	False	False	False	True
    '255.255.255.255/32', #	Limited Broadcast	[RFC8190] [RFC919], Section 7	1984-10	N/A	False	True	False	False	True
]

import ipaddress

# convert string to network
routed_net_list =   [ ipaddress.ip_network(net) for net in routed_str_list ]
excluded_net_list = [ ipaddress.ip_network(net) for net in excluded_str_list ]

def log(string):
    if not quiet: print(string)

for excluded_net in excluded_net_list:
    log('Excluding %s...' % excluded_net)
    temp_net_list = list(routed_net_list)
    routed_net_list = []
    while temp_net_list:
        temp_net = temp_net_list.pop()
        excluded_net_list = []
        try:
            excluded_net_list = list(temp_net.address_exclude(excluded_net))
            log('net %s - subnet %s =' % (temp_net, excluded_net))
            log('    ' + ','.join( str(net) for net in excluded_net_list))
        except ValueError:
            log('Network %s is not a part of net %s' % (excluded_net, temp_net))
            excluded_net_list = [temp_net]
            pass
        routed_net_list.extend(excluded_net_list)
        log('routed_net_list: ' + ','.join(str(net) for net in routed_net_list))

print( 'Resulting set:\n' + '\n'.join(str(net) for net in routed_net_list) )

print( 'Openvpn ccd routing table:\n' )
for net in routed_net_list:
    print('push "route ' + str(net.with_netmask).replace('/','  ') + '"' )
