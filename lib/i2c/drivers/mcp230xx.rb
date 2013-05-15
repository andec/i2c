# -*- coding: utf-8 -*-
# I2C IO-Expander drivers. 
#
# Copyright (c) 2012 Christoph Anderegg <christoph@christoph-anderegg.ch>
# This file may be distributed under the terms of the GNU General Public
# License Version 2.
#

require 'i2c/i2c.rb'

# Constants for mode()
INPUT = 1 unless defined? INPUT
OUTPUT = 0 unless defined? OUTPUT

# Constants for write()
HIGH = 1 unless defined? HIGH
LOW = 0 unless defined? LOW

module I2C
  module Drivers
    # Driver class for the Microchip MPC230xx IO-Expanders.
    #
    # The interface is mostly compatible to the interface
    # of the WiringPi gem. PWM is not supported though.
    # On the other hand a more rubyesque interface is also
    # provided.
    module MCP230xx
      # Creates an instance representing exactly one
      # MCP230xx on one I2C-bus.
      #
      # @todo This implementation currently assumes
      #   that all registers of the same type are
      #   on a continuos address range. Implement
      #   a (less efficient) case for other
      #   situations.
      #
      # @param device [IO, String] I2C-device file 
      #   (usually /dev/i2c-0). Or an intantiated 
      #   io class that supports the necessary 
      #   operations (#read, #write and #ioctl).
      # @param address [Integer] Device address on the bus.
      def initialize(device, address)
        if device.kind_of?(String)
          @device = ::I2C.create(device)
        else
          [ :read, :write ].each do |m|
            raise IncompatibleDeviceException, 
            "Missing #{m} method in device object." unless device.respond_to?(m)
          end
          @device = device
        end
        @address = address
        
        @iodir = Array.new
        max_port_no.times { @iodir << 0xFF } # Direction is input initially
        @device.write(@address, port_count, iodir[0], @iodir)
        
        @data = Array.new
        max_port_no.times { @data << 0xFF }
        @unpack_string = "C" * port_count
        @data = @device.read(@address, port_count, gpio[0]).unpack(@unpack_string)
        @dir = @device.read(@address, port_count, iodir[0]).unpack(@unpack_string)
      end  

      # Reads the mode of a IO-pin.
      # @param pin [Integer] Pin number to check.
      # @return [Integer] Pin mode. Either INPUT or OUTPUT. 
      def mode?(pin)
        check_pin(pin) # Raises if the pin is not valid
        @dir = @device.read(@address, port_count, iodir[0]).unpack(@unpack_string)
        index = port_for_pin(pin)

        (@dir[index[0]] >> index[1]) & 0x01
      end

      # Sets the mode of a IO-pin.
      # @param pin [Integer] Pin number to set.
      # @param pin_mode [Integer] Pin mode. Either INPUT or OUTPUT. 
      def mode(pin, pin_mode)
        check_pin(pin) # Raises if the pin is not valid
        raise ArgumentError, 'invalid value' unless [0,1].include?(pin_mode)
        index = port_for_pin(pin)

        @dir[index[0]] = set_bit_value(@dir[index[0]], index[1], pin_mode)
        @device.write(@address, iodir[0], *@dir)
       end

      # Sets a IO-pin value.
      # @param pin [Integer] Pin number to set.
      # @param value [Integer] Pin value. Either HIGH or LOW. 
      def []=(pin, value)
        check_pin(pin) # Raises if the pin is not valid
        raise ArgumentError, 'invalid value' unless [0,1].include?(value)
        index = port_for_pin(pin)
        @data[index[0]] = set_bit_value(@data[index[0]], index[1], value)
        @device.write(@address, gpio[0], *@data)
      end

      #  Alias for a WiringPi compatible naming.
      alias :write :[]= 
        
      # Reads a IO-pin value.
      # @param pin [Integer] Pin number to set.
      # @return [Integer] Pin value. Either HIGH or LOW. 
      def [](pin)
        check_pin(pin) # Raises if the pin is not valid
        index = port_for_pin(pin)
        @data = @device.read(@address, port_count, gpio[0]).unpack(@unpack_string)
        index = port_for_pin(pin)

        (@data[index[0]] >> index[1]) & 0x01
      end

      #  Alias for a WiringPi compatible naming.
      alias_method :read, :[]

