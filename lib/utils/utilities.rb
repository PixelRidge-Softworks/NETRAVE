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
    if speed.end_with?('gbps')
      speed.to_i * 1000
    else
      speed.to_i
    end
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
    cipher = OpenSSL::Cipher.new('chacha20')
    cipher.encrypt
    cipher.key = Base64.decode64(key)  # Decode the key from Base64
    encrypted_data = cipher.update(data) + cipher.final

    loggman = LoggMan.new
    loggman.log_debug("Data to be encrypted: #{data}")
    loggman.log_debug("Key: #{key}")
    loggman.log_debug("Encrypted data: #{encrypted_data}")

    Base64.encode64(encrypted_data).chomp
  end

  def decrypt_string_chacha20(encrypted_data, key)
    return nil if encrypted_data.nil?

    cipher = OpenSSL::Cipher.new('chacha20')
    cipher.decrypt
    cipher.key = Base64.decode64(key)  # Decode the key from Base64
    cipher.update(Base64.decode64(encrypted_data)) + cipher.final
  end
end
