#! /usr/bin/env ruby

# Copyright 2014 Kevin Cox

################################################################################
#                                                                              #
#  This software is provided 'as-is', without any express or implied           #
#  warranty. In no event will the authors be held liable for any damages       #
#  arising from the use of this software.                                      #
#                                                                              #
#  Permission is granted to anyone to use this software for any purpose,       #
#  including commercial applications, and to alter it and redistribute it      #
#  freely, subject to the following restrictions:                              #
#                                                                              #
#  1. The origin of this software must not be misrepresented; you must not     #
#     claim that you wrote the original software. If you use this software in  #
#     a product, an acknowledgment in the product documentation would be       #
#     appreciated but is not required.                                         #
#                                                                              #
#  2. Altered source versions must be plainly marked as such, and must not be  #
#     misrepresented as being the original software.                           #
#                                                                              #
#  3. This notice may not be removed or altered from any source distribution.  #
#                                                                              #
################################################################################

require 'stringio'

class Object
	def to_altjson(*args)
		raise TypeError.new "Can't encode #{self.class} to altjson."
	end
end

class NilClass
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		into << AltJSON::NULL
	end
end

class TrueClass
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		into << AltJSON::TRUE
	end
end
class FalseClass
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		into << AltJSON::FALSE
	end
end

class Integer
	def altjson_sign_flag
		if self < 0
			AltJSON::INT_SIGN
		else
			0
		end
	end
	
	def to_altjson(into='', short=true)
		# into.force_encoding Encoding::BINARY # Done in helpers.
		bits = bit_length
		if self < 0
			bits += 1 # For the sign bit.
		end
		
		case
		when bits <= 6 && short
			to_altjson6 into
		when bits <= 8
			to_altjson8 into
		when bits <= 16
			to_altjson16 into
		when bits <= 32
			to_altjson32 into
		when bits <= 64
			to_altjson64 into
		else
			raise TypeError.new "AltJSON doesn't know how to encode #{self}."
		end
	end
	
	def to_altjson6(into='')
		into.force_encoding Encoding::BINARY
		into << [self].pack('c'.freeze)
	end
	def to_altjson8(into='')
		into.force_encoding Encoding::BINARY
		into << (AltJSON::INT|altjson_sign_flag|0)
		into << [self].pack('C'.freeze)
	end
	def to_altjson16(into='')
		into.force_encoding Encoding::BINARY
		into << (AltJSON::INT|altjson_sign_flag|1)
		into << [self].pack('S>'.freeze)
	end
	def to_altjson32(into='')
		into.force_encoding Encoding::BINARY
		into << (AltJSON::INT|altjson_sign_flag|2)
		into << [self].pack('L>'.freeze)
	end
	def to_altjson64(into='')
		into.force_encoding Encoding::BINARY
		into << (AltJSON::INT|altjson_sign_flag|3)
		into << [self].pack('Q>'.freeze)
	end
end

class Float
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		into << AltJSON::DOUBLE
		into << [self].pack('G'.freeze)
	end
end

class String
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		bin = self.b
		
		if bin.length <= AltJSON::STR_SLEN
			into << (AltJSON::STR_SHORT|b.length)
			into << b
		else
			i = b.length.to_altjson
			i.setbyte 0, AltJSON::STR | i.getbyte(0) & AltJSON::INT_BYTE
			into << i << b
		end
	end
	
	def from_altjson(start=0)
		io = StringIO.new self, File::RDONLY|File::BINARY
		io.seek start
		[io.from_altjson, io.tell]
	end
end

class StringIO
	def from_altjson
		AltJSON.decode(self)
	end
end

class Symbol
	def to_altjson(*args)
		to_s.to_altjson *args
	end
end

class Hash
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		if length <= AltJSON::DIC_SLEN
			into << (AltJSON::DIC_SHORT | length)
		else
			i = length.to_altjson('', false)
			i.setbyte 0, AltJSON::DIC | i.getbyte(0) & AltJSON::INT_BYTE
			into << i
		end
		
		each {|k,v| k.to_altjson into; v.to_altjson into }
		
		into
	end
end

module Enumerable
	def to_altjson(into='')
		into.force_encoding Encoding::BINARY
		if length <= AltJSON::ARR_SLEN
			into << (AltJSON::ARR_SHORT | length)
		else
			i = length.to_altjson('', false)
			i.setbyte 0, AltJSON::ARR | i.getbyte(0) & AltJSON::INT_BYTE
			into << i
		end
		
		each {|v| v.to_altjson into }
		
		into
	end
	
	def from_altjson(*args)
		AltJSON.decode pack('C*'.freeze), *args
	end
