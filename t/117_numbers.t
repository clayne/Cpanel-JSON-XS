use strict;
use Cpanel::JSON::XS;
use Test::More;
plan tests => 19;

is encode_json([9**9**9]), '[null]';
is encode_json([-sin(9**9**9)]), '[null]';
is encode_json([-9**9**9]), '[null]';
is encode_json([sin(9**9**9)]), '[null]';
is encode_json([9**9**9/9**9**9]), '[null]';

my $json = Cpanel::JSON::XS->new->stringify_infnan;
my ($inf, $nan) = ($^O eq 'MSWin32') ? ('1.#INF','1.#IND') : ('inf','nan');
is $json->encode([9**9**9]), "[\"$inf\"]";
is $json->encode([-sin(9**9**9)]), "[\"$nan\"]";
is $json->encode([-9**9**9]), "[\"-$inf\"]";
is $json->encode([sin(9**9**9)]), "[\"-$nan\"]";
is $json->encode([9**9**9/9**9**9]), "[\"-$nan\"]";

$json = Cpanel::JSON::XS->new->stringify_infnan(2);
($inf, $nan) = ('inf','nan');
is $json->encode([9**9**9]), "[$inf]";
is $json->encode([-sin(9**9**9)]), "[$nan]";
is $json->encode([-9**9**9]), "[-$inf]";
is $json->encode([sin(9**9**9)]), "[-$nan]";
is $json->encode([9**9**9/9**9**9]), "[-$nan]";

my $num = 3;
my $str = "$num";
is encode_json({test => [$num, $str]}), '{"test":[3,"3"]}';

$num = 3.21;
$str = "$num";
is encode_json({test => [$num, $str]}), '{"test":[3.21,"3.21"]}';

$str = '0 but true';
$num = 1 + $str;
is encode_json({test => [$num, $str]}), '{"test":[1,"0 but true"]}';

$str = 'bar';
{ no warnings "numeric"; $num = 23 + $str }
is encode_json({test => [$num, $str]}), '{"test":[23,"bar"]}';
