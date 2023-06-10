# frozen_string_literal: true

require 'securerandom'
require 'digest'
require 'base64'
require 'openssl'

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

  def encrypt_string_chacha20(string, key)
    cipher = OpenSSL::Cipher.new('chacha20')
    cipher.encrypt
    cipher.key = Base64.decode64(key)
    encrypted = cipher.update(string) + cipher.final
    Base64.encode64(encrypted).chomp
  end

  def decrypt_string_chacha20(encrypted_string, key)
    decipher = OpenSSL::Cipher.new('chacha20')
    decipher.decrypt
    decipher.key = Base64.decode64(key)
    decrypted = Base64.decode64(encrypted_string)
    decipher.update(decrypted) + decipher.final
  end

  # Encrypts a given data object using Blowfish and returns the encrypted string
  def encrypt_data_blowfish(data, key)
    plain_text = YAML.dump(data)
    encrypt_string_blowfish(plain_text, key)
  end

  # Decrypts a given encrypted string using Blowfish and returns the original data object
  def decrypt_data_blowfish(encrypted_text, key)
    plain_text = decrypt_string_blowfish(encrypted_text, key)
    YAML.load(plain_text)
  end
end
