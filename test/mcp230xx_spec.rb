require 'i2c'

class MockI2CIO
  attr_reader :registers
  attr_reader :last_address

  def initialize
    @registers = Hash.new
    # Initialize according to data sheet
    (0x00..0x01).each do |reg| 
      @registers[reg] = 0xFF
    end
    (0x02..0x13).each do |reg|
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
      size.times do |index|
        answer << (@registers[reg_addr+index] & 0xFF)
      end
    end
    answer
  end
end

describe I2C::Drivers::MCP23017, "#port_count" do
  it "returns the number of ports." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    mcp.port_count.should eq(2)
  end
end

describe I2C::Drivers::MCP23017, "#max_port_no" do
  it "returns the highest port number." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    mcp.max_port_no.should eq(1)
  end
end

describe I2C::Drivers::MCP23017, "#pin_count" do
  it "returns the number of pins." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    mcp.pin_count.should eq(16)
  end
end

describe I2C::Drivers::MCP23017, "#max_pin_no" do
  it "returns the highest pin number." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    mcp.max_pin_no.should eq(15)
  end
end

describe I2C::Drivers::MCP23017, "#check_pin" do
  it "raises an exception for out of range pin indices." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    [-1000, -1, 16, 1000].each do |pin|
      expect { mcp.check_pin(pin) }.to raise_error
    end
  end

  it "returns nil for valid indices." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    16.times do |pin|
      mcp.check_pin(pin).should eq nil
    end
  end
end

describe I2C::Drivers::MCP23017, "#check_port" do
  it "raises an exception for out of range port indices." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    [-1000, -1, 2, 1000].each do |port|
      expect { mcp.check_port(port) }.to raise_error
    end
  end

  it "returns nil for valid indices." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    2.times do |port|
      mcp.check_port(port).should eq nil
    end
  end
end

describe I2C::Drivers::MCP23017, "#port_for_pin" do
  it "returns correctly split pin and port numbers for 16bit IO expanders." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    expected =
      [[0, 0],
       [0, 1],
       [0, 2],
       [0, 3],
       [0, 4],
       [0, 5],
       [0, 6],
       [0, 7],
       [1, 0],
       [1, 1],
       [1, 2],
       [1, 3],
       [1, 4],
       [1, 5],
       [1, 6],
       [1, 7]]
      expected.each_index do |pin|
      mcp.port_for_pin(pin).should eq(expected[pin])
    end
  end

  it "raises an exception for out of range arguments." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    [1000, 16, -1, -1000].each do |pin|
      expect { mcp.port_for_pin(pin) }.to raise_error
    end
  end
end 

describe I2C::Drivers::MCP23017, "#set_bit_value" do
  it "raises on non-integer arguments for the first argument" do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    expect { mcp.set_bit_value("Hello", 0, 0) }.to raise_error
  end
  it "raises on non-integer arguments for the second argument" do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    expect { mcp.set_bit_value(0, "Hello", 0) }.to raise_error
  end
  it "raises on arguments other than 0 and 1 for the third argument" do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    [1000, 2, -1, -1000].each do |value|
      expect { mcp.set_bit_value(0, 0, value) }.to raise_error
    end
  end
  it "sets the correct bits in a byte" do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    # Original, bit no, new value, result
    [
     [ 0b11111111, 0, 0, 0b11111110 ],
     [ 0b00000000, 0, 1, 0b00000001 ],
     [ 0b11111111, 7, 0, 0b01111111 ],
     [ 0b00000000, 7, 1, 0b10000000 ],
     [ 0b11111111, 0, 1, 0b11111111 ],
     [ 0b00000000, 0, 0, 0b00000000 ]
    ].each do |test|
      mcp.set_bit_value(test[0], test[1], test[2]).should eq test[3]
    end
  end
end

describe I2C::Drivers::MCP23017, "#mode" do
  it "raises an exception for out of range pin indices." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    [-1000, -1, 16, 1000].each do |pin|
      expect { mcp.mode(pin, HIGH) }.to raise_error
    end
  end
end

describe I2C::Drivers::MCP23017, "#mode?" do
  it "raises an exception for out of range pin indices." do
    io = MockI2CIO.new
    mcp = I2C::Drivers::MCP23017.new(io, 0x20)
    [-1000, -1, 16, 1000].each do |pin|
      expect { mcp.mode?(pin) }.to raise_error
    end
  end

  it "initially returns 1 for all pin modes" do
    io = MockI2CIO.new
    mcp23017 = I2C::Drivers::MCP23017.new(io, 0x20)
    (0..15).each do |pin|
      mcp23017.mode?(pin).should eq(1)
    end
  end

  it "returns what has been set through #mode" do
    io = MockI2CIO.new
    mcp23017 = I2C::Drivers::MCP23017.new(io, 0x20)
    (0..500).each do |pin|
      pin = rand(16)
      mode = rand(2)
      mcp23017.mode(pin, mode)
      mcp23017.mode?(pin).should eq(mode)
    end
  end
end

describe I2C::Drivers::MCP23017, "#[]" do
  it "initially returns 0 for all I/O pins" do
    io = MockI2CIO.new
    mcp23017 = I2C::Drivers::MCP23017.new(io, 0x20)
    (0..15).each do |pin|
      mcp23017[pin].should eq(0)
    end
  end
  it "returns what has been set through #[]=" do
    io = MockI2CIO.new
    mcp23017 = I2C::Drivers::MCP23017.new(io, 0x20)
    (0..500).each do |pin|
      pin = rand(16)
      value = rand(2)
      mcp23017[pin] = value
      mcp23017[pin].should eq(value)
    end
  end
end
