#! /usr/bin/env ruby

require 'minitest/autorun'

require_relative '../lib/altjson'

class TestEncode < Minitest::Test
	parallelize_me!
	
	def test_true_const
		assert_equal 0x81, AltJSON::TRUE
	end
	def test_true
		assert_equal "\x81".b,   true.to_altjson
		assert_equal "\x81".b,   true.to_altjson('')
		assert_equal "21\x81".b, true.to_altjson('21')
	end
	
	def test_false_const
		assert_equal 0x80, AltJSON::FALSE
	end
	def test_false
		assert_equal "\x80".b,   false.to_altjson
		assert_equal "\x80".b,   false.to_altjson('')
		assert_equal "32\x80".b, false.to_altjson('32')
	end
	
	def test_null_const
		assert_equal 0x82, AltJSON::NULL
	end
	def test_null
		assert_equal "\x82".b,   nil.to_altjson
		assert_equal "\x82".b,   nil.to_altjson('')
		assert_equal "32\x82".b, nil.to_altjson('32')
	end
	
	def test_double_const
		assert_equal 0x83, AltJSON::DOUBLE
	end
	def test_double
		assert_equal "\x83\0\0\0\0\0\0\0\0".b, 0.0.to_altjson
		assert_equal "\x83\x40\x08\0\0\0\0\0\0".b, 3.0.to_altjson
		assert_equal "\x83\x40\x0C\0\0\0\0\0\0".b, 3.5.to_altjson
	end
	
	def test_int_const
		assert_equal 0xA0, AltJSON::INT
		assert_equal AltJSON::INT & AltJSON::INT_MASK, AltJSON::INT
		assert_equal 0, AltJSON::INT_SHORT
	end
	def test_int
		assert_equal "\xA2\xFF\xFE\xFD\xFC".b,  0xFFFEFDFC.to_altjson
		assert_equal "3\xA2\xFF\xFE\xFD\xFC".b, 0xFFFEFDFC.to_altjson('3')
		
		assert_equal "\xA301234567".b, 0x3031323334353637.to_altjson
		assert_equal "\xA1\x4D\xFC".b, 0x4DFC.to_altjson
		assert_equal "\xA0\xF3".b,     0xF3.to_altjson
		assert_equal "\x13".b,         0x13.to_altjson
		
		assert_equal "\xA9\xC0\0".b, -0x4000.to_altjson
		assert_equal "\xA8\xC0".b,   -0b01000000.to_altjson
	end
	
	def test_str_const
		assert_equal 0xB0, AltJSON::STR
		assert_equal AltJSON::STR & AltJSON::STR_MASK, AltJSON::STR
		assert_equal 0x40, AltJSON::STR_SHORT
	end
	def test_str
		assert_equal "\xB0\x70".b  << ('a'*0x70), ('a'*0x70).to_altjson
		assert_equal "\xB0\x70".b  << ('a'*0x70), ('a'*0x70).to_altjson('')
		assert_equal "3\xB0\x70".b << ('a'*0x70), ('a'*0x70).to_altjson('3')
		
		assert_equal "\xB1\x04\0".b<<('abcd'*256), ('abcd'*256).to_altjson
		
		assert_equal "\x43123".b, '123'.to_altjson
		
		assert_equal "\x43foo".b, :foo.to_altjson
	end
	
	def test_dic_const
		assert_equal 0x98,                             AltJSON::DIC
		assert_equal AltJSON::DIC & AltJSON::DIC_MASK, AltJSON::DIC
		assert_equal 0xD0,                             AltJSON::DIC_SHORT
	end
	def test_dic
		def check(d, tag, aj)
			assert_equal tag, aj.slice!(0, tag.length)
			
			out = []
			
			i = 0
			# We know that they are all the same length.
			len = '0123456789'.to_altjson.length+'0123'.to_altjson.length
			while i < aj.length
				out << aj[i, len]
				i += len
			end
			out.sort!
			
			exp = []
			d.each { |k, v| exp << v.to_altjson(k.to_altjson) }
			exp.sort!
			
			assert_equal exp, out
		end
		d = {}
		
		def add(d, num)
			chars = ['A'..'Z','a'..'z','0'..'9'].map{|r| r.to_a}.join
			
			while num > 0
				k = (0...10).map{ chars[rand(chars.length)] }.join
				
				next if d[k]
				
				d[k] = (0...4).map{ chars[rand(chars.length)] }.join
				num -= 1
			end
		end
		
		add(d, 0x0A)
		
		check d, "\xDA".b, d.to_altjson
		check d, "\xDA".b, d.to_altjson('')
		check d, "3\xDA".b, d.to_altjson('3')
		
		add(d, 0x40)
		
		check d, "\x98\x4A".b, d.to_altjson
		
		assert_equal "\xD0".b, {}.to_altjson
	end
	
	def test_arr_const
		assert_equal 0x90,                             AltJSON::ARR
		assert_equal AltJSON::ARR & AltJSON::ARR_MASK, AltJSON::ARR
		assert_equal 0xC0,                             AltJSON::ARR_SHORT
	end
	def test_arr
		assert_equal "\xC1\x02".b,  [0x02].to_altjson
		assert_equal "\xC1\x02".b,  [0x02].to_altjson('')
		assert_equal "2\xC1\x02".b, [0x02].to_altjson('2')
		
		src = [1, 'foo', -3]*256
		exp = (1.to_altjson << 'foo'.to_altjson << -3.to_altjson)*256
		
		assert_equal "\x91\x03\0".b << exp, src.to_altjson
	end
end
