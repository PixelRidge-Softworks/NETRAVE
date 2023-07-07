# frozen_string_literal: true

require 'English'
require 'securerandom'
require 'digest'
require 'base64'
require 'openssl'
require 'pty'
require 'expect'

# Utiltiies Module
module Utilities # rubocop:disable Metrics/ModuleLength
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

  def ask_for_sudo(logger) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @loggman = logger
    @loggman.log_info('Asking for sudo and explaining why...')
    lines = [
      'We require sudo permissions to complete certain steps.',
      'Granting a program sudo access is a significant decision.',
      'We treat your sudo password with the utmost care.',
      'We handle it "As a Bomb".',
      '',
      'As soon as we receive your sudo password, it is encrypted.',
      'The unencrypted password is then wiped from the system.',
      'This includes the sudo cache.',
      'When we need to use your sudo password, we decrypt it.',
      'We use it, and then immediately wipe it again.',
      'We only ever store the encrypted version of your password.',
      'We delete even that as soon as we finish the operations.',
      'However, even with these precautions, there is always a risk.',
      'If an attacker were to gain access to this program,',
      'they could potentially decrypt your password.',
      'Therefore, you should only enter your sudo password',
      'if you fully understand and accept these risks.',
      '',
      '',
      'Please enter your sudo password ONLY if you understand',
      'and accept the risks described above: '
    ]
    Curses.clear
    lines.each_with_index do |line, index|
      Curses.setpos(index, 0) # Move the cursor to the beginning of the next line
      Curses.addstr(line)
    end
    # use the dynamic curses input gem in secure mode to collect the sudo password
    sudo_password = DCI.catch_input(false)
    @loggman.log_info('Sudo password received. (This log entry will be removed)')
    @loggman.log_info("Entered sudo password: #{sudo_password}")

    # Generate a new secret key
    key = SecureRandom.random_bytes(32) # generates a random string of 32 bytes

    # encode the key for storage
    @secret_key = Base64.encode64(key)

    # Encrypt the sudo password right away and store it in an environment variable
    encrypted_sudo_password = encrypt_string_chacha20(sudo_password, @secret_key)
    @loggman.log_info("Encrypted sudo password: #{encrypted_sudo_password}")
    ENV['SPW'] = encrypted_sudo_password
    ENV['SDSECRET_KEY'] = @secret_key

    # Clear the unencrypted sudo password from memory
    sudo_password.replace(' ' * sudo_password.length)
  end

  def test_sudo
    # Run a simple ls command with sudo privileges to test
    use_sudo('ls')

    true
  rescue PTY::ChildExited
    false
  end

  def deescalate_sudo
    # Retrieve the encrypted sudo password from the environment variable
    encrypted_sudo_password = ENV['SPW']

    # Retrieve the secret key from the environment variable
    @secret_key = ENV['SDSECRET_KEY']

    # Decrypt the sudo password
    sudo_password = decrypt_string_chacha20(encrypted_sudo_password, @secret_key)

    # Invalidate the user's cached credentials
    PTY.spawn('sudo -S -k') do |r, w, _pid|
      w.sync = true
      r.expect(/password/) { w.puts sudo_password }
    end

    # Clear the sudo password from memory
    sudo_password.replace(' ' * sudo_password.length)

    # Remove the encrypted sudo password and the secret key from the environment variables
    ENV.delete('SPW')
    ENV.delete('SECRET_KEY')
  end

  def use_sudo(command) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @secret_key = ENV['SDSECRET_KEY']
    # Retrieve the encrypted sudo password from the environment variable
    encrypted_sudo_password = ENV['SPW']

    # Decrypt the sudo password
    sudo_password = decrypt_string_chacha20(encrypted_sudo_password, @secret_key)

    # this is only here for debugging
    @loggman.log_info("Decrypted sudo password: #{sudo_password}")

    # Log the command
    @loggman.log_info("Running command: #{command}")

    # Use the sudo password to run the command
    exit_status = nil
    begin
      Timeout.timeout(60) do
        PTY.spawn("sudo -S #{command} 2>&1") do |r, w, pid|
          w.sync = true
          r.expect(/password/) { w.puts sudo_password }
          while IO.select([r], nil, nil, 0.1)
            output = r.read_nonblock(1000)
            output.each_line { |line| @loggman.log_info("Command output: #{line.strip}") }
          end
          begin
            Process.wait(pid)
            exit_status = $CHILD_STATUS.exitstatus
          ensure
            # Clear the sudo password from memory
            sudo_password.replace(' ' * sudo_password.length)
          end
        end
      end
    rescue Timeout::Error
      @loggman.log_error("Command '#{command}' timed out")
    rescue Errno::EIO
      # This error is expected when the process has finished
    end

    if exit_status&.zero?
      @loggman.log_info("Command '#{command}' completed successfully")
    else
      @loggman.log_error("Command '#{command}' failed with exit status #{exit_status}")
    end

    exit_status
  end
end
