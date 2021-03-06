set_default(:unicorn_user) { user }
set_default(:unicorn_pid) { "#{current_path}/tmp/pids/unicorn.pid" }
set_default(:unicorn_sock) { "/tmp/unicorn.#{application}.sock" }
set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_log) { "#{shared_path}/log/unicorn.log" }
set_default(:unicorn_workers, 2)

namespace :unicorn do
  desc "Setup Unicorn initializer and app configuration"
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "unicorn.rb.erb", unicorn_config
    template "unicorn_init.erb", "/tmp/unicorn_init"
    run "chmod +x /tmp/unicorn_init"
    run "#{sudo} mv /tmp/unicorn_init /etc/init.d/unicorn_#{application}"
    run "#{sudo} update-rc.d -f unicorn_#{application} defaults"
  end
  after "deploy:setup", "unicorn:setup"

  %w[start stop restart upgrade].each do |command|
    desc "#{command} unicorn"
    task command, roles: :app do
      # run "cat #{unicorn_log} >> #{unicorn_log}.all"
      run "cat /dev/null > #{unicorn_log}"
      run "service unicorn_#{application} #{command}"
      run "cat #{unicorn_log}"
    end
  end
  after "deploy:start", "unicorn:start"
  after "deploy:stop", "unicorn:stop"
  after "deploy:restart", "unicorn:upgrade"

  desc "Force hard Unicorn restart"
  task :force_restart, roles: :app do
    run "cat /dev/null > #{unicorn_log}"
    run "service unicorn_#{application} stop"
    run "service unicorn_#{application} start"
    run "cat #{unicorn_log}"
  end
end
