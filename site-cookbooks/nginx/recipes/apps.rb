def prepare_attributes(app_name, app_attributes)

  ssl = app_attributes[:ssl]
  ssl_certificate = app_attributes[:ssl_certificate]
  ssl_certificate_key = app_attributes[:ssl_certificate_key]

  app_name_simple = app_name.split('-')[1]

  atts = {}
  atts[:listen] = ssl ? [443, 80] : [80]
  atts[:public_path] = "/home/deploy/#{app_name}/current/public"
  atts[:locations] = [
    {
      path: "@#{app_name_simple}",
      directives: [
        "proxy_set_header X-Forwarded-Proto $scheme;",
        "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
        "proxy_set_header X-Real-IP $remote_addr;",
        "proxy_set_header Host $host;",
        "proxy_redirect off;",
        "proxy_http_version 1.1;",
        "proxy_set_header Connection '';",
        "proxy_pass  http://#{app_name_simple};"
      ]
    },
    {
      path: "~ ^/(assets|fonts|system)/|favicon.ico|robots.txt",
      directives: [
        "gzip_static on;",
        "expires max;",
        "add_header Cache-Control public;"
      ]
    },
    {
      path: "~ ^/(files|cgi-bin)/",
      directives: [
        "deny all;"
      ]
    }
  ]
  atts[:upstreams] = [
    {
      name: app_name_simple,
      servers: [
        "unix:/home/deploy/#{app_name}/shared/tmp/sockets/#{app_name}.sock max_fails=3 fail_timeout=1s"
      ]
    }
  ]
  atts[:try_files] = ["$uri", "@#{app_name_simple}"]
  atts[:custom_directives] = ssl ? [
          "ssl on;",
          "ssl_certificate #{ssl_certificate};",
          "ssl_certificate_key #{ssl_certificate_key};",
          "ssl_session_cache shared:SSL:10m;",
          "ssl_protocols TLSv1.2 TLSv1.1 TLSv1;",
          "ssl_ciphers 'HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES';",
          "ssl_prefer_server_ciphers on;",
          "ssl_session_timeout 10m;"
        ] : nil

  #atts[:upstream_keepalive] = ""
  #atts[:client_max_body_size] = ""
  #atts[:keepalive_timeout] = ""
  #atts[:action] = ""

  atts
end

node[:nginx][:apps].each do |app_name, app_attributes|
  prepared_attributes = prepare_attributes(app_name, app_attributes)

  nginx_app app_name do
    server_name           app_attributes[:server_name]
    upstream_keepalive    app_attributes[:upstream_keepalive]
    client_max_body_size  app_attributes[:client_max_body_size]
    keepalive_timeout     app_attributes[:keepalive_timeout]
    action                app_attributes[:action]

    listen                prepared_attributes[:listen]
    public_path           prepared_attributes[:public_path]
    locations             prepared_attributes[:locations]
    upstreams             prepared_attributes[:upstreams]
    try_files             prepared_attributes[:try_files]
    custom_directives     prepared_attributes[:custom_directives]
  end
end
