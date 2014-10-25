=head1 NAME

JSON::XS - JSON serialising/deserialising, done correctly and fast

=head1 SYNOPSIS

 use JSON::XS;

 # exported functions, they croak on error
 # and expect/generate UTF-8

 $utf8_encoded_json_text = to_json $perl_hash_or_arrayref;
 $perl_hash_or_arrayref  = from_json $utf8_encoded_json_text;

 # objToJson and jsonToObj aliases to to_json and from_json
 # are exported for compatibility to the JSON module,
 # but should not be used in new code.

 # OO-interface

 $coder = JSON::XS->new->ascii->pretty->allow_nonref;
 $pretty_printed_unencoded = $coder->encode ($perl_scalar);
 $perl_scalar = $coder->decode ($unicode_json_text);

=head1 DESCRIPTION

This module converts Perl data structures to JSON and vice versa. Its
primary goal is to be I<correct> and its secondary goal is to be
I<fast>. To reach the latter goal it was written in C.

As this is the n-th-something JSON module on CPAN, what was the reason
to write yet another JSON module? While it seems there are many JSON
modules, none of them correctly handle all corner cases, and in most cases
their maintainers are unresponsive, gone missing, or not listening to bug
reports for other reasons.

See COMPARISON, below, for a comparison to some other JSON modules.

See MAPPING, below, on how JSON::XS maps perl values to JSON values and
vice versa.

=head2 FEATURES

=over 4

=item * correct unicode handling

This module knows how to handle Unicode, and even documents how and when
it does so.

=item * round-trip integrity

When you serialise a perl data structure using only datatypes supported
by JSON, the deserialised data structure is identical on the Perl level.
(e.g. the string "2.0" doesn't suddenly become "2" just because it looks
like a number).

=item * strict checking of JSON correctness

There is no guessing, no generating of illegal JSON texts by default,
and only JSON is accepted as input by default (the latter is a security
feature).

=item * fast

Compared to other JSON modules, this module compares favourably in terms
of speed, too.

=item * simple to use

This module has both a simple functional interface as well as an OO
interface.

=item * reasonably versatile output formats

You can choose between the most compact guarenteed single-line format
possible (nice for simple line-based protocols), a pure-ascii format
(for when your transport is not 8-bit clean, still supports the whole
unicode range), or a pretty-printed format (for when you want to read that
stuff). Or you can combine those features in whatever way you like.

=back

=cut

package JSON::XS;

use strict;

BEGIN {
   our $VERSION = '1.21';
   our @ISA = qw(Exporter);

   our @EXPORT = qw(to_json from_json objToJson jsonToObj);
   require Exporter;

   require XSLoader;
   XSLoader::load JSON::XS::, $VERSION;
}

=head1 FUNCTIONAL INTERFACE

The following convinience methods are provided by this module. They are
exported by default:

=over 4

=item $json_text = to_json $perl_scalar

Converts the given Perl data structure (a simple scalar or a reference to
a hash or array) to a UTF-8 encoded, binary string (that is, the string contains
octets only). Croaks on error.

This function call is functionally identical to:

   $json_text = JSON::XS->new->utf8->encode ($perl_scalar)

except being faster.

=item $perl_scalar = from_json $json_text

The opposite of C<to_json>: expects an UTF-8 (binary) string and tries to
parse that as an UTF-8 encoded JSON text, returning the resulting simple
scalar or reference. Croaks on error.

This function call is functionally identical to:

   $perl_scalar = JSON::XS->new->utf8->decode ($json_text)

except being faster.

=back


=head1 OBJECT-ORIENTED INTERFACE

The object oriented interface lets you configure your own encoding or
decoding style, within the limits of supported formats.

=over 4

=item $json = new JSON::XS

Creates a new JSON::XS object that can be used to de/encode JSON
strings. All boolean flags described below are by default I<disabled>.

The mutators for flags all return the JSON object again and thus calls can
be chained:

   my $json = JSON::XS->new->utf8->space_after->encode ({a => [1,2]})
   => {"a": [1, 2]}

=item $json = $json->ascii ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will not
generate characters outside the code range C<0..127> (which is ASCII). Any
unicode characters outside that range will be escaped using either a
single \uXXXX (BMP characters) or a double \uHHHH\uLLLLL escape sequence,
as per RFC4627. The resulting encoded JSON text can be treated as a native
unicode string, an ascii-encoded, latin1-encoded or UTF-8 encoded string,
or any other superset of ASCII.

