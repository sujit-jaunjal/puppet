#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# hiera_lookup: hiera lookup tool

def usage(error = '')
  msg = <<-end
hiera_lookup: hiera lookup tool

Usage:
     hiera_lookup [OPTIONS] KEY

Mandatory arguments:

  --fqdn=<FQDN>  Fully Qualified Domain Name
  KEY            Key to lookup in hiera

Optional arguments:

  -v                          Verbose mode
  --site=<SITE>               Wikimedia site (ex: eqiad)
  --roles=<ROLE>[,<ROLE>]...  Puppet role(s) class(es)
  -h, --help                  Display this help and exit

If SITE is not provided, it will be derived from the FQDN whenever possible.
For Wmflabs a FQDN should be: <hostname>.<project>.<site>.wmflabs

Examples:
  hiera_lookup --fqdn=mw1020.eqiad.wmnet --roles=mediawiki::appserver admin::groups
  hiera_lookup --fqdn=host.tools.eqiad.wmflabs classes


end
  msg << error
end

require 'hiera'
require 'hiera/backend'

# Determine the scope from the command line arguments
def determine_scope
  # Transform the CL arguments in a dictionary in the form "::option" => argument
  scope = Hash[ARGV.map { |kv| "::#{kv.sub('--', '')}".split('=') }]
  abort(usage "Error: --fqdn=FQDN is required.") unless scope['::fqdn']
  scope['::hostname'] = scope['::fqdn'][/^[^.]+/]
  if scope['::fqdn'].end_with?('.wmflabs') || scope['::fqdn'].end_with?('.labtest') || scope['::fqdn'].end_with?('.cloud')
    scope['::realm'] = 'labs'
  else
    scope['::realm'] = 'production'
  end

  # Detect labs project/site
  if scope['::realm'] == 'labs'
    bits = scope['::fqdn'].split('.')
    unless bits.length == 4
      Kernel.abort('labs FQDN must be <hostname>.<project>.<site>.(wmflabs|labtest|cloud)')
    end
    scope['::labsproject'] = bits[1]
    scope['::site'] = bits[2]
  end

  # Attempt at determining the site
  scope['::site'] ||= scope['::fqdn'].split('.')[-2]
  if scope['::site'] == 'wikimedia' || scope['::site'].nil?
    abort(usage "\nError: --site=SITE is required if the FQDN doesn't contain it")
  end

  # Transform roles in the form puppet expects
  if scope['::roles']
    scope['_roles'] = Hash[scope['::roles'].split(',').map { |role| [role.gsub('role::', ''), true] }]
    # Mimic the changes in the role() function
    scope['::_role'] = scope['_roles'].keys[0].gsub(/::/, '/')
    scope.delete('::roles')
  end
  scope
end

class Hiera
  module Backend
    class << self
      alias_method :old_datadir, :datadir
      def datadir(backend, scope)
        old_datadir(backend, scope).gsub(%r{^.*(?=/hieradata)}, DIR)
      end
    end
  end
end

abort(usage) if ARGV.include?('-h') || ARGV.include?('--help') || ARGV.empty?
if ARGV.include?('-v')
  verbose = true
  ARGV.delete('-v')
else
  verbose = false
end

DIR = ENV['PUPPETDIR'] || File.expand_path('../..', __FILE__)
$LOAD_PATH << File.join(DIR, 'modules/wmflib/lib')

scope = determine_scope

cfg = File.join(DIR, "modules/puppetmaster/files/#{scope['::realm']}.hiera.yaml")
unless File.exist?(cfg)
  Kernel.abort("Hiera cfg file not found for realm '#{scope['::realm']}': #{cfg}")
end

key = ARGV.pop
abort(usage "\nError: KEY is required") if key.match('^--')

puts "\e[33mpuppet now has this functionality built in.  try the following on the puppet master\e[0m"
puts " puppet lookup [--explain] --compile --node #{scope['::fqdn']} #{key}\n\n"
hiera = Hiera.new(:config => cfg)
if !verbose || scope.include?('::debug')
    Hiera.logger = "noop"
end

puts hiera.lookup(key, nil, scope, nil, :priority)
