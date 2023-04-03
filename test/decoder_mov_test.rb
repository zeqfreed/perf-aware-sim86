require 'test/unit'
require_relative 'support/decoder_helper'

class DecoderMovTest < Test::Unit::TestCase
  include DecoderHelper

  BASIC_MOV_ASM = <<~ASM
    bits 16

    mov cx, bx
    mov ch, ah
    mov dx, bx
    mov si, bx
    mov bx, di
    mov al, cl
    mov ch, ch
    mov bx, ax
    mov bx, si
    mov sp, di
    mov bp, ax
  ASM

  def test_basic_mov
    assembled = assemble(BASIC_MOV_ASM)
    reassembled = reassemble(assembled)
    assert(assembled == reassembled, 'Reassembled bytes do not match')
  end

  EXTRA_MOV_ASM = <<~ASM
    bits 16

    ; Register-to-register
    mov si, bx
    mov dh, al

    ; 8-bit immediate-to-register
    mov cl, 12
    mov ch, -12

    ; 16-bit immediate-to-register
    mov cx, 12
    mov cx, -12
    mov dx, 3948
    mov dx, -3948

    ; Source address calculation
    mov al, [bx + si]
    mov bx, [bp + di]
    mov dx, [bp]

    ; Source address calculation plus 8-bit displacement
    mov ah, [bx + si + 4]

    ; Source address calculation plus 16-bit displacement
    mov al, [bx + si + 4999]

    ; Dest address calculation
    mov [bx + di], cx
    mov [bp + si], cl
    mov [bp], ch
  ASM

  def test_extra_mov
    assembled = assemble(EXTRA_MOV_ASM)
    reassembled = reassemble(assembled)
    assert(assembled == reassembled, 'Reassembled bytes do not match')
  end

  CHALLENGE_MOV_ASM = <<~ASM
    bits 16

    ; Signed displacements
    mov ax, [bx + di - 37]
    mov [si - 300], cx
    mov dx, [bx - 32]

    ; Explicit sizes
    mov [bp + di], byte 7
    mov [di + 901], word 347

    ; Direct address
    mov bp, [5]
    mov bx, [3458]

    ; Memory-to-accumulator test
    mov ax, [2555]
    mov ax, [16]

    ; Accumulator-to-memory test
    mov [2554], ax
    mov [15], ax
  ASM

  def test_challenge_mov
    assembled = assemble(EXTRA_MOV_ASM)
    reassembled = reassemble(assembled)
    assert(assembled == reassembled, 'Reassembled bytes do not match')
  end
end
