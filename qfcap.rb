require 'yaml'
require 'ec2util'

ssh_options[:keys] = '/Users/kstone/.ec2/trial1.pem'
set :user, 'root'
set :use_sudo, false

@config = YAML::load( File.open('config/build.yml') )

task :launch do
  abort 'build arg required' if build.nil?
  inst_id = EC2Util.start( build, @config )
  puts '-----------------------------------------'
  puts 'instance id: ' + inst_id.to_s
  puts '-----------------------------------------'
  puts 'waiting for instance to start...'
  30.times do # == ten minutes
    if( EC2Util.running?( inst_id, @config ) )
      break
    else
      sleep( 20 )
    end
  end
  abort 'instance failed to start!' unless( EC2Util.running?( inst_id, @config ) )
  EC2Util.describe_inst( inst_id, @config )
  puts '-----------------------------------------'
end

task :describe_all do
  EC2Util.describe( @config )
end

task :stop_all do
  EC2Util.stop_all( @config )
  sleep(10)
  EC2Util.describe( @config )
end

task :checkout do
  abort 'inst_id and build args required' if( build.nil? or inst_id.nil? )
  role :libs, EC2Util.get_dns( inst_id, @config )
  capture "svn export #{@config['builds'][build]['repo']} /mnt/qf"
end

task :make do
  capture 'cd /mnt/qf && ./bootstrap'
  capture 'cd /mnt/qf && ./@configure'
  capture 'cd /mnt/qf && make'
end

task :run_at do
  capture 'cd /mnt/qf/test && ./runat 5001'
end
