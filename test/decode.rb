#! /usr/bin/env ruby

require 'minitest/autorun'

require_relative '../lib/altjson'

class TestDecode < Minitest::Test
	parallelize_me!
	
	def test_null
		assert_equal [nil, 1], "\x82".from_altjson
	end
	
	def test_bool
		assert_equal [true,  1], "\x81".from_altjson
		assert_equal [false, 1], "\x80".from_altjson
	end
	
	def test_int
		assert_equal [0x22,1], "\x22".from_altjson
		assert_equal [-1,1], "\xFF".from_altjson
		assert_equal [0x2345,3], "\xA1\x23\x45".from_altjson
		assert_equal [0x12345678,5], "\xA2\x12\x34\x56\x78".from_altjson
		assert_equal [-0x4000,3], "\xA9\xC0\x00".from_altjson
	end
	
	def test_double
		assert_equal [0.0, 9], "\x83\0\0\0\0\0\0\0\0".from_altjson
		assert_equal [3.0, 9], "\x83\x40\x08\0\0\0\0\0\0".from_altjson
		assert_equal [3.5, 9], "\x83\x40\x0C\0\0\0\0\0\0".from_altjson
	end
	
	
	def test_str
		assert_equal ['Hi',3], "\x42Hi".from_altjson
		assert_equal ['!!',4], "\xB0\x02!!".from_altjson
	end
	
	def test_arr
		assert_equal [[],1],  "\xC0".from_altjson
		assert_equal [[2],2], "\xC1\x02".from_altjson
		assert_equal [[2],3], "\x90\x01\x02".from_altjson
	end
	
	def test_hash
		assert_equal [{'a'=>4},4],     "\xD1\x41a\x04".from_altjson
		assert_equal [{'ad'=>true},6], "\x98\x01\x42ad\x81".from_altjson
	end
end
