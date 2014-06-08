#! /usr/bin/env ruby

require 'minitest/autorun'

require_relative '../lib/altjson'

class TestEncode < Minitest::Test
	parallelize_me!
	
	def test_true_const
		assert_equal 0x81, AltJSON::TRUE
	end
	def test_true
		assert_equal [AltJSON::TRUE], true.to_altjson
		assert_equal [AltJSON::TRUE], true.to_altjson([])
		assert_equal [3,2,AltJSON::TRUE], true.to_altjson([3,2])
	end
	
	def test_false_const
		assert_equal 0x80, AltJSON::FALSE
	end
	def test_false
		assert_equal [AltJSON::FALSE], false.to_altjson
		assert_equal [AltJSON::FALSE], false.to_altjson([])
		assert_equal [3,2,AltJSON::FALSE], false.to_altjson([3,2])
	end
	
	def test_null_const
		assert_equal 0x82, AltJSON::NULL
	end
	def test_null
		assert_equal [AltJSON::NULL], nil.to_altjson
		assert_equal [AltJSON::NULL], nil.to_altjson([])
		assert_equal [3,2,AltJSON::NULL], nil.to_altjson([3,2])
	end
	
	def test_double
		assert_equal [AltJSON::DOUBLE, 0,0,0,0,0,0,0,0], 0.0.to_altjson
		assert_equal [AltJSON::DOUBLE, 0x40,0x08,0,0,0,0,0,0], 3.0.to_altjson
		assert_equal [AltJSON::DOUBLE, 0x40,0x0C,0,0,0,0,0,0], 3.5.to_altjson
	end
	
	def test_int_const
		assert_equal 0xA0, AltJSON::INT
		assert_equal AltJSON::INT & AltJSON::INT_MASK, AltJSON::INT
		assert_equal 0, AltJSON::INT_SHORT
	end
	def test_int
		assert_equal [  AltJSON::INT|2, 0xFF, 0xFE, 0xFD, 0xFC], 0xFFFEFDFC.to_altjson
		assert_equal [  AltJSON::INT|2, 0xFF, 0xFE, 0xFD, 0xFC], 0xFFFEFDFC.to_altjson([])
		assert_equal [3,AltJSON::INT|2, 0xFF, 0xFE, 0xFD, 0xFC], 0xFFFEFDFC.to_altjson([3])
		
		assert_equal [AltJSON::INT|1, 0x4D, 0xFC], 0x4DFC.to_altjson
		assert_equal [AltJSON::INT|0, 0xF3], 0xF3.to_altjson
		assert_equal [AltJSON::INT_SHORT|0x13], 0x13.to_altjson
		
		assert_equal [AltJSON::INT|AltJSON::INT_SIGN|1, 0xC0, 0x00], -0x4000.to_altjson
		assert_equal [AltJSON::INT|AltJSON::INT_SIGN|0, 0b11000000], -0b01000000.to_altjson
	end
	
	def test_str_const
		assert_equal 0xB0, AltJSON::STR
		assert_equal AltJSON::STR & AltJSON::STR_MASK, AltJSON::STR
		assert_equal 0x40, AltJSON::STR_SHORT
	end
	def test_str
		assert_equal [  AltJSON::STR|0, 70, *('a'*70).bytes], ('a'*70).to_altjson
		assert_equal [  AltJSON::STR|0, 70, *('a'*70).bytes], ('a'*70).to_altjson([])
		assert_equal [3,AltJSON::STR|0, 70, *('a'*70).bytes], ('a'*70).to_altjson([3])
		
		assert_equal [AltJSON::STR|1, 4, 0, *('abcd'*256).bytes], ('abcd'*256).to_altjson
		
		assert_equal [AltJSON::STR_SHORT|3, *'123'.bytes], '123'.to_altjson
		
		assert_equal [AltJSON::STR_SHORT|3, *'foo'.bytes], :foo.to_altjson
	end
	
	def test_dic_const
		assert_equal 0x98,                             AltJSON::DIC
		assert_equal AltJSON::DIC & AltJSON::DIC_MASK, AltJSON::DIC
		assert_equal 0xD0,                             AltJSON::DIC_SHORT
	end
	def test_dic
		def check(d, tag, aj)
			assert_equal tag, aj.shift(tag.length)
			
			out = []
			aj.each_slice(
				# We know that they are all the same length.
				"0123456789".to_altjson.length+"0123".to_altjson.length
			) do |s|
				out << s
			end
			out.sort!
			
			exp = []
			d.each { |k, v| exp << ( k.to_altjson + v.to_altjson ) }
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
		
		add(d, 10)
		
		check d, [  AltJSON::DIC_SHORT|10], d.to_altjson
		check d, [  AltJSON::DIC_SHORT|10], d.to_altjson([])
		check d, [3,AltJSON::DIC_SHORT|10], d.to_altjson([3])
		
		add(d, 50)
		
		check d, [AltJSON::DIC|0, 60], d.to_altjson
		
		assert_equal [AltJSON::DIC_SHORT], {}.to_altjson
	end
	
	def test_arr_const
		assert_equal 0x90,                             AltJSON::ARR
		assert_equal AltJSON::ARR & AltJSON::ARR_MASK, AltJSON::ARR
		assert_equal 0xC0,                             AltJSON::ARR_SHORT
	end
	def test_arr
		assert_equal [  AltJSON::ARR_SHORT|1, *2.to_altjson], [2].to_altjson
		assert_equal [  AltJSON::ARR_SHORT|1, *2.to_altjson], [2].to_altjson([])
		assert_equal [3,AltJSON::ARR_SHORT|1, *2.to_altjson], [2].to_altjson([3])
		
		src = [1, "foo", -3]*256
		exp = (1.to_altjson + "foo".to_altjson + -3.to_altjson)*256
		
		assert_equal [AltJSON::ARR|1, 3, 0, *exp], src.to_altjson
	end
	
	def test_integration
		s = {
			e: 0,
			msg: "This is a message about your request.",
			items: [1,2,3,4,5,6,7,8,9]*1024,
			weird: [{a: "b", c: 5}, {f: 4}],
		}
		
		# assert_equal s, AltJSON.decode(s.to_altjson)
	end
end
