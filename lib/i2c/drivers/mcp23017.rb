# -*- coding: utf-8 -*-
# I2C IO-Expander driver 
# for the MCP23017 16-bit IO-Expander.
#
# Copyright (c) 2012 Christoph Anderegg <christoph@christoph-anderegg.ch>
# This file may be distributed under the terms of the GNU General Public
# License Version 2.
#

require 'i2c/i2c.rb'

# Constants for mode()
INPUT = 1
OUTPUT = 0

# Constants for write()
HIGH = 1
LOW = 0
      
module I2C
  module Drivers
    # Driver class for the Microchip MPC23017 16-bit 
    # IO-Expander.
    #
    # The interface is mostly compatible to the interface
    # of the WiringPi gem. PWM is not supported though.
    # On the other hand a more rubyesque interface is also
    # provided.
    class MCP23017
      # Registers
      IODIRA = 0x00
      IODIRB = 0x01
      GPIOA = 0x12
      GPIOB = 0x13
      
      # Creates an instance representing exactly one
      # MCP23017 on one I2C-bus.
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
        
        @dir_a = 0xFF # Direction is input initially 
        @dir_b = 0xFF # Direction is input initially
        @device.write(@address, IODIRA, @dir_a, @dir_b)
        
        @data_a = 0xFF # Initial data
        @data_b = 0xFF # Initial data
        @data_a, @data_b = @device.read(@address, 2, GPIOA).unpack("CC")   
      end  
      
      # Reads the mode of a IO-pin.
      # @param pin [Integer] Pin number to check.
      # @return [Integer] Pin mode. Either INPUT or OUTPUT. 
      def mode?(pin)
        @dir_a, @dir_b = @device.read(@address, 2, IODIRA).unpack("CC")
        dir = @dir_a
        if 8 <= pin
          dir = @dir_b
          pin -= 8
        end
        return (dir >> pin) & 0x01
      end
      
      # Sets the mode of a IO-pin.
      # @param pin [Integer] Pin number to set.
      # @param pin_mode [Integer] Pin mode. Either INPUT or OUTPUT. 
      def mode(pin, pin_mode)
        raise ArgumentError, "Pin not 0-15" unless (0..15).include?(pin)
        raise ArgumentError, 'invalid value' unless [0,1].include?(pin_mode)
        if 8 <= pin
          @dir_b = set_bit_value(@dir_b, (pin-8), pin_mode)
        else
          @dir_a = set_bit_value(@dir_a, pin, pin_mode)
        end
        @device.write(@address, IODIRA, @dir_a, @dir_b)
      end
      
      # Sets a IO-pin value.
      # @param pin [Integer] Pin number to set.
      # @param value [Integer] Pin value. Either HIGH or LOW. 
      def []=(pin, value)
        raise ArgumentError, "Pin not 0-15" unless (0..15).include?(pin)
        raise ArgumentError, 'invalid value' unless [0,1].include?(value)
        if 8 <= pin
          @data_b = set_bit_value(@data_b, (pin-8), value)
        else
          @data_a = set_bit_value(@data_a, pin, value)
        end
        @device.write(@address, GPIOA, @data_a, @data_b)
      end

      #  Alias for a WiringPi compatible naming.
      alias :write :[]= 
        
      # Reads a IO-pin value.
      # @param pin [Integer] Pin number to set.
      # @return [Integer] Pin value. Either HIGH or LOW. 
      def [](pin)
        raise ArgumentError, "Pin not 0-15." unless (0..15).include?(pin)
        @data_a, @data_b = @device.read(@address, 2, GPIOA).unpack("CC")
        data = @data_a
        if 8 <= pin
          data  = @data_b;
          pin -= 8
        end
        return (data >> pin) & 0x01        
      end

      #  Alias for a WiringPi compatible naming.
      alias_method :read, :[]
      
      private
      def set_bit_value(byte, bit, value)
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
#        puts "Byte: (0x#{"%X" % byte}) 0b#{"%B" % byte}; " +
#          "Mask: 0b#{"%B" % mask}; Bit: #{bit}; Value: #{value}"
        byte
      end
    end
  end
end
