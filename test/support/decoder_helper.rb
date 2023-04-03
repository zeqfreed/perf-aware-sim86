require 'tempfile'
require 'shellwords'
require_relative '../../intel_8086/decoder'

module DecoderHelper
  def assemble(asm)
    Tempfile.open(['test', '.asm']) do |input|
      input.write(asm)
      input.flush

      Tempfile.open(['test', '.bin']) do |output|
        `nasm #{input.path.shellescape} -o #{output.path.shellescape}`
        assert($? == 0, 'nasm exit code not 0')
        output.read.bytes
      end
    end
  end

  def reassemble(input_bytes)
    instructions = Intel8086::Decoder.new.decode_bytes(input_bytes)
    assemble("bits 16\n" + instructions.map(&:to_asm).join("\n"))
  end
end
