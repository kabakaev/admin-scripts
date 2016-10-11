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
    '10.0.0.0/8',
    '192.168.0.0/16',
    '169.254.0.0/16',
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

print( 'Resulting set: \n' + '\n'.join(str(net) for net in routed_net_list) )

print( 'Openvpn ccd routing table: \n' )
for net in routed_net_list:
    print('route "' + str(net.with_netmask).replace('/','  ') + '"' )
