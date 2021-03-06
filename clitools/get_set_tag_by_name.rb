#!/usr/bin/env ruby
#
# It expects that a yaml file exists at ~/.fog and contains
#
# :default:
#         :aws_access_key_id:     XXXXXXXXXXXXXXXXXXXXXX
#         :aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#
require 'rubygems'
require 'fog'
require 'json'
require 'optparse'
require 'yaml'

filter = {}
tagset = {}
options = {}

usage = "Example: set_tag_by_name.rb --name NAME --key KEY --value VALUE"

optparse = OptionParser.new do|opts|
  opts.banner = usage

  opts.on( '-V', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:region] = 'us-east-1'
  opts.on( '-r', '--region REGION', 'AWS Region (us-east-1)' ) do|region|
    options[:region] = region
  end

  opts.on( '-n', '--name NAME', 'Instance Name' ) do|name|
    filter[:key] = 'Name'
    filter[:value] = name
  end

  opts.on( '-k', '--key KEY', 'Tag Key' ) do|tag_key|
    tagset[:key] = tag_key
  end

  opts.on( '-v', '--value VALUE', 'Tag Value' ) do|tag_value|
    tagset[:value] = tag_value
  end

end

optparse.parse!

# new compute provider from AWS
compute = Fog::Compute.new(:provider => 'AWS', :region => options[:region])

# print resource id's by the hash {key => value}
compute.describe_tags(filter).body['tagSet'].each do|tag|
  instance_facts = compute.describe_instances('instance-id' => tag['resourceId']).body['reservationSet'][0]['instancesSet'][0]
  if options[:verbose]
    instance_facts.each do|fact|
      puts fact.to_yaml
    end
  else
    puts instance_facts['tagSet'].to_yaml
  end
  if tagset[:key] && tagset[:value] then
    compute.tags.create(:resource_id => tag['resourceId'], :key => tagset[:key], :value => tagset[:value])
  end
end


