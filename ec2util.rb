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
    i = ec2.launch_instances( image_id, :key_name=>config['ssh_key_name'], :user_data=>'build' )
    return i[0][:aws_instance_id]
  end

  def self.describe( config )
    instances = get_ec2( config ).describe_instances
    puts instances.size.to_s + ' total instances running'
    instances.each do |instance|
      puts '-------------------------------------'
      instance.each { |param, val| puts param.to_s + ': ' + val.to_s }
    end
  end

  def self.running?( inst_id, config )
    running = false
    instances = get_ec2( config ).describe_instances
    instances.each do |i| 
      running=true if( i[:aws_state].eql?( 'running' ) and i[:aws_instance_id].eql?( inst_id ))
    end
    return running
  end

  def self.stop( inst_id, config )
    get_ec2( config ).terminate_instances( inst_id )
  end

  def self.stop_all( config )
    ec2 = get_ec2( config )
    instances = ec2.describe_instances
    instances.each { |inst| ec2.terminate_instances( inst[:aws_instance_id] ) }
  end
end
