require 'rubygems'
require 'yaml'

class EC2Config
  attr_reader :access_key, :secret_access_key, :key_name, :key_path

  def initialize( configfile )
    @config = YAML::load( File.open( configfile ) )
    @access_key = @config['access_key']
    @secret_access_key = @config['secret_access_key']
    @key_name = @config['key_name']
    @key_path = @config['key_path']
  end

  def repo_for( build )
    return @config['builds'][build]['repo']
  end

  def image_id_for( build )
    image = @config['builds'][build]['image']
    return @config['images'][image]
  end

  def save_inst_id( inst_id )
    f = File.new( 'inst_ids.txt', 'a' )
    f.puts( inst_id )
    f.close
  end

  def last_inst_id
    get_ids[-1]
  end

  def pop_inst_id
    ids = get_ids
    id = ids.pop
    f = File.new( 'inst_ids.txt', 'w' )
    ids.each { |i| f.puts( i ) }
    f.close
    return id
  end

private
  def get_ids
    ids = []
    f = File.new( 'inst_ids.txt', 'r' )
    f.each_line { |line| ids << line.chomp }
    f.close
    return ids
  end
end
