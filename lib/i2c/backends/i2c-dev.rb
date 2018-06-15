# -*- coding: utf-8 -*-
# I2C - Linux i2c-dev backend.
#
# Copyright (c) 2012 Christoph Anderegg <christoph@christoph-anderegg.ch>
# Copyright (c) 2008 Jonas Bähr, jonas.baehr@fs.ei.tum.de
# This file may be distributed under the terms of the GNU General Public
# License Version 2.
#
module I2C
	class Dev
		# see i2c-dev.h
		I2C_SLAVE = 0x0703

		def self.create(device_path)
			raise Errno::ENOENT, "Device #{device_path} not found." unless File.exists?(device_path)
			@instances ||= Hash.new
			@instances[device_path] = Dev.new(device_path) unless @instances.has_key?(device_path)
			@instances[device_path]
		end

		attr_reader :comsMutex

		# this tries to lock the coms mutex, unless already held,
		# then sends every param, begining with +params[0]+
		# If the current param is a Fixnum, it is treated as one byte.
		# If the param is a String, this string will be sent byte by byte.
		# You can use Array#pack to create a string from an array
		# For Fixnum there is a convenient function to_short which transforms
		# the number to a string this way: 12345.to_short == [12345].pack("s")
		def write(address, *params)
			if(@comsMutex.owned?)
				keepLock = true;
			else
				@comsMutex.lock;
			end

			begin
				setup_device(address);
				raw_write(params);
			ensure
				@comsMutex.unlock() unless keepLock;
			end
		end

		# this tries to lock the coms mutex (unless already held),
		# then sends *params, if given, and then tries to read
		# +size+ bytes. The result is a String which can be treated with
		# String#unpack afterwards
		def read(address, size, *params)
			if(@comsMutex.owned?)
				keepLock = true;
			else
				@comsMutex.lock;
			end

			begin
				setup_device(address);
				raw_write(params) unless params.empty?
				result = raw_read(size);
			ensure
				@comsMutex.unlock() unless keepLock;
				return result;
			end
		end

		# Read a byte from the current address. Return a one char String which
		# can be treated with String#unpack
		def read_byte(address)
			read(address, 1);
		end

		private
		# Set up @device for a I2C communication to address
		def setup_device(address)
			@device.ioctl(I2C_SLAVE, address);
		end

		# Read size bytes from @device, if possible. Raise an error otherwise
		def raw_read(size)
			return @device.sysread(size)
		end

		# Write "params" to @device, unrolling them first should they be an array.
		# params should be a string, formatted with Array.pack as explained for write()
		def raw_write(params)
			data = String.new();
			data.force_encoding("US-ASCII")

			if(params.is_a? Array)
				params.each do |i| data << i; end
			else
				data << params;
			end

			@device.syswrite(data);
		end

		def initialize(device_path)
			@comsMutex = Mutex.new();

			@device = File.new(device_path, 'r+')
			# change the sys* functions of the file object to meet our requirements
			class << @device
				alias :syswrite_orig :syswrite
				def syswrite(var)
					begin
						syswrite_orig var
					rescue Errno::EREMOTEIO, Errno::EIO
						raise AckError, "No acknowledge received"
					end
				end
				alias :sysread_orig :sysread
				def sysread(var)
					begin
						sysread_orig var
					rescue Errno::EREMOTEIO, Errno::EIO
						raise AckError, "No acknowledge received"
					end
				end
			end # virtual class
		end # initialize
	end # Class
end # Module