end

module AltJSON
	VERSION   = '1.0.0'.freeze
	
	BOOL      = 0b10000000
	BOOL_MASK = 0b11111110
	FALSE     = 0b10000000
	TRUE      = 0b10000001
	
	NULL      = 0b10000010
	DOUBLE    = 0b10000011
	
	#           0b1010sbbb
	INT       = 0b10100000 # 2^(b+1) bytes.
	INT_MASK  = 0b11110000
	INT_SIGN  = 0b00001000
	INT_BYTE  = 0b00000111
	
	#           0b10110bbb # 2^(b+1) bytes.
	STR       = 0b10110000
	STR_MASK  = 0b11111000
	STR_BYTE  = 0b00000111
	
	#           0b10011bbb
	DIC       = 0b10011000 # 2^(b+1) bytes of length.
	DIC_MASK  = 0b11111000
	DIC_BYTE  = 0b00000111
	
	#           0b11011bbb
	ARR       = 0b10010000
	ARR_MASK  = 0b11111000
	ARR_BYTE  = 0b00000111
	
	#           0b00vvvvvv
	INT_SHORT = 0b00000000
	INT_SMASK = 0b11000000
	
	INT_SHORT_BITS = 6
	
	#           0b111vvvvv # 2's comp
	INT_NEG   = 0b11100000
	INT_NMASK = 0b11100000
	
	INT_NEG_BITS = 6 # The leading 1 is implied.
	
	#          0b01vvvvvv
	STR_SHORT = 0b01000000
	STR_SMASK = 0b11000000
	STR_SLEN  = 0b00111111
	
	#           0b1101llll
	DIC_SHORT = 0b11010000
	DIC_SMASK = 0b11110000
	DIC_SLEN  = 0b00001111
	
	#           0b1100llll
	ARR_SHORT = 0b11000000
	ARR_SMASK = 0b11110000
	ARR_SLEN  = 0b00001111
	
	def self.encode(obj)
		obj.to_altjson
	end
	
	def self.decode(bytes)
		t = getbyte bytes
		
		# puts "Tag: 0x#{t.to_s(16).upcase}"
		
		r = case
		when t & STR_SMASK == STR_SHORT
			getbytes bytes, t & STR_SLEN
		when t & STR_MASK == STR
			l = read_int bytes, 2**(t&STR_BYTE)
			getbytes bytes, l
		when t & INT_SMASK == INT_SHORT
			t
		when t & INT_MASK == INT
			read_int bytes, 2**(t&INT_BYTE), t & INT_SIGN != 0
		when t == TRUE
			true
		when t == FALSE
			false
		when t == NULL
			nil
		when t & DIC_SMASK == DIC_SHORT
			read_dic bytes, t & DIC_SLEN
		when t & DIC_MASK == DIC
			l = read_int bytes, 2**(t&DIC_BYTE)
			d = read_dic bytes, l
		when t & ARR_SMASK == ARR_SHORT
			a = read_arr bytes, t & ARR_SLEN
		when t & ARR_MASK == ARR
			l = read_int bytes, 2**(t&ARR_BYTE)
			read_arr bytes, l
		when t & INT_NMASK == INT_NEG
			-1 & ~0xFF | t
		when t == DOUBLE
			#TODO: Removed string copy.
			getbytes(bytes, 8).unpack("G".freeze).first
		else
			raise TypeError.new "Unexpected tag 0x#{t.to_s(16).upcase}."
		end
		
		r
	end
	
	private
	
	def self.getbyte(io)
		b = io.getbyte
		raise TypeError.new 'Too little data.'.freeze unless b
		b
	end
	def self.getbytes(io, l)
		b = io.gets l
		raise TypeError.new 'Too little data.'.freeze unless b.length == l
		b
	end
	
	def self.read_int(b, c, neg=false)
		r = if neg then -1 else 0 end
		c.times { r = (r<<8) | getbyte(b) }
		r
	end
	
	def self.read_arr(b, l)
		Array.new l do |i|
			decode b
		end
	end
	
	def self.read_dic(b, l)
		d = {}
		# puts "Dic len #{l}"
		l.times do
			k = decode b
			v = decode b
			# puts "Just got #{k}/#{v}"
			d[k] = v
		end
		d
	end
end
