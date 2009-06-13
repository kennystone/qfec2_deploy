require 'yaml'
require 'ec2util'
require 'ec2config'

@config = EC2Config.new( 'config/build.yml')
@ec2 = EC2Util.new( @config.access_key, @config.secret_access_key )

set :user, 'root'
set :use_sudo, false
ssh_options[:keys] = @config.key_path
role :libs, @ec2.get_dns( @config.last_inst_id )

desc 'launches a new instance (req arg: build)'
task :launch do
  inst_id = @ec2.start( @config.image_id_for( build ), @config.key_name )
  @config.save_inst_id( inst_id )
  puts '-----------------------------------------'
  puts 'instance id: ' + inst_id.to_s
  puts '-----------------------------------------'
  30.times do # == ten minutes
    break if( @ec2.running?( inst_id ) )
    puts 'waiting for instance to start...'
    sleep( 20 )
  end
  abort 'instance failed to start!' unless( @ec2.running?( inst_id ) )
  @ec2.describe_inst( inst_id )
  puts '-----------------------------------------'
end

desc 'describes all running instances'
task :describe do
  @ec2.describe
end

desc 'stops instance'
task :stop do
  @ec2.stop( @config.pop_inst_id )
  sleep(10)
  @ec2.describe
end

desc 'stops all instances'
task :stop_all do
  @ec2.stop_all
  sleep(10)
  @ec2.describe
  service 'rm -rf inst_ids.txt'
end

desc 'checks out repo on instance (req args: build)'
task :checkout do
  qfdir = "qf_#{Time.now.strftime('%Y%m%d-%H%M%S')}_#{rand(999999999)}"
  system "git clone #{@config.repo_for( build )} #{qfdir}"
  puts 'tar and upload repo to instance'
  puts 'this may take a few minutes'
  system "tar -cjf #{qfdir}.zip #{qfdir}"
  upload( "#{qfdir}.zip", '/mnt/qf.zip', :via=>:scp ) 
  capture "cd /mnt && tar -xjf qf.zip"
  capture "mv /mnt/#{qfdir}/quickfix /mnt/qf"
  system "rm -rf #{qfdir}*"
end

desc 'builds repo on instance'
task :make do
  capture 'cd /mnt/qf && ./bootstrap'
  capture 'cd /mnt/qf && ./configure'
  capture 'cd /mnt/qf && make'
end

desc 'runs acceptance tests'
task :run_at do
  tr = capture 'cd /mnt/qf/test && ./runat 5001'
  puts '-----------------------------------------'
  puts 'test results'
  puts '-----------------------------------------'
  puts tr
  puts '-----------------------------------------'
end

