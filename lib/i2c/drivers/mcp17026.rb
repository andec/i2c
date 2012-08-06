# -*- coding: utf-8 -*-
# I2C IO-Expander driver 
# for the MCP23017 16-bit IO-Expander.
#
# The interface is compatible to the interface
# of the WiringPi gem. PWM is not supported though.
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
    class MCP17026
      # Registers
      IODIRA = 0x00
      IODIRB = 0x01
      GPIOA = 0x12
      GPIOB = 0x13
      
      # Creates an instance representing exactly one
      # MCP17026 on one I2C-bus.
      #
      # device: I2C-device file (usually /dev/i2c-0).
      # address: Device address on the bus.
      def initialize(device, address)
        @device = nil
        @device = ::I2C.create(device)
        @address = address
        
        @dir_a = 0xFF # Direction is input initially 
        @dir_b = 0xFF # Direction is input initially
        @device.write(@address, IODIRA, @dir_a, @dir_b)
        
        @data_a = 0xFF # Initial data
        @data_b = 0xFF # Initial data
        @data_a, @data_b = @device.read(@address, 2, GPIOA).unpack("CC")   
      end  
      
      def mode?(pin)
        @dir_a, @dir_b = @device.read(@address, 2, IODIRA)
        dir = @dir_a
        if 8 <= pin
          dir = @dir_b
        end
        return (@dir_b >> pin) & 0x01
      end
      
      def mode(pin, pin_mode)
        raise ArgumentError, "Pin not 0-15" unless (0..16).include?(pin)
        raise ArgumentError, 'invalid value' unless [0,1].include?(pin_mode)
        if 8 <= pin
          puts "ModeB"
          @dir_b = set_bit_value(@dir_b, (pin-8), pin_mode)
        else
          @dir_a = set_bit_value(@dir_a, pin, pin_mode)
          puts "ModeA"
        end
        @device.write(@address, IODIRA, @dir_a, @dir_b)
        #@device.write(@address, IODIRA, @dir_a)
      end
      
      def []=(pin, value)
        raise ArgumentError, "Pin not 0-15" unless (0..15).include?(pin)
        raise ArgumentError, 'invalid value' unless [0,1].include?(value)
        if 8 <= pin
          puts "DataB"
          @data_b = set_bit_value(@data_b, (pin-8), value)
        else
          puts "DataA"
          @data_a = set_bit_value(@data_a, pin, value)
        end
        puts "#{@device}: addr: 0x#{"%X" % @address} DAta: 0b#{"%B" % @data_a}"
        @device.write(@address, GPIOA, @data_a, @data_b)
        #@device.write(@address, GPIOA, @data_a)
      end
      alias :write :[]= 
        
      def [](pin)
        raise ArgumentError, "Pin not 0-15." unless (0..15).include?(pin)
        @data_a, @data_b = @device.read(@address, 2, GPIOA).unpack("CC")
        if 8 <= pin
          return ((@data_b & (0x01 << (pin-8))) != 0x00)
        end
        return ((@data_a & (0x01 << pin)) != 0x00)
      end
      alias :read :[]
      
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
