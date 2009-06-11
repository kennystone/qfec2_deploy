require 'rubygems'
require 'yaml'
require 'right_aws'

class EC2Util
  def self.get_ec2( config )
    RightAws::Ec2.new(config['access_key'], config['secret_access_key'])
  end

  def self.start( build, config )
    ec2 = get_ec2( config )
    image_name = config['builds'][build]['image']
    image_id = config['images'][image_name]
    inst = ec2.launch_instances( image_id, :key_name=>config['ssh_key_name'] )
    return inst[0][:aws_instance_id]
  end

  def self.describe( config )
    instances = get_ec2( config ).describe_instances
    puts instances.size.to_s + ' total instances running'
    instances.each do |instance|
      puts '-------------------------------------'
      EC2Util.inst_to_s( instance )
    end
  end

  def self.inst_to_s( instance )
    instance.each { |param, val| puts param.to_s + ': ' + val.to_s }
  end

  def self.describe_inst( inst_id, config )
    puts EC2Util.inst_to_s( EC2Util.get_instance( inst_id, config ) )
  end

  def self.running?( inst_id, config )
    instance = EC2Util.get_instance(inst_id, config )
    return instance[:aws_state].eql?( 'running' )
  end

  def self.stop( inst_id, config )
    get_ec2( config ).terminate_instances( inst_id )
  end

  def self.get_instance( inst_id, config )
    instances = get_ec2( config ).describe_instances
    return instances.select{|i| i[:aws_instance_id]==inst_id }[0]
  end

  def self.stop_all( config )
    ec2 = get_ec2( config )
    instances = ec2.describe_instances
    instances.each { |inst| ec2.terminate_instances( inst[:aws_instance_id] ) }
  end

  def self.get_dns( inst_id, config )
    instance = get_instance( inst_id, config )
    raise 'could not find instance!' if instance.nil?
    return instance[:dns_name]
  end
end

