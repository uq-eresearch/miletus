# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

def get_random_bytes(n = 256)
  begin
    SecureRandom.random_bytes(n).bytes
  rescue NotImplemented
    get_random_bytes_online(n)
  end
end

def get_random_bytes_online(n)
  # Get some random bytes from Random.org
  require 'random/online'
  generator = RealRand::RandomOrg.new
  begin
    # If testing, allow a net connection just this once
    WebMock.allow_net_connect! if defined? WebMock
    # Get the random bytes
    return generator.randbyte(number = n)
  ensure
    # If testing, disallow net connections again
    WebMock.disable_net_connect! if defined? WebMock
  end
end

# As this is an open source app, we need to generate this on first run.
secret_filename = File.join(Rails.root, '.secret_token')
unless File.exists?(secret_filename)
  bytes = get_random_bytes
  # Write bytes to file as characters
  File.open(secret_filename, 'wb') { |f| f.write(bytes.map{|b| b.chr}.join) }
end

# Read secret
Miletus::Application.config.secret_token = \
  File.open(secret_filename, 'rb') { |f| f.read() }
