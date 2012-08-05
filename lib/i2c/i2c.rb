# -*- coding: utf-8 -*-
# Entry point to the I2C library.
#
# Essentially this requires the correct backend
# driver, right now this means the linux i2c-dev driver.
# This could be extended to do some system specific
#
# Copyright (c) 2012 Christoph Anderegg <christoph@christoph-anderegg.ch>
# Copyright (c) 2008 Jonas Bähr, jonas.baehr@fs.ei.tum.de 
#
# This file may be distributed under the terms of the GNU General Public
# License Version 2.
#

require 'i2c/backends/i2c-dev.rb'

module I2C
  # some common error classes
  class AckError < StandardError; end

  # Returns an instance of the current backend 
  # driver.
  #
  # Is there a system agnostic way to do this?
  #
  # +bus_descriptor+ describes the bus to use. This is
  #                  of course system specific. For the
  #                  Linux i2c-dev driver this is the
  #                  device file (e.g. /dev/i2c-0").
  def create(bus_descriptor)
    I2C::Dev.create(bus_descriptor)
  end
end


