require 'yaml'
require 'ec2util'
require 'ec2config'

@config = EC2Config.new( 'config/build.yml')
@ec2 = EC2Util.new( @config.access_key, @config.secret_access_key )
@build = build if exists?( :build )
@inst = @config.last_inst_id

set :user, 'root'
set :use_sudo, false
ssh_options[:keys] = @config.key_path

desc 'launch, checkout, make, run_at, stop (req: build)'
task :do_build do
  launch
  @inst = @config.last_inst_id
  checkout
  make
  run_ut
  run_at
  stop
end

desc 'launches a new instance (req arg: build)'
task :launch do
  inst_id = @ec2.start( @config.image_id_for( @build ), @config.key_name )
  @config.save_inst_id( inst_id, @build )
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
  @ec2.describe
end

desc 'stops all instances'
task :stop_all do
  @ec2.stop_all
  @ec2.describe
  system 'rm -rf inst_ids.yml'
end

desc 'checks out repo on instance'
task :checkout do
  role :libs, @ec2.get_dns( @inst )
  builddir = "build_#{Time.now.strftime('%Y%m%d-%H%M%S')}_#{rand(999999999)}"
  system "git clone #{@config.repo_for( @config.last_build )} #{builddir}"
  puts 'tar and upload repo to instance'
  puts 'this may take a few minutes'
  system "tar -cjf #{builddir}.zip #{builddir}"
  upload( "#{builddir}.zip", "#{@config.build_loc}/build.zip", :via=>:scp ) 
  capture "cd #{@config.build_loc} && tar -xjf build.zip"
  capture "mv #{@config.build_loc}/#{builddir}/ #{@config.build_loc}/build"
  system "rm -rf #{builddir}*"
end

desc 'builds repo on instance'
task :make do
  role :libs, @ec2.get_dns( @inst )
  @config.each_build_step do |step|
    capture "cd #{@config.build_loc}/build && #{step}"
  end
end

desc 'runs acceptance tests'
task :run_at do
  role :libs, @ec2.get_dns( @inst )
  tr = ''
  @config.each_at_step do |step|
    tr += capture "cd #{@config.build_loc}/build && #{step}"
  end
  puts '-----------------------------------------'
  puts 'test results'
  puts '-----------------------------------------'
  puts tr
  puts '-----------------------------------------'
end

desc 'runs unit tests'
task :run_ut do
  role :libs, @ec2.get_dns( @inst )
  tr = ''
  @config.each_ut_step do |step|
    tr += capture "cd #{@config.build_loc}/build && #{step}"
  end
  puts '-----------------------------------------'
  puts 'test results'
  puts '-----------------------------------------'
  puts tr
  puts '-----------------------------------------'
end

