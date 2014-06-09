# AltJSON

[![Build Status](https://travis-ci.org/kevincox/altjson.rb.png?branch=master)](https://travis-ci.org/kevincox/altjson.rb)

AltJSON is an alternate encoding for JSON data.  It is simple and efficient.
Most fields require only a single tag byte and many elements can be packed
directly into the tag byte, requiring only one byte to send.

It is not designed to replace JSON but as an alternative encoding.  This means
that you can keep your JSON APIs but you can use AltJSON for clients that
support it for more compact encodings.

## Usage

```ruby
# Encode into an array of bytes.
r = {a: 5, b: [true, false, nil]}.to_altjson
r == "\xD2\x41a\x05\x41b\xC3\x81\x80\x82"

nil.to_altjson    == "\x82"
false.to_altjson  == "\x80"
true.to_altjson   == "\x81"
15.to_altjson     == "\x0F"
"foo".to_altjson  == "\x43foo"
:foo.to_altjson   # Implicitly converted to string.
[].to_altjson     == "\xC0"
{a: 3}.to_altjson == "\xD1\x41a\x03"

# Decode an array of bytes (as an array or string).
# You get two values, the value, and the length decoded.
AltJSON.decode("\xC3\x38\0\x81") == [[0x38, 0, true], 4]
"\x80".from_altjson              == [false,           1]
[0x81].from_altjson              == [true,            1]
```

## Encoding

AltJSON utilizes a very simple encoding format.  It is a single tag byte
followed by a variable number of data bytes.  Furthermore many types can pack
extra data into the tag byte to cut down on encoded size.

The different types are described below.

### Boolean

Boolean values are encoded as just a tag byte.  The byte is `0b10000001` for true
and `0b10000000` for false.

### Null

Null is encoded as the tag byte `0b10000010`.

### Integers

#### Standard Form

Integers are encoded in the form `0b1010sbbb` where `s` indicates signed (set)
or unsigned (unset) numbers.  And `bbb` indicates the number of bytes used to
encode the number.  The number of bytes is calculated as `n = 2^b`.  So a `b` of
0 is one byte and a `b` of 3 is eight bytes.  There is currently room for 256
byte (2048 bit) numbers although this may be changed in the future if the bits
are more valuable elsewhere.

The following `n` bytes are the integer in big-endian byte order.  Signed
integers are in two's complement encoding.

#### Compact Form

Small integers are included directly included in the tag byte.  Positive
integers take the form `0b00vvvvvv` for positive integers and `0b111vvvvv` for
negative integers.  These values are the integer, or the two's complement of the
negative integer.  Both of these forms can hold 6-bit integers (because of the
implied 1 for two's complement) meaning that integers in the range `-31 - 63`.
Since integers tend to be small this is a huge savings.

### Strings

Strings are treated as pure binary data by AltJSON although it is recommended to
use UTF-8 encoded strings as JSON requires.

#### Standard Form

Strings are a tag byte of the form `0b10110bbb` followed by `n` length bytes
where `n` is calculated from `b` the same way as for integers, then the value in
those bytes `s` is the number of bytes in the string.

#### Compact Form

Strings have a compact form very similar to integers where their length is
encoded in the tag byte.  The tag byte takes the form `0b01ssssss` where `s` is
the size of the string.  The bytes of the string then follow.  This allows
strings of up to 63 bytes not require an additional byte to describe their
length.

### Floating Point Values

Floating point values are encoded as `0b10000011` followed by 8 bytes of
big-endian IEEE double precision floating point value.

### Arrays

#### Standard Form

Arrays are encoded as `0b10010bbb` where `b` is the number of bytes used to
describe the length if the array in the same way as strings.  Then that many
elements of the array follow as AltJSON encoded values.

#### Compact Form

Compact form is `0b1100ssss` where `s` is the number of elements in the array.
The elements then follow.  This allows arrays of up to 15 elements to be encoded
without a length byte.

### Dictionaries

Dictionaries are a unordered mapping of keys to values.

AltJSON -- like JSON -- does not allow multiple entries in the dictionary to
have the same value (no matter how it is encoded).  It is implementation defined
how this is handled if it does occur however it is recommended that the last
encountered value is kept and the earlier ones discarded.

#### Standard Form

Dictionaries are encoded as `0b10011bbb` where `b` is the number of bytes
describing the number of entries the same way as arrays and strings.  The
entries then follow, each encoded as the key followed by the value.

#### Compact Form

The compact form is `0b1101ssss` where `s` is the number of entries in the
dictionary.  The entries then follow.
