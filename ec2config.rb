require 'rubygems'
require 'yaml'

class EC2Config
  attr_reader :access_key, :secret_access_key, :key_name, :key_path, :build_loc

  ID_FILE = 'inst_ids.yml'

  def initialize( configfile )
    @config = YAML::load( File.open( configfile ) )
    @access_key = @config['ec2']['access_key']
    @secret_access_key = @config['ec2']['secret_access_key']
    @key_name = @config['ec2']['key_name']
    @key_path = @config['ec2']['key_path']
    @id_file = ID_FILE
    @build_steps = @config['build_steps']
    @at_steps = @config['acceptance_test_steps']
    @build_loc = '/mnt'
  end

  def repo_for( build )
    return @config['builds'][build]['repo']
  end

  def image_id_for( build )
    image = @config['builds'][build]['image']
    return @config['images'][image]
  end

  def save_inst_id( inst_id, build )
    ids = get_ids
    ids << make_yaml_entry( inst_id, build )
    f = File.new( @id_file, 'w' )
    f.puts( YAML::dump( ids ))
    f.close
  end

  def last_build
    get_ids[-1]['build']
  end

  def last_inst_id
    id = nil
    inst = get_ids[-1]
    id = inst['instance_id'] unless inst.nil?
    return id
  end

  def pop_inst_id
    ids = get_ids
    id = ids.pop
    f = File.new( @id_file, 'w' )
    f.puts( YAML::dump( ids ))
    f.close
    return id['instance_id']
  end

  def each_build_step
    @build_steps.each { |step| yield step }
  end

  def each_at_step
    @at_steps.each { |step| yield step }
  end

private
  def get_ids
    return [] if !File.exist?( @id_file )
    YAML::load( File.open( @id_file ))
  end

  def make_yaml_entry( inst_id, build )
    {'instance_id'=>inst_id, 'build'=>build}
  end

end
