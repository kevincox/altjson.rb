#! /usr/bin/env ruby

require 'minitest/autorun'

require_relative '../lib/altjson'

class TestIntegration < Minitest::Test
	parallelize_me!
	make_my_diffs_pretty!
	
	def assert_roundtrip(o)
		b = o.to_altjson
		r, l = AltJSON.decode(b)
		assert_equal o, r
		assert_equal b.length, l
	end
	
	def test_integration
		s = {
			'e' => 0,
			'msg' => 'This is a message about your request.',
			'items' => [1,2,3,4,5,6,7,8,9]*1024,
			'weird' => [{'a' => 'b', 'c' => 5}, {'f' => 4}],
			'longfloat' => 41414.24251245215412,
			'superlongfloat' => 4195921845895147686785.46151614563461515614615,
		}
		
		assert_roundtrip s
	end
end
