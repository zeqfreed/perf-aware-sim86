require 'test/unit'
require_relative 'support/decoder_helper'

class DecoderJumpsTest < Test::Unit::TestCase
  include DecoderHelper

  ASM = <<~ASM
    bits 16

    test_label0:
    jnz test_label1
    jnz test_label0
    test_label1:
    jnz test_label0
    jnz test_label1

    label:
    je label
    jl label
    jle label
    jb label
    jbe label
    jp label
    jo label
    js label
    jne label
    jnl label
    jg label
    jnb label
    ja label
    jnp label
    jno label
    jns label
    loop label
    loopz label
    loopnz label
    jcxz label
  ASM

  def test_jumps
    assembled = assemble(ASM)
    reassembled = reassemble(assembled)
    assert(assembled == reassembled, 'Reassembled bytes do not match')
  end
end
