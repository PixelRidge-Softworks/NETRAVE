# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'base64'
require 'openssl'
require_relative 'logg_man'

# Utiltiies Module
module Utilities
  # Converts speed from Gbps to Mbps if necessary
  def convert_speed_to_mbps(speed)
    return nil unless speed.is_a?(String) && speed.match?(/\A\d+(gbps|mbps)\z/i)

    speed.end_with?('gbps') ? speed.to_i * 1000 : speed.to_i
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
    loggman = LoggMan.new
    loggman.log_error("Failed to encrypt data: #{e.message}")
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
      loggman = LoggMan.new
      loggman.log_error("Decrypted data is not valid ASCII: #{decrypted_data.inspect}")
      nil
    end
  rescue OpenSSL::Cipher::CipherError => e
    loggman = LoggMan.new
    loggman.log_error("Failed to decrypt data: #{e.message}")
    nil
  end

  def display_alert(message, severity) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    case severity
    when :info
      Curses.attron(Curses.color_pair(1)) # Blue color
    when :warning
      Curses.attron(Curses.color_pair(3)) # Yellow color
    when :error
      Curses.attron(Curses.color_pair(2)) # Red color
    end

    Curses.setpos(Curses.lines - 1, 0)
    Curses.addstr(message)
    Curses.refresh

    Thread.new do
      sleep(5) # Pause for 5 seconds

      # Clear the alert
      Curses.setpos(Curses.lines - 1, 0)
      Curses.clrtoeol
      Curses.refresh
    end

    Curses.attroff(Curses.color_pair(1)) if severity == :info
    Curses.attroff(Curses.color_pair(3)) if severity == :warning
    Curses.attroff(Curses.color_pair(2)) if severity == :error
  end
end
