# frozen_string_literal: true

module Intel8086
  module IntegerBitMatcherMethods
    refine Integer do
      def bits(name)
        BitMatcher.new(self, name)
      end
    end
  end

  module StringBitMatcherMethods
    refine String do
      def as(name)
        BitMatcher.new(length, name, to_i(2))
      end
    end
  end

  using IntegerBitMatcherMethods
  using StringBitMatcherMethods

  class BitMatcher
    attr_reader :length, :name

    def initialize(length, name, value = nil)
      @length = length
      @mask = (1 << length) - 1
      @name = name
      @value = value
      @optional = false
    end

    def match(byte, shift = 0)
      value = (byte >> shift) & @mask
      if @value
        value == @value ? value : false
      else
        value
      end
    end
  end

  class ByteMatcher
    def initialize(bits = []) = @bits = bits
    def <<(bit) = @bits.insert(0, bit)
    def length = @bits.map(&:length).sum
    def if(**conditions) = (@conditions = (@conditions || []) + [conditions]; self)
    alias_method :or, :if

    def should_match?(memo)
      return true unless @conditions
      @conditions.any? { |conds| conds.all? { |k, v| Array(v).include?(memo[k]) } }
    end

    def match(byte)
      shift = 0
      @bits.each.inject({}) do |memo, bit|
        if value = bit.match(byte, shift)
          memo[bit.name] = value
          shift += bit.length
        else
          return nil
        end
        memo
      end
    end
  end

  class << self
    def to_bit_matcher(value)
      case value
      when BitMatcher then value
      when String then BitMatcher.new(value.length, :opcode, value.to_i(2))
      when Symbol then BitMatcher.new(1, value)
      else raise "Unable to convert to bit matcher: #{value.inspect}"
      end
    end

    def to_byte_matchers(entries)
      entries.each.inject([ByteMatcher.new]) do |memo, entry|
        if entry.is_a?(ByteMatcher)
          raise 'Invalid instruction' unless memo.last.length == 8
          next memo.tap { _1 << entry }
        end

        memo << ByteMatcher.new if memo.last.length == 8

        to_bit_matcher(entry).then do |bit_matcher|
          raise 'Invalid instruction' unless bit_matcher.length + memo.last.length <= 8
          memo.last << bit_matcher
          memo
        end
      end
    end

    def byte(name)
      ByteMatcher.new([BitMatcher.new(8, name)])
    end
  end

  DISP_LOW = byte(:disp_low).if(mod: [1, 2]).or(mod: 0, rm: 6).freeze
  DISP_HIGH = byte(:disp_high).if(mod: 2).or(mod: 0, rm: 6).freeze
  DATA_LOW = byte(:data_low).freeze
  DATA_HIGH = byte(:data_high).if(w: 1).freeze
  DATA_SW = byte(:data_high).if(s: 0, w: 1).freeze

  INSTRUCTIONS_TABLE = [
    [:mov, ['100010', :d, :w, 2.bits(:mod), 3.bits(:reg), 3.bits(:rm), DISP_LOW, DISP_HIGH]],
    [:mov, ['1100011', :w, 2.bits(:mod), '000'.as(:_), 3.bits(:rm), DISP_LOW, DISP_HIGH, DATA_LOW, DATA_HIGH], d: 0],
    [:mov, ['1011', :w, 3.bits(:reg), DATA_LOW, DATA_HIGH], d: 1],
    [:mov, ['1010000', :w, 8.bits(:addr_low), 8.bits(:addr_high)], reg: 0, mod: 0, rm: 6, d: 1],
    [:mov, ['1010001', :w, 8.bits(:addr_low), 8.bits(:addr_high)], reg: 0, mod: 0, rm: 6, d: 0],
    [:mov, ['10001110', 2.bits(:mod), 3.bits(:sr), 3.bits(:rm), DISP_LOW, DISP_HIGH], d: 1, w: 1],
    [:mov, ['10001100', 2.bits(:mod), 3.bits(:sr), 3.bits(:rm), DISP_LOW, DISP_HIGH], d: 0, w: 1],

    [:add, ['000000', :d, :w, 2.bits(:mod), 3.bits(:reg), 3.bits(:rm), DISP_LOW, DISP_HIGH]],
    [:add, ['100000', :s, :w, 2.bits(:mod), '000'.as(:_), 3.bits(:rm), DISP_LOW, DISP_HIGH, DATA_LOW, DATA_SW]],
    [:add, ['0000010', :w, DATA_LOW, DATA_HIGH], d: 1, reg: 0],

    [:sub, ['001010', :d, :w, 2.bits(:mod), 3.bits(:reg), 3.bits(:rm), DISP_LOW, DISP_HIGH]],
    [:sub, ['100000', :s, :w, 2.bits(:mod), '101'.as(:_), 3.bits(:rm), DISP_LOW, DISP_HIGH, DATA_LOW, DATA_SW]],
    [:sub, ['0010110', :w, DATA_LOW, DATA_HIGH], d: 1, reg: 0],

    [:cmp, ['001110', :d, :w, 2.bits(:mod), 3.bits(:reg), 3.bits(:rm), DISP_LOW, DISP_HIGH]],
    [:cmp, ['100000', :s, :w, 2.bits(:mod), '111'.as(:_), 3.bits(:rm), DISP_LOW, DISP_HIGH, DATA_LOW, DATA_SW]],
    [:cmp, ['0011110', :w, DATA_LOW, DATA_HIGH], d: 1, reg: 0],

    [:je,     ['01110100', 8.bits(:ip_inc8)]],
    [:jl,     ['01111100', 8.bits(:ip_inc8)]],
    [:jle,    ['01111110', 8.bits(:ip_inc8)]],
    [:jb,     ['01110010', 8.bits(:ip_inc8)]],
    [:jbe,    ['01110110', 8.bits(:ip_inc8)]],
    [:jp,     ['01111010', 8.bits(:ip_inc8)]],
    [:jo,     ['01110000', 8.bits(:ip_inc8)]],
    [:js,     ['01111000', 8.bits(:ip_inc8)]],
    [:jne,    ['01110101', 8.bits(:ip_inc8)]],
    [:jnl,    ['01111101', 8.bits(:ip_inc8)]],
    [:jnle,   ['01111111', 8.bits(:ip_inc8)]],
    [:jnb,    ['01110011', 8.bits(:ip_inc8)]],
    [:jnbe,   ['01110111', 8.bits(:ip_inc8)]],
    [:jnp,    ['01111011', 8.bits(:ip_inc8)]],
    [:jno,    ['01110001', 8.bits(:ip_inc8)]],
    [:jns,    ['01111001', 8.bits(:ip_inc8)]],
    [:loop,   ['11100010', 8.bits(:ip_inc8)]],
    [:loopz,  ['11100001', 8.bits(:ip_inc8)]],
    [:loopnz, ['11100000', 8.bits(:ip_inc8)]],
    [:jcxz,   ['11100011', 8.bits(:ip_inc8)]]
  ].map { |n, b, i| [n, to_byte_matchers(b), i] }.freeze
end
