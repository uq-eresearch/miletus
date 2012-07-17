class Rails::Application::Configuration

  def database_configuration
    # There is no config file, so manufacture one
    config = {
      'test' => 'sqlite3://localhost/:memory:',
      'development' => ENV['DATABASE_URL'],
      'production' => ENV['DATABASE_URL']
    }
    config.each_key do |key|
      # Based on how Heroku do it: https://gist.github.com/1059446
      begin
        uri = URI.parse(config[key])

        # Values
        adapter = uri.scheme
        adapter = "postgresql" if adapter == "postgres"
        database = (uri.path || "").split("/")[1]
        username = uri.user
        password = uri.password
        host = uri.host
        port = uri.port

        config[key] = {
          'adapter' => adapter,
          'database' => database,
          'username' => username,
          'password' => password,
          'host' => host,
          'port' => port
        }
      rescue URI::InvalidURIError
        config.delete(key)
      end
    end

    config
  end

end