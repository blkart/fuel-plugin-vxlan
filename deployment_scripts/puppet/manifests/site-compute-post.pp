$fuel_settings = parseyaml($astute_settings_yaml)
$roles         = node_roles($::fuel_settings['nodes'], $::fuel_settings['uid'])
# for hyper-converged: there's nothing to do for vxlan
# when compute and controller role in the same node.
if (! member($roles, 'controller') and ! member($roles, 'primary-controller')){
  class {'vxlan::compute':}
} else {
  notice('Compute role with primary-controller/controller role in the same node, nothing to do.')
}
