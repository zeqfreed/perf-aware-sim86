#!/usr/bin/env ruby

require_relative 'instruction'

module Intel8086
  class Decoder
    def decode_bytes(input_bytes)
      input_index = 0
      result = []

      while input_index < input_bytes.length
        values = {}
        read_bytes = nil

        Intel8086::INSTRUCTIONS_TABLE.each do |key, bytes, implied|
          read_bytes = 0

          values = bytes.each.inject({}) do |memo, byte|
            next memo unless memo && byte.should_match?(memo)

            input_byte = input_bytes[input_index + read_bytes]
            next unless input_byte

            if matched = byte.match(input_byte)
              read_bytes += 1
              memo.merge!(matched)
            end
          end

          if values
            values[:name] = key
            values.merge!(implied) if implied
            break
          end
        end

        raise 'Invalid instruction stream' unless values

        result << Intel8086::Instruction.new(values)

        input_index += read_bytes
      end

      result
    end
  end
end
