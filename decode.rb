#!/usr/bin/env ruby

require_relative 'intel_8086/decoder'

input_bytes = if ARGV[0]
                File.read(ARGV[0]).each_byte.to_a
              else
                $stdin.each_byte.to_a
              end

instructions = Intel8086::Decoder.new.decode_bytes(input_bytes)

puts 'bits 16'
instructions.each { puts _1.to_asm }