If C<$enable> is false, then the C<encode> method will not escape Unicode
characters unless required by the JSON syntax or other flags. This results
in a faster and more compact format.

The main use for this flag is to produce JSON texts that can be
transmitted over a 7-bit channel, as the encoded JSON texts will not
contain any 8 bit characters.

  JSON::XS->new->ascii (1)->encode ([chr 0x10401])
  => ["\ud801\udc01"]

=item $json = $json->latin1 ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will encode
the resulting JSON text as latin1 (or iso-8859-1), escaping any characters
outside the code range C<0..255>. The resulting string can be treated as a
latin1-encoded JSON text or a native unicode string. The C<decode> method
will not be affected in any way by this flag, as C<decode> by default
expects unicode, which is a strict superset of latin1.

If C<$enable> is false, then the C<encode> method will not escape Unicode
characters unless required by the JSON syntax or other flags.

The main use for this flag is efficiently encoding binary data as JSON
text, as most octets will not be escaped, resulting in a smaller encoded
size. The disadvantage is that the resulting JSON text is encoded
in latin1 (and must correctly be treated as such when storing and
transfering), a rare encoding for JSON. It is therefore most useful when
you want to store data structures known to contain binary data efficiently
in files or databases, not when talking to other JSON encoders/decoders.

  JSON::XS->new->latin1->encode (["\x{89}\x{abc}"]
  => ["\x{89}\\u0abc"]    # (perl syntax, U+abc escaped, U+89 not)

=item $json = $json->utf8 ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will encode
the JSON result into UTF-8, as required by many protocols, while the
C<decode> method expects to be handled an UTF-8-encoded string.  Please
note that UTF-8-encoded strings do not contain any characters outside the
range C<0..255>, they are thus useful for bytewise/binary I/O. In future
versions, enabling this option might enable autodetection of the UTF-16
and UTF-32 encoding families, as described in RFC4627.

If C<$enable> is false, then the C<encode> method will return the JSON
string as a (non-encoded) unicode string, while C<decode> expects thus a
unicode string.  Any decoding or encoding (e.g. to UTF-8 or UTF-16) needs
to be done yourself, e.g. using the Encode module.

Example, output UTF-16BE-encoded JSON:

  use Encode;
  $jsontext = encode "UTF-16BE", JSON::XS->new->encode ($object);

Example, decode UTF-32LE-encoded JSON:

  use Encode;
  $object = JSON::XS->new->decode (decode "UTF-32LE", $jsontext);

=item $json = $json->pretty ([$enable])

This enables (or disables) all of the C<indent>, C<space_before> and
C<space_after> (and in the future possibly more) flags in one call to
generate the most readable (or most compact) form possible.

Example, pretty-print some simple structure:

   my $json = JSON::XS->new->pretty(1)->encode ({a => [1,2]})
   =>
   {
      "a" : [
         1,
         2
      ]
   }

=item $json = $json->indent ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will use a multiline
format as output, putting every array member or object/hash key-value pair
into its own line, identing them properly.

If C<$enable> is false, no newlines or indenting will be produced, and the
resulting JSON text is guarenteed not to contain any C<newlines>.

This setting has no effect when decoding JSON texts.

=item $json = $json->space_before ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will add an extra
optional space before the C<:> separating keys from values in JSON objects.

If C<$enable> is false, then the C<encode> method will not add any extra
space at those places.

This setting has no effect when decoding JSON texts. You will also
most likely combine this setting with C<space_after>.

Example, space_before enabled, space_after and indent disabled:

   {"key" :"value"}

=item $json = $json->space_after ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will add an extra
optional space after the C<:> separating keys from values in JSON objects
and extra whitespace after the C<,> separating key-value pairs and array
members.

If C<$enable> is false, then the C<encode> method will not add any extra
space at those places.

This setting has no effect when decoding JSON texts.

Example, space_before and indent disabled, space_after enabled:

   {"key": "value"}

=item $json = $json->canonical ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will output JSON objects
by sorting their keys. This is adding a comparatively high overhead.

If C<$enable> is false, then the C<encode> method will output key-value
pairs in the order Perl stores them (which will likely change between runs
of the same script).

This option is useful if you want the same data structure to be encoded as
the same JSON text (given the same overall settings). If it is disabled,
the same hash migh be encoded differently even if contains the same data,
as key-value pairs have no inherent ordering in Perl.

This setting has no effect when decoding JSON texts.

=item $json = $json->allow_nonref ([$enable])

If C<$enable> is true (or missing), then the C<encode> method can convert a
non-reference into its corresponding string, number or null JSON value,
which is an extension to RFC4627. Likewise, C<decode> will accept those JSON
values instead of croaking.

If C<$enable> is false, then the C<encode> method will croak if it isn't
passed an arrayref or hashref, as JSON texts must either be an object
or array. Likewise, C<decode> will croak if given something that is not a
JSON object or array.

Example, encode a Perl scalar as JSON value with enabled C<allow_nonref>,
resulting in an invalid JSON text:

   JSON::XS->new->allow_nonref->encode ("Hello, World!")
   => "Hello, World!"

=item $json = $json->shrink ([$enable])

Perl usually over-allocates memory a bit when allocating space for
strings. This flag optionally resizes strings generated by either
C<encode> or C<decode> to their minimum size possible. This can save
memory when your JSON texts are either very very long or you have many
short strings. It will also try to downgrade any strings to octet-form
if possible: perl stores strings internally either in an encoding called
UTF-X or in octet-form. The latter cannot store everything but uses less
space in general (and some buggy Perl or C code might even rely on that
internal representation being used).

The actual definition of what shrink does might change in future versions,
but it will always try to save space at the expense of time.

If C<$enable> is true (or missing), the string returned by C<encode> will
be shrunk-to-fit, while all strings generated by C<decode> will also be
shrunk-to-fit.

If C<$enable> is false, then the normal perl allocation algorithms are used.
If you work with your data, then this is likely to be faster.

In the future, this setting might control other things, such as converting
strings that look like integers or floats into integers or floats
internally (there is no difference on the Perl level), saving space.

=item $json = $json->max_depth ([$maximum_nesting_depth])

Sets the maximum nesting level (default C<512>) accepted while encoding
or decoding. If the JSON text or Perl data structure has an equal or
higher nesting level then this limit, then the encoder and decoder will
stop and croak at that point.

Nesting level is defined by number of hash- or arrayrefs that the encoder
needs to traverse to reach a given point or the number of C<{> or C<[>
characters without their matching closing parenthesis crossed to reach a
given character in a string.

Setting the maximum depth to one disallows any nesting, so that ensures
that the object is only a single hash/object or array.

The argument to C<max_depth> will be rounded up to the next nearest power
of two.

See SECURITY CONSIDERATIONS, below, for more info on why this is useful.

=item $json_text = $json->encode ($perl_scalar)

Converts the given Perl data structure (a simple scalar or a reference
to a hash or array) to its JSON representation. Simple scalars will be
converted into JSON string or number sequences, while references to arrays
become JSON arrays and references to hashes become JSON objects. Undefined
Perl values (e.g. C<undef>) become JSON C<null> values. Neither C<true>
nor C<false> values will be generated.

=item $perl_scalar = $json->decode ($json_text)

The opposite of C<encode>: expects a JSON text and tries to parse it,
returning the resulting simple scalar or reference. Croaks on error.

JSON numbers and strings become simple Perl scalars. JSON arrays become
Perl arrayrefs and JSON objects become Perl hashrefs. C<true> becomes
C<1>, C<false> becomes C<0> and C<null> becomes C<undef>.

=item ($perl_scalar, $characters) = $json->decode_prefix ($json_text)

This works like the C<decode> method, but instead of raising an exception
when there is trailing garbage after the first JSON object, it will
silently stop parsing there and return the number of characters consumed
so far.

This is useful if your JSON texts are not delimited by an outer protocol
(which is not the brightest thing to do in the first place) and you need
to know where the JSON text ends.

   JSON::XS->new->decode_prefix ("[1] the tail")
   => ([], 3)

=back


=head1 MAPPING

This section describes how JSON::XS maps Perl values to JSON values and
vice versa. These mappings are designed to "do the right thing" in most
circumstances automatically, preserving round-tripping characteristics
(what you put in comes out as something equivalent).

For the more enlightened: note that in the following descriptions,
lowercase I<perl> refers to the Perl interpreter, while uppcercase I<Perl>
refers to the abstract Perl language itself.

=head2 JSON -> PERL

=over 4

=item object

A JSON object becomes a reference to a hash in Perl. No ordering of object
keys is preserved (JSON does not preserver object key ordering itself).

=item array

A JSON array becomes a reference to an array in Perl.

=item string

A JSON string becomes a string scalar in Perl - Unicode codepoints in JSON
are represented by the same codepoints in the Perl string, so no manual
decoding is necessary.

=item number

A JSON number becomes either an integer or numeric (floating point)
scalar in perl, depending on its range and any fractional parts. On the
Perl level, there is no difference between those as Perl handles all the
conversion details, but an integer may take slightly less memory and might
represent more values exactly than (floating point) numbers.

=item true, false

These JSON atoms become C<0>, C<1>, respectively. Information is lost in
this process. Future versions might represent those values differently,
but they will be guarenteed to act like these integers would normally in
Perl.

=item null

A JSON null atom becomes C<undef> in Perl.

=back

=head2 PERL -> JSON

The mapping from Perl to JSON is slightly more difficult, as Perl is a
truly typeless language, so we can only guess which JSON type is meant by
a Perl value.

=over 4

=item hash references

Perl hash references become JSON objects. As there is no inherent ordering
in hash keys (or JSON objects), they will usually be encoded in a
pseudo-random order that can change between runs of the same program but
stays generally the same within a single run of a program. JSON::XS can
optionally sort the hash keys (determined by the I<canonical> flag), so
the same datastructure will serialise to the same JSON text (given same
settings and version of JSON::XS), but this incurs a runtime overhead
and is only rarely useful, e.g. when you want to compare some JSON text
against another for equality.

=item array references

Perl array references become JSON arrays.

=item other references

Other unblessed references are generally not allowed and will cause an
exception to be thrown, except for references to the integers C<0> and
C<1>, which get turned into C<false> and C<true> atoms in JSON. You can
also use C<JSON::XS::false> and C<JSON::XS::true> to improve readability.

   to_json [\0,JSON::XS::true]      # yields [false,true]

=item blessed objects

Blessed objects are not allowed. JSON::XS currently tries to encode their
underlying representation (hash- or arrayref), but this behaviour might
change in future versions.

=item simple scalars

Simple Perl scalars (any scalar that is not a reference) are the most
difficult objects to encode: JSON::XS will encode undefined scalars as
JSON null value, scalars that have last been used in a string context
before encoding as JSON strings and anything else as number value:

   # dump as number
   to_json [2]                      # yields [2]
   to_json [-3.0e17]                # yields [-3e+17]
   my $value = 5; to_json [$value]  # yields [5]

   # used as string, so dump as string
   print $value;
   to_json [$value]                 # yields ["5"]

   # undef becomes null
   to_json [undef]                  # yields [null]

You can force the type to be a string by stringifying it:

   my $x = 3.1; # some variable containing a number
   "$x";        # stringified
   $x .= "";    # another, more awkward way to stringify
   print $x;    # perl does it for you, too, quite often

You can force the type to be a number by numifying it:

   my $x = "3"; # some variable containing a string
   $x += 0;     # numify it, ensuring it will be dumped as a number
   $x *= 1;     # same thing, the choise is yours.

You can not currently output JSON booleans or force the type in other,
less obscure, ways. Tell me if you need this capability.

=back


=head1 COMPARISON

As already mentioned, this module was created because none of the existing
JSON modules could be made to work correctly. First I will describe the
problems (or pleasures) I encountered with various existing JSON modules,
followed by some benchmark values. JSON::XS was designed not to suffer
from any of these problems or limitations.

=over 4

=item JSON 1.07

Slow (but very portable, as it is written in pure Perl).

Undocumented/buggy Unicode handling (how JSON handles unicode values is
undocumented. One can get far by feeding it unicode strings and doing
en-/decoding oneself, but unicode escapes are not working properly).

No roundtripping (strings get clobbered if they look like numbers, e.g.
the string C<2.0> will encode to C<2.0> instead of C<"2.0">, and that will
decode into the number 2.

=item JSON::PC 0.01

Very fast.

Undocumented/buggy Unicode handling.

No roundtripping.

Has problems handling many Perl values (e.g. regex results and other magic
values will make it croak).

Does not even generate valid JSON (C<{1,2}> gets converted to C<{1:2}>
which is not a valid JSON text.

Unmaintained (maintainer unresponsive for many months, bugs are not
getting fixed).

=item JSON::Syck 0.21

Very buggy (often crashes).

Very inflexible (no human-readable format supported, format pretty much
undocumented. I need at least a format for easy reading by humans and a
single-line compact format for use in a protocol, and preferably a way to
generate ASCII-only JSON texts).

Completely broken (and confusingly documented) Unicode handling (unicode
escapes are not working properly, you need to set ImplicitUnicode to
I<different> values on en- and decoding to get symmetric behaviour).

No roundtripping (simple cases work, but this depends on wether the scalar
value was used in a numeric context or not).

Dumping hashes may skip hash values depending on iterator state.

Unmaintained (maintainer unresponsive for many months, bugs are not
getting fixed).

Does not check input for validity (i.e. will accept non-JSON input and
return "something" instead of raising an exception. This is a security
issue: imagine two banks transfering money between each other using
JSON. One bank might parse a given non-JSON request and deduct money,
while the other might reject the transaction with a syntax error. While a
good protocol will at least recover, that is extra unnecessary work and
the transaction will still not succeed).

=item JSON::DWIW 0.04

Very fast. Very natural. Very nice.

Undocumented unicode handling (but the best of the pack. Unicode escapes
still don't get parsed properly).

Very inflexible.

No roundtripping.

Does not generate valid JSON texts (key strings are often unquoted, empty keys
result in nothing being output)

Does not check input for validity.

=back

=head2 SPEED

It seems that JSON::XS is surprisingly fast, as shown in the following
tables. They have been generated with the help of the C<eg/bench> program
in the JSON::XS distribution, to make it easy to compare on your own
system.

First comes a comparison between various modules using a very short JSON
string:

   {"method": "handleMessage", "params": ["user1", "we were just talking"], "id": null}

It shows the number of encodes/decodes per second (JSON::XS uses the
functional interface, while JSON::XS/2 uses the OO interface with
pretty-printing and hashkey sorting enabled). Higher is better:

   module     |     encode |     decode |
   -----------|------------|------------|
   JSON       |  11488.516 |   7823.035 |
   JSON::DWIW |  94708.054 | 129094.260 |
   JSON::PC   |  63884.157 | 128528.212 |
   JSON::Syck |  34898.677 |  42096.911 |
   JSON::XS   | 654027.064 | 396423.669 |
   JSON::XS/2 | 371564.190 | 371725.613 |
   -----------+------------+------------+

That is, JSON::XS is more than six times faster than JSON::DWIW on
encoding, more than three times faster on decoding, and about thirty times
faster than JSON, even with pretty-printing and key sorting.

Using a longer test string (roughly 18KB, generated from Yahoo! Locals
search API (http://nanoref.com/yahooapis/mgPdGg):

   module     |     encode |     decode |
   -----------|------------|------------|
   JSON       |    273.023 |     44.674 |
   JSON::DWIW |   1089.383 |   1145.704 |
   JSON::PC   |   3097.419 |   2393.921 |
   JSON::Syck |    514.060 |    843.053 |
   JSON::XS   |   6479.668 |   3636.364 |
   JSON::XS/2 |   3774.221 |   3599.124 |
   -----------+------------+------------+

Again, JSON::XS leads by far.

On large strings containing lots of high unicode characters, some modules
(such as JSON::PC) seem to decode faster than JSON::XS, but the result
will be broken due to missing (or wrong) unicode handling. Others refuse
to decode or encode properly, so it was impossible to prepare a fair
comparison table for that case.


=head1 SECURITY CONSIDERATIONS

When you are using JSON in a protocol, talking to untrusted potentially
hostile creatures requires relatively few measures.

First of all, your JSON decoder should be secure, that is, should not have
any buffer overflows. Obviously, this module should ensure that and I am
trying hard on making that true, but you never know.

Second, you need to avoid resource-starving attacks. That means you should
limit the size of JSON texts you accept, or make sure then when your
resources run out, thats just fine (e.g. by using a separate process that
can crash safely). The size of a JSON text in octets or characters is
usually a good indication of the size of the resources required to decode
it into a Perl structure.

Third, JSON::XS recurses using the C stack when decoding objects and
arrays. The C stack is a limited resource: for instance, on my amd64
machine with 8MB of stack size I can decode around 180k nested arrays but
only 14k nested JSON objects (due to perl itself recursing deeply on croak
to free the temporary). If that is exceeded, the program crashes. to be
conservative, the default nesting limit is set to 512. If your process
has a smaller stack, you should adjust this setting accordingly with the
C<max_depth> method.

And last but least, something else could bomb you that I forgot to think
of. In that case, you get to keep the pieces. I am always open for hints,
though...


=head1 BUGS

While the goal of this module is to be correct, that unfortunately does
not mean its bug-free, only that I think its design is bug-free. It is
still relatively early in its development. If you keep reporting bugs they
will be fixed swiftly, though.

=cut

sub true()  { \1 }
sub false() { \0 }

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

