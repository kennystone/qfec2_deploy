require 'yaml'
require 'ec2util'


ssh_options[:keys] = '/Users/kstone/.ec2/trial1.pem'
set :user, 'root'
set :use_sudo, false

@config = YAML::load( File.open('config/build.yml') )

desc 'launches a new instance (req arg: build)'
task :launch do
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
  ENV['INST_ID'] = inst_id
  EC2Util.describe_inst( inst_id, @config )
  puts '-----------------------------------------'
end

desc 'describes all running instances'
task :describe do
  EC2Util.describe( @config )
end

desc 'stops instance (req arg: inst_id)'
task :stop do
  EC2Util.stop( inst_id, @config )
  sleep(10)
  EC2Util.describe( @config )
end

desc 'stops all instances'
task :stop_all do
  EC2Util.stop_all( @config )
  sleep(10)
  EC2Util.describe( @config )
end

desc 'checks out repo on instance (req args: build, inst_id)'
task :checkout do
  role :libs, EC2Util.get_dns( inst_id, @config )
  qfdir = "qf_#{Time.now.strftime('%Y%m%d-%H%M%S')}_#{rand(999999999)}"
  system "git clone #{@config['builds'][build]['repo']} #{qfdir}"
  puts 'tar and upload repo to instance'
  system "tar -cjf #{qfdir}.zip #{qfdir}"
  upload( "#{qfdir}.zip", '/mnt/qf.zip', :via=>:scp ) 
  capture "cd /mnt && tar -xjf qf.zip"
  capture "mv /mnt/#{qfdir}/quickfix /mnt/qf"
  system "rm -rf #{qfdir}*"
end

desc 'builds repo on instance (req arg: inst_id)'
task :make do
  role :libs, EC2Util.get_dns( inst_id, @config )
  capture 'cd /mnt/qf && ./bootstrap'
  capture 'cd /mnt/qf && ./configure'
  capture 'cd /mnt/qf && make'
end

desc 'runs acceptance tests (req args: build, inst_id)'
task :run_at do
  role :libs, EC2Util.get_dns( inst_id, @config )
  tr = capture 'cd /mnt/qf/test && ./runat 5001'
  puts '-----------------------------------------'
  puts 'test results'
  puts '-----------------------------------------'
  puts tr
  puts '-----------------------------------------'
end

