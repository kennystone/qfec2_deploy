require 'rubygems'
require 'yaml'
require 'right_aws'

class EC2Util
  def initialize( access_key, secret_access_key )
    @ec2 = RightAws::Ec2.new( access_key, secret_access_key )
  end

  def start( image_id, key_name )
    inst = @ec2.launch_instances( image_id, :key_name=>key_name )
    return inst[0][:aws_instance_id]
  end

  def describe
    instances = @ec2.describe_instances
    tot_running = instances.select{|i| i[:aws_state]=='running' }.size
    puts tot_running.to_s + ' total instances running'
    instances.each do |instance|
      puts '-------------------------------------'
      inst_to_s( instance )
    end
  end

  def inst_to_s( instance )
    instance.each { |param, val| puts param.to_s + ': ' + val.to_s }
  end

  def describe_inst( inst_id )
    puts inst_to_s( get_instance( inst_id ) )
  end

  def running?( inst_id )
    instance = get_instance(inst_id )
    return instance[:aws_state].eql?( 'running' )
  end

  def stop( inst_id )
    @ec2.terminate_instances( inst_id )
  end

  def get_instance( inst_id )
    instances = @ec2.describe_instances
    instance = instances.select{|i| i[:aws_instance_id]==inst_id }[0]
    abort "could not find instance! inst_id: #{inst_id}" if instance.nil?
    return instance
  end

  def stop_all
    instances = @ec2.describe_instances
    instances.each { |inst| @ec2.terminate_instances( inst[:aws_instance_id] ) }
  end

  def get_dns( inst_id )
    instance = get_instance( inst_id )
    return instance[:dns_name]
  end
end

