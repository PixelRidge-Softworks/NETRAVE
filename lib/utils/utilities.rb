# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'base64'
require 'openssl'
require 'sudo'

# Utiltiies Module
module Utilities
  # Converts speed from Gbps to Mbps if necessary
  def convert_speed_to_mbps(speed)
    return nil unless speed.is_a?(String) && speed.downcase.match?(/\A\d+(gbps|mbps)\z/i)

    # Extract the numeric part and the unit from the speed
    numeric_speed, unit = speed.downcase.match(/(\d+)(gbps|mbps)/i).captures

    # Convert the numeric part to an integer
    numeric_speed = numeric_speed.to_i

    # If the unit is 'gbps', multiply the numeric part by 1000
    numeric_speed *= 1000 if unit == 'gbps'

    numeric_speed
  end

  # Converts an array of services into a hash
  def services_to_hash(services)
    services_hash = {}
    services.each { |service| services_hash[service] = true }
    services_hash
  end

  # Calculates total bandwidth from uplink and downlink speeds
  def calculate_total_bandwidth(uplink_speed, downlink_speed)
    uplink_speed + downlink_speed
  end

  def generate_key
    Base64.encode64(SecureRandom.bytes(32)).chomp
  end

  def encrypt_string_chacha20(data, key)
    return nil if data.nil? || key.nil?

    cipher = OpenSSL::Cipher.new('chacha20')
    cipher.encrypt
    cipher.key = Base64.decode64(key) # Decode the key from Base64
    encrypted_data = cipher.update(data) + cipher.final

    Base64.encode64(encrypted_data).chomp
  rescue OpenSSL::Cipher::CipherError => e
    @loggman.log_error("Failed to encrypt data: #{e.message}")
    nil
  end

  def decrypt_string_chacha20(encrypted_data, key) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return nil if encrypted_data.nil? || key.nil?

    cipher = OpenSSL::Cipher.new('chacha20')
    cipher.decrypt
    cipher.key = Base64.decode64(key) # Decode the key from Base64
    decrypted_data = cipher.update(Base64.decode64(encrypted_data)) + cipher.final

    # Check if the decrypted data is valid ASCII
    decrypted_data.force_encoding('UTF-8')
    if decrypted_data.valid_encoding?
      decrypted_data
    else
      @loggman.log_error("Decrypted data is not valid ASCII: #{decrypted_data.inspect}")
      nil
    end
  rescue OpenSSL::Cipher::CipherError => e
    @loggman.log_error("Failed to decrypt data: #{e.message}")
    nil
  end

  def ask_for_sudo(logger)
    @loggman = logger
    @loggman.log_info('Asking for sudo password... (This log entry will be removed)')
    Curses.addstr('Please enter your sudo password: ')
    # use the dynamic curses input gem in secure mode to collect the sudo password
    sudo_password = DCI.catch_input(false)
    @loggman.log_info('Sudo password received. (This log entry will be removed)')

    # Encrypt the sudo password right away and store it in an environment variable
    encrypted_sudo_password = encrypt_string_chacha20(sudo_password, @secret_key)
    ENV['SPW'] = encrypted_sudo_password

    # Clear the unencrypted sudo password from memory
    sudo_password.replace(' ' * sudo_password.length)
  end

  def test_sudo
    # Run a simple ls command with sudo privileges to test
    use_sudo('ls')

    true
  rescue Sudo::Wrapper::InvalidPassword
    false
  end

  def deescalate_sudo
    # Retrieve the encrypted sudo password from the environment variable
    encrypted_sudo_password = ENV['SPW']

    # Decrypt the sudo password
    sudo_password = decrypt_string_chacha20(encrypted_sudo_password, @secret_key)

    # Invalidate the user's cached credentials
    Sudo::Wrapper.run('sudo -k', password: sudo_password)

    # Clear the sudo password from memory
    sudo_password.replace(' ' * sudo_password.length)

    # Remove the encrypted sudo password from the environment variables
    ENV.delete('SPW')
  end

  def use_sudo(command)
    # Retrieve the encrypted sudo password from the environment variable
    encrypted_sudo_password = ENV['SPW']

    # Decrypt the sudo password
    sudo_password = decrypt_string_chacha20(encrypted_sudo_password, @secret_key)

    # Use the sudo password to run the command
    result = Sudo::Wrapper.run(command, password: sudo_password)

    # Clear the sudo password from memory
    sudo_password.replace(' ' * sudo_password.length)

    result
  end
end
