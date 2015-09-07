directory "/home/#{node[:nginx][:user]}/git-repos" do
  owner node[:nginx][:user]
  group node[:nginx][:user]
  mode "0755"
  action :create
end

node[:nginx][:apps].each do |app_name, app_attributes|

  execute "creating git repo for #{app_name}" do
    cwd "/home/#{node[:nginx][:user]}/git-repos/"
    command "git init --bare #{app_name}.git"
  end

  path = "/home/#{node[:nginx][:user]}/"
  [app_name, "shared", "config"].each do |child|
    path = "#{path}/#{child}"
    directory path do
      owner node[:nginx][:user]
      group node[:nginx][:user]
      mode "0755"
      action :create
    end
  end

  template "#{path}/secrets.yml" do
    source 'secrets.erb'
    owner node[:nginx][:user]
    group node[:nginx][:user]
    mode '0755'
  end

  template "#{path}/database.yml" do
    source 'database.erb'
    owner node[:nginx][:user]
    group node[:nginx][:user]
    mode '0755'
    variables short_db_name: app_name.sub("inside-", "")
  end

end


