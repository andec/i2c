# -*- coding: utf-8 -*-
# I2C IO-Expander driver 
# for the MCP23008 8-bit IO-Expander.
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
    # Driver class for the Microchip MPC23008 8-bit 
    # IO-Expander.
    #
    # The interface is mostly compatible to the interface
    # of the WiringPi gem. PWM is not supported though.
    # On the other hand a more rubyesque interface is also
    # provided.
    class MCP23008
      # Registers
      IODIR = 0x00
      GPIO = 0x09
      
      # Creates an instance representing exactly one
      # MCP23008 on one I2C-bus.
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
        
        @dir = 0xFF # Direction is input initially 
        @device.write(@address, IODIR, @dir)
        @data = @device.read(@address, 1, GPIO).unpack("C")[0]   
      end  
      
      def mode?(pin)
        @dir = @device.read(@address, 1, IODIR).unpack("C")[0]
        return (@dir >> pin) & 0x01
      end
      
      # Sets the mode of a IO-pin.
      # @param pin [Integer] Pin number to set.
      # @param pin_mode [Integer] Pin mode. Either INPUT or OUTPUT. 
      def mode(pin, pin_mode)
        raise ArgumentError, "Pin not 0-7" unless (0..7).include?(pin)
        raise ArgumentError, 'invalid value' unless [0,1].include?(pin_mode)
        @dir = set_bit_value(@dir, pin, pin_mode)
        @device.write(@address, IODIR, @dir)
      end
      
      # Sets a IO-pin value.
      # @param pin [Integer] Pin number to set.
      # @param value [Integer] Pin value. Either HIGH or LOW. 
      def []=(pin, value)
        raise ArgumentError, "Pin not 0-7" unless (0..7).include?(pin)
        raise ArgumentError, 'invalid value' unless [0,1].include?(value)
        @data = set_bit_value(@data, pin, value)
        @device.write(@address, GPIO, @data)
      end

      #  Alias for a WiringPi compatible naming.
      alias :write :[]= 
        
      # Reads a IO-pin value.
      # @param pin [Integer] Pin number to set.
      # @return [Integer] Pin value. Either HIGH or LOW. 
      def [](pin)
        raise ArgumentError, "Pin not 0-7." unless (0..7).include?(pin)
        @data = @device.read(@address, 1, GPIO).unpack("C")[0]
        return (@data >> pin) & 0x01        
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
        byte
      end
    end
  end
end
