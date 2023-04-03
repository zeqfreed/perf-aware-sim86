# frozen_string_literal: true

require_relative '../intel_8086'

module Intel8086
  class Instruction
    REGS = {
      0 => %w[al ax],
      1 => %w[cl cx],
      2 => %w[dl dx],
      3 => %w[bl bx],
      4 => %w[ah sp],
      5 => %w[ch bp],
      6 => %w[dh si],
      7 => %w[bh di]
    }.freeze

    SRS = {
      0 => 'es',
      1 => 'cs',
      2 => 'ss',
      3 => 'ds',
    }

    def initialize(attrs)
      attrs.slice(:name, :s, :d, :w, :mod, :reg, :rm, :sr).each do |k, v|
        instance_variable_set("@#{k}", v)
      end

      raise 'Invalid SR' unless @sr.nil? || (@sr >= 0 && @sr < 4)

      @addr = word(attrs[:addr_low], attrs[:addr_high])
      @data = word(attrs[:data_low], attrs[:data_high])
      @disp = signed(attrs[:disp_low], attrs[:disp_high])
      @offset = signed(attrs[:ip_inc8])
    end

    def to_asm
      op1 = reg_operand
      op2 = mod_operand
      op1, op2 = op2, op1 unless @d == 1

      if op2
        "#{@name} #{op1}, #{op2}"
      else
        "#{@name} #{op1}"
      end
    end

    private

    def reg_operand
      if @reg
        reg_name(@reg, @w)
      elsif @data
        "#{@w == 1 ? 'word' : 'byte'} #{@data}"
      elsif @addr
        "[#{@addr}]"
      end
    end

    def mod_operand
      if @mod.nil?
        if @data
          @data
        elsif @addr
          "[#{@addr}]"
        elsif @offset
          offset_expr
        end
      elsif @mod == 3
        reg_name(@rm, @w)
      else
        if @rm == 6 && @mod == 0
          "[#{@disp || @addr}]"
        else
          "[#{addr_expr(@rm, @mod) + displacement}]"
        end
      end
    end

    def offset_expr
      offset = @offset + 2
      return '$+0' if offset == 0
      '$' + (offset > 0 ? "+#{offset}" : offset.to_s) + '+0'
    end

    def addr_expr(reg, mod)
      case reg
      when 0 then 'bx + si'
      when 1 then 'bx + di'
      when 2 then 'bp + si'
      when 3 then 'bp + di'
      when 4 then 'si'
      when 5 then 'di'
      when 6 then 'bp'
      when 7 then 'bx'
      end
    end

    def displacement
      return '' if @mod.nil? || @mod == 0 || @disp == 0
      @disp > 0 ? " + #{@disp}" : " - #{-1 * @disp}"
    end

    def word(low, high)
      return unless low || high
      ((high || 0) << 8) | low
    end

    def signed(low, high = nil)
      if low && high
        [low, high].pack('CC').unpack('s!<')[0]
      elsif low
        [low].pack('C').unpack('c')[0]
      end
    end

    def reg_name(reg, w)
      REGS[reg][w]
    end
  end
end
