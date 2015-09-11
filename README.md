# Chef-Rails

Kitchen to setup an Ubuntu Server ready to roll with Nginx, PostgreSQL, Redis Server and Rails.

## Requirements

* Ubuntu 12.04+

## Usage

To cook with this kitchen you must follow four easy steps.

### 0. Create server deploy user (Optional)

We create our deploy user in deploy server adding our SSH keys:
```bash
sudo adduser deploy --disabled-password
# Add your SSH keys to deploy authorized_keys
sudo mkdir /home/deploy/.ssh/
sudo vim /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy -R /home/deploy/
```

### 1. Prepare your local working copy

```bash
git clone git://github.com/acidlabs/chef-rails.git chef
cd chef
bundle install
bundle exec librarian-chef install
```

### 2. Prepare the servers you want to configure

We need to copy chef-solo to any server we’re going to setup. For each server, execute

```bash
bundle exec knife solo prepare [user]@[host] -p [port]
```

where

* *user* is a user in the server with sudo and an authorized key.
* *host* is the ip or host of the server.
* *port* is the port in which ssh is listening on the server. Defaul port: 22.

### 3. Define the specs for each server

If you take a look at the *nodes* folder, you’re going to see files called [host].json, corresponding to the hosts or ips of the servers we previously prepared, plus a file called *localhost.json.example* which is, as its name suggests, and example.

The specs for each server needs to be defined in those files, and the structure is exactly the same as in the example.

For the very same reason, we’re going to exaplain the example for you to ride on your own pony later on.

```json
{
  // This is the list of the recipes that are going to be cooked.
  "run_list": [
    "recipe[apt]",
    "recipe[sudo]",
    "recipe[build-essential]",
    "recipe[ohai]",
    "recipe[runit]",
    "recipe[git]",
    "recipe[postgresql]",
    "recipe[postgresql::contrib]",
    "recipe[postgresql::server]",
    "recipe[nginx]",
    "recipe[nginx::apps]",
    "recipe[add_dir_structure]",
    "recipe[redis::install_from_package]",
    "recipe[redis::client]",
    "recipe[monit]",
    "recipe[monit::ssh]",
    "recipe[monit::nginx]",
    "recipe[monit::postgresql]",
    "recipe[monit::redis-server]",
    "recipe[rvm::user]",
    "recipe[chef-rails]"
  ],

  "automatic": {
    "ipaddress": "<host_ip>"
  },

  // You must define who’s going to be the user(s) you’re going to use for deploy.
  "authorization": {
    "sudo": {
      "groups"      : ["deploy","vagrant"],
      "users"       : ["deploy","vagrant"],
      "passwordless": true
    }
  },

  // You must define the password for postgres user.
  // Leave config block commented untill next cook.
  "postgresql": {
    "contrib": {
      "extensions": ["pg_stat_statements"]
    },  
    // "config": {
    //   "shared_buffers": "125MB", // 1/4 of total memory is recommended
    //   "shared_preload_libraries": "pg_stat_statements"
    // },
    "password"      : { 
      "postgres": "postgres4all"
    },  
    "pg_hba": [
      { "type": "local", "db": "all", "user": "postgres", "addr": null, "method": "ident" },
      {"type": "local", "db": "all", "user": "all", "addr": null, "method": "ident"},
      {"type": "host", "db": "all", "user": "all", "addr": "127.0.0.1/32", "method": "md5"},
      {"type": "host", "db": "all", "user": "all", "addr": "::1/128", "method": "md5"}
      // the following line allows connections from 136.243.51.136. Remove it and the comma on the line before
      //{"type": "host", "db": "all", "user": "all", "addr": "136.243.51.136/32", "method": "md5"}
    ],  
    "config": {
      // open for remote access:
      "listen_addresses": "*" 
      // else:
      //"listen_addresses": "localhost"
    }   
  },  

  "memcached": {
    "listen" : "127.0.0.1"
  },

  // You must specify the ubuntu distribution by it’s name to configure the proper version
  // of nginx, otherwise it’s going to fail.
  "nginx": {
    "user"          : "deploy",
    "distribution"  : "trusty",
    "components"    : ["main"],
    "worker_rlimit_nofile": 30000,

    // Here you should define all the apps you want nginx to serve for you in the server.
    //
    // specify inside apps like the following (for ssl-apps you need to put the certicficates into /etc/nginx/ssl manually):
    //
    "apps": {

      "inside-gamescom-2015": {
        "ssl" : true,
        // server_name == domain(s)
        "server_name": "gamescom-app.de www.gamescom-app.de",
        "ssl_certificate": "/etc/nginx/ssl/gamescom.de.combined.crt",
        "ssl_certificate_key": "/etc/nginx/ssl/gamescom.de.key"
      },

      "inside-baselworld-2016": {
        "ssl"     : false,
        "server_name": "baselworld-2016.insidetradeshow.com www.baselworld-2016.insidetradeshow.com bsw.ins1.de"
      }

    }
  },

  // The ruby version you’re going to use and rvm user.
  "rvm" : {
    "user_installs": [
      {
        "user"         : "deploy",
        "default_ruby" : "ruby-2.1.2"
      }
    ]
  },

  // Monit configuration. Sets email, check period and delay since monit service start
  "monit" : {
    "notify_email"     : "email@example.com",
    "poll_period"      : "60",
    "poll_start_delay" : "120"
  },

  // Finally, declare all the system packages required by the services and gems you’re using in your apps.
  // To give you an example: If you’re using paperclip, the native extensions compilation will fail unless you have installed imagemagick declared below.
  "chef-rails": {
    "packages": ["imagemagick", "nodejs-dev"]
  }
}
```

### 4. Happy cooking

We’re now ready to cook. For each server you want to setup, execute

```bash
bundle exec knife solo cook [user]@[host] -p [port]
```

following the same criteria we defined in step **2**.

Remember to clean your kitchen after cook

```bash
bundle exec knife solo clean [user]@[host] -p [port]
```

### 5. Create PostgreSQL user for deploy

```bash
sudo -u postgres psql
CREATE USER deploy SUPERUSER ENCRYPTED PASSWORD '<deploy_user_password>';
\q
```

### 6. Troubleshooting

Here are some issues with current cookbooks recipes, we have to solve them, so it's kind a TODO list:

#### Error executing action \`create\` on resource 'template[/etc/postgresql/9.3/main/postgresql.conf]'

```bash
ssh [user]@[host] -p [port]
sudo pg_createcluster 9.3 main --start
exit
bundle exec knife solo cook [user]@[host] -p [port]
```

#### After first succesfull cooking

Uncomment the following block in PostgreSQL configuration:

```json
    // "config": {
    //   "shared_buffers": "125MB", // 1/4 of total memory is recommended
    //   "shared_preload_libraries": "pg_stat_statements"
    // },
```

Then, cook again.