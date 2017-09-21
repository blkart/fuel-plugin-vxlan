# == Class: vxlan
#
# Full description of class vxlan here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'vxlan':
#    
#  }
#
# === Authors
#
# Author Name <samuel.bartel@orange.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class vxlan::controller (
  $vxlan_port = 4789,
){
include vxlan::params


  #update  ml2 configuration
  neutron_plugin_ml2 {
      'ml2/type_drivers': value => 'vxlan,flat,vlan,gre,local';
      'ml2/tenant_network_types': value => 'vxlan,flat,vlan,gre';
      'ovs/tunnel_types': value => 'vxlan,gre';
  }~> Service['neutron-server']

  file { 'dnsmasq-neutron.conf':
    ensure  => file,
    path    => '/etc/neutron/dnsmasq-neutron.conf',
    source  => 'puppet:///modules/vxlan/dnsmasq-neutron.conf',
    group   => 'root',
  }

  neutron_dhcp_agent_config {
      'DEFAULT/dnsmasq_config_file': value => '/etc/neutron/dnsmasq-neutron.conf';
  }~> Service['neutron-dhcp-agent']

  if $fuel_settings['deployment_mode'] == 'ha_compact' {
    service { 'neutron-dhcp-agent':
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => false,
      provider   => 'pacemaker',
    }
  }
  else {
    service { 'neutron-dhcp-agent':
      ensure => running,
      enable => true,
    }
  }
  
  class{'vxlan::neutron_services':}
  
  #add vxlan port to firewall
  class {'::firewall':}
  firewall { '334 notrack vxlan':
    port    => $vxlan_port,
    chain   => 'PREROUTING',
    table   => 'raw',
    proto   => 'udp',
    jump  => 'NOTRACK',
  }

  firewall { '335 accept vxlan port 4789':
    chain   => 'INPUT',
    table   => 'filter',
    port    => $vxlan_port,
    proto   => 'udp',
    action  => 'accept',
  }

  service { 'neutron-server':
    ensure  => running,
    enable  => true,
  }

}