#      private
      # Checks a pin number for validity.
      # Raises an exception if not valid. Returns nil otherwise.
      # @param pin [Integer] IO pin number.
      # @return nil Raises an exception in all other cases.
      def check_pin(pin)
        raise ArgumentError, "Pin not 0-#{max_pin_no}" unless (0..max_pin_no).include?(pin)
        nil
      end

      # Checks a port number for validity.
      # Raises an exception if not valid. Returns nil otherwise.
      # @param no [Integer] IO port number.
      # @return nil Raises an exception in all other cases.
      def check_port(no)
        raise ArgumentError, "Only Ports 0-#{max_port_no} available." unless (0..max_port_no).include?(no)
        nil
      end

      # Returns a port no, index in port pair for a pin number.
      #
      # E.g. Pin 14 is the is bit 7 of port 1. So the method returns [1,7].
      #
      # @param pin [Integer] Pin number, begining at 0.
      # @return [Array<Integer, Integer>] Port number and index in the port 
      #    of the passed continuos pin number. 
      def port_for_pin(pin)
        check_pin(pin)
        [pin / 8, pin % 8]
      end

      # Sets a bit in a byte to a defied state not touching the other bits.
      #
      # @param byte [Integer] Byte to manipulate (LSB).
      # @param bit [Integer] Bit number to manipulate.
      # @param value [Integer] 1 or 0; the new value of the bit.
      # @return [Integer] The new byte
      def set_bit_value(byte, bit, value)
        [byte, bit, value].each do |p|
          raise ArgumentError, "Arguments must be Integer" unless p.kind_of? Integer
        end
        raise ArgumentError, "Only bits 0..7 are available." unless bit < 8
        raise ArgumentError, "Value needs to be 0 or 1." unless (value == 0) or (value == 1)
        mask = 0x00
        mask = (0x01 << bit)
        case value
        when 0
          byte = (byte & ((~mask) & 0xFF)) & 0xFF
        when 1
          byte = (byte |  mask) & 0xFF
        else
          raise ArgumentError, "Bit not 0-7."
        end
        byte
      end

      # @!method iodir(no)
      # Returns the address of the IO direction register 
      # for an IO port.
      #
      # @param no [Integer] Port number, begining at 0.
      # @return Address of the IO direction register 
      #   corresponding to passed IO port number.
      
      # @!method gpio(no)
      # Returns the address of the GPIO register 
      # for an IO port.
      #
      # @param no [Integer] Port number, begining at 0.
      # @return [Integer] Address of the GPIO register 
      #   corresponding to passed IO port number.

      # @!method pin_count
      # Returns the number of pins in the io expander.
      #
      # @return [Integer] Number of pins.

      # @!method max_pin_no
      # Returns the highest pin index. Usually #pin_count - 1.
      #
      # @return [Integer] Highest pin index.

      # @!method port_count
      # Returns the number of ports in the io expander.
      #
      # @return [Integer] Number of ports.

      # @!method max_port_no
      # Returns the highest port index. Usually #port_count - 1.
      #
      # @return [Integer] Highest port index.
    end
    
    # Defines a class for a chip implementation.
    #
    # @param name Class name
    def self.define_mcp230xx_chip(name, parameters)
      raise ArgumentError, "Expecting options hash." unless parameters.kind_of? Hash
      [ [ :pin_count, Integer ],
        [ :port_count, Integer ],
        [ :iodir, Array ],
        [ :gpio, Array ] ].each do |expected_key| 
        raise ArgumentError, "Missing option #{expected_key[0]}" unless 
          parameters.has_key? expected_key[0] 
        raise ArgumentError, "Option #{expected_key[0]} expected to be a #{expected_key[1]}" unless 
          parameters[expected_key[0]].kind_of? expected_key[1] 
      end
      chip_class = self.const_set(name.to_sym, Class.new)
      chip_class.instance_eval do
        include MCP230xx
        parameters.each do |method_name, return_value|
          #puts "Defining #{name}##{method_name.to_sym}"
          define_method method_name.to_sym do
            return_value
          end
        end
        define_method :max_pin_no do 
          parameters[:pin_count] - 1 
        end 
        define_method :max_port_no do 
          parameters[:port_count] - 1 
        end 
      end
      chip_class
    end
    define_mcp230xx_chip :MCP23008,       
      :pin_count => 8,
      :port_count => 1,
      :iodir => [ 0x00 ],
      :gpio => [ 0x09 ]
    define_mcp230xx_chip :MCP23017,
      :pin_count => 16,
      :port_count => 2,
      :iodir => [ 0x00, 0x01 ],
      :gpio => [ 0x12, 0x13 ]
  end
end    
