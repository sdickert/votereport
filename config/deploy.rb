# Use Git for deployment - git-specific options
default_run_options[:pty] = true
set :scm, "git"
set :repository,  "git@github.com:davetroy/votereport.git"
set :branch, "master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1

set :application, "votereport"
set :keep_releases, 3

role :app, "74.63.9.148"
role :daemons, "74.63.9.148"
role :db, "74.63.9.148", :primary=>true

set :use_sudo, false
set :user, application
set :deploy_to, "/home/#{application}"

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

namespace :daemons do
  desc "Start Daemons"
  task :start, :roles => :daemons do
    run "#{deploy_to}/current/script/daemons start"
  end

  desc "Stop Daemons"
  task :stop, :roles => :daemons do
    run "#{deploy_to}/current/script/daemons stop"
		run "sleep 5 && killall -9 ruby"
  end
end
