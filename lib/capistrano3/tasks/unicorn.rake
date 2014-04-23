namespace :load do
  task :defaults do
    set :unicorn_command, 'bundle exec unicorn'
    set :unicorn_pid, -> { current_path.join('tmp', 'pids', 'unicorn.pid') }
    set :unicorn_config_path, -> { current_path.join('config', 'unicorn', "#{fetch(:rails_env)}.rb") }
    set :unicorn_roles, -> { :app }
    set :unicorn_options, ''
    set :unicorn_rack_env, 'none'
  end
end

namespace :unicorn do
  desc "Start Unicorn"
  task :start do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        if test("[ -e #{fetch(:unicorn_pid)} ] && kill -0 #{pid}")
          info "unicorn is running..."
        else
          with rails_env: fetch(:rails_env) do
            execute fetch(:unicorn_command), '-c', fetch(:unicorn_config_path), '-E', fetch(:unicorn_rack_env), '-D', fetch(:unicorn_options)
          end
        end
      end
    end
  end

  desc "Stop Unicorn (QUIT)"
  task :stop do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        if test("[ -e #{fetch(:unicorn_pid)} ]")
          if test("kill -0 #{pid}")
            info "stopping unicorn..."
            execute :kill, "-s QUIT", pid
          else
            info "cleaning up dead unicorn pid..."
            execute :rm, fetch(:unicorn_pid)
          end
        else
          info "unicorn is not running..."
        end
      end
    end
  end

  desc "Reload Unicorn (HUP); use this when preload_app: false"
  task :reload do
    invoke "unicorn:start"
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "reloading..."
        execute :kill, "-s HUP", pid
      end
    end
  end

  desc "Restart Unicorn (USR2 + QUIT); use this when preload_app: true"
  task :restart do
    invoke "unicorn:start"
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "unicorn restarting..."
        execute :kill, "-s USR2", pid
      end
    end
  end

  desc "Add a worker (TTIN)"
  task :add_worker do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "adding worker"
        execute :kill, "-s TTIN", pid
      end
    end
  end

  desc "Remove a worker (TTOU)"
  task :remove_worker do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "removing worker"
        execute :kill, "-s TTOU", pid
      end
    end
  end
end

def pid
  "`cat #{fetch(:unicorn_pid)}`"
end

def pid_oldbin
  "`cat #{fetch(:unicorn_pid)}.oldbin`"
end
