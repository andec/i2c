require 'i2c'

class MockI2CIO
  attr_reader :registers
  attr_reader :last_address

  def initialize
    @registers = Hash.new
    # Initialize according to data sheet
    @registers[0x00] = 0xFF
    (0x01..0x0A).each do |reg|
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

describe I2C::Drivers::MCP23008, "#mode?" do
  it "initially returns 1 for all pin modes" do
    io = MockI2CIO.new
    mcp23008 = I2C::Drivers::MCP23008.new(io, 0x20)
    (0..7).each do |pin|
      mcp23008.mode?(pin).should eq(1)
    end
  end
end

describe I2C::Drivers::MCP23008, "#mode?" do
  it "returns what has been set through #mode" do
    io = MockI2CIO.new
    mcp23008 = I2C::Drivers::MCP23008.new(io, 0x20)
    (0..500).each do |pin|
      pin = rand(8)
      mode = rand(2)
      mcp23008.mode(pin, mode)
      mcp23008.mode?(pin).should eq(mode)
    end
  end
end

describe I2C::Drivers::MCP23008, "#[]" do
  it "initially returns 0 for all I/O pins" do
    io = MockI2CIO.new
    mcp23008 = I2C::Drivers::MCP23008.new(io, 0x20)
    (0..7).each do |pin|
      mcp23008[pin].should eq(0)
    end
  end
end

describe I2C::Drivers::MCP23008, "#[]" do
  it "returns what has been set through #[]=" do
    io = MockI2CIO.new
    mcp23008 = I2C::Drivers::MCP23008.new(io, 0x20)
    (0..500).each do |pin|
      pin = rand(8)
      value = rand(2)
      mcp23008[pin] = value
      mcp23008[pin].should eq(value)
    end
  end
end
