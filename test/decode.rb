#! /usr/bin/env ruby

require 'minitest/autorun'

require_relative '../lib/altjson'

class TestDecode < Minitest::Test
	parallelize_me!
	
	def test_bool
		assert_equal [nil, 1] [AltJSON::NULL].from_altjson
	end
	
	def test_bool
		assert_equal [true,  1], [AltJSON::TRUE,].from_altjson
		assert_equal [false, 1], [AltJSON::FALSE].from_altjson
	end
	
	def test_int
		assert_equal [42,1], [AltJSON::INT_SHORT|42].from_altjson
		assert_equal [-1,1], [AltJSON::INT_NEG|0xFF].from_altjson
		assert_equal [0x2345,3], [AltJSON::INT|1, 0x23, 0x45].from_altjson
		assert_equal [0x12345678,5], [AltJSON::INT|2, 0x12, 0x34, 0x56, 0x78].from_altjson
		assert_equal [-0x4000,3], [AltJSON::INT|AltJSON::INT_SIGN|1, 0xC0, 0x00].from_altjson
	end
	
	def test_double
		assert_equal [0.0, 9], [AltJSON::DOUBLE, 0,0,0,0,0,0,0,0].from_altjson
		assert_equal [3.0, 9], [AltJSON::DOUBLE, 0x40,0x08,0,0,0,0,0,0].from_altjson
		assert_equal [3.5, 9], [AltJSON::DOUBLE, 0x40,0x0C,0,0,0,0,0,0].from_altjson
	end
	
	
	def test_str
		assert_equal ['Hi',3], [AltJSON::STR_SHORT|2, *'Hi'.bytes].from_altjson
		assert_equal ['!!',4], [AltJSON::STR, 2, *'!!'.bytes].from_altjson
	end
	
	def test_arr
		assert_equal [[],1],  [AltJSON::ARR_SHORT].from_altjson
		assert_equal [[2],2], [AltJSON::ARR_SHORT|1, *2.to_altjson].from_altjson
		assert_equal [[2],3], [AltJSON::ARR, 1, *2.to_altjson].from_altjson
	end
	
	def test_hash
		assert_equal [{"a"=>4},4], [AltJSON::DIC_SHORT|1, *:a.to_altjson, *4.to_altjson].from_altjson
		assert_equal [{"ad"=>true},6], [AltJSON::DIC, 1, *:ad.to_altjson, 0x81].from_altjson
	end
end
