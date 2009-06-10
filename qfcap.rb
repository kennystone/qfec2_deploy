role :libs, 'ec2-174-129-139-145.compute-1.amazonaws.com'
ssh_options[:keys] = '/Users/kstone/.ec2/trial1.pem'
set :user, 'root'
set :use_sudo, false

task :checkout do
  capture 'svn export https://svn.sourceforge.net/svnroot/quickfix/trunk/quickfix /mnt/qf'
end

task :make do
  capture 'cd /mnt/qf && ./bootstrap'
  capture 'cd /mnt/qf && ./configure'
  capture 'cd /mnt/qf && make'
end

task :run_at do
  capture 'cd /mnt/qf/test && ./runat 5001'
end
