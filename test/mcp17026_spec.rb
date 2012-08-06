require 'i2c'
#require 'mock/mock_i2c_io.rb'

class MockI2CIO

  attr_reader :registers
  attr_reader :last_address

  def initialize
    @registers = Hash.new
    # Initialize according to data sheet
    (0x00..0x01).each do |reg| 
      @registers[reg] = 0xFF
    end
    (0x02..0x15).each do |reg|
      @registers[reg] = 0x00
    end
  end

  def write(address, *params)
    @last_address = address
    if params.count >= 1
      reg_addr = params.shift
      index = 0
      params.each do |p|
        @registers[reg_addr+index] = p
        index += 1
      end
    end
  end

  def read(address, size, *params)
    @last_address = address
    answer = String.new
    answer.force_encoding("US-ASCII")
    if (size > 0) && (params.count >= 1)
      reg_addr = params.shift
      (0...size).each do |index|
        answer << (@registers[reg_addr+index] & 0xFF)
      end
    end
    answer
  end
end

describe I2C::Drivers::MCP17026, "#mode?" do
  it "initially returns 1 for all pin modes" do
    io = MockI2CIO.new
    mcp17026 = I2C::Drivers::MCP17026.new(io, 0x20)
    (0..15).each do |pin|
      mcp17026.mode?(pin).should eq(1)
    end
  end
end

describe I2C::Drivers::MCP17026, "#mode?" do
  it "returns what has been set through #mode" do
    io = MockI2CIO.new
    mcp17026 = I2C::Drivers::MCP17026.new(io, 0x20)
    (0..500).each do |pin|
      pin = rand(16)
      mode = rand(2)
      mcp17026.mode(pin, mode)
      mcp17026.mode?(pin).should eq(mode)
    end
  end
end

describe I2C::Drivers::MCP17026, "#[]" do
  it "initially returns 0 for all I/O pins" do
    io = MockI2CIO.new
    mcp17026 = I2C::Drivers::MCP17026.new(io, 0x20)
    (0..15).each do |pin|
      mcp17026[pin].should eq(0)
    end
  end
end

describe I2C::Drivers::MCP17026, "#[]" do
  it "returns what has been set through #[]=" do
    io = MockI2CIO.new
    mcp17026 = I2C::Drivers::MCP17026.new(io, 0x20)
    (0..500).each do |pin|
      pin = rand(16)
      value = rand(2)
      mcp17026[pin] = value
      mcp17026[pin].should eq(value)
    end
  end
end
