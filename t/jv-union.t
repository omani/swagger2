use Mojo::Base -strict;
use Test::More;
use Swagger2::Validator;

#$SIG{__DIE__} = sub { Carp::confess($_[0]) };

my $validator = Swagger2::Validator->new;

my $schema1 = {
  type                 => 'object',
  additionalProperties => 0,
  properties           => {test => {type => ['boolean', 'integer'], required => 1}}
};

my $schema2 = {
  type                 => 'object',
  additionalProperties => 0,
  properties           => {
    test => {
      type => [
        {type => "object", additionalProperties => 0, properties => {dog => {type => "string", required => 1}}},
        {
          type                 => "object",
          additionalProperties => 0,
          properties           => {sound => {type => 'string', enum => ["bark", "meow", "squeak"], required => 1}}
        }
      ],
      required => 1
    }
  }
};

my $schema3 = {
  type                 => 'object',
  additionalProperties => 0,
  properties           => {test => {type => [qw/object array string number integer boolean null/], required => 1}}
};

my @errors = $validator->validate({test => "strang"}, $schema1);
is "@errors", "Value (strang) did not match boolean or integer.", 'boolean or integer against string';

@errors = $validator->validate({test => 1}, $schema1);
is "@errors", "", 'boolean or integer against integer';

@errors = $validator->validate({test => ['array']}, $schema1);
like "@errors", qr{Value \(ARRAY\S+ did not match boolean or integer}, 'boolean or integer against array';

@errors = $validator->validate({test => {object => 'yipe'}}, $schema1);
like "@errors", qr{Value \(HASH\S+ did not match boolean or integer}, 'boolean or integer against object';

@errors = $validator->validate({test => 1.1}, $schema1);
is "@errors", "Value (1.1) did not match boolean or integer.", 'boolean or integer against number';

@errors = $validator->validate({test => !!1}, $schema1);
is "@errors", "", 'boolean or integer against boolean';

@errors = $validator->validate({test => undef}, $schema1);
is "@errors", "Value (null) did not match boolean or integer.", 'boolean or integer against null';

@errors = $validator->validate({test => {dog => "woof"}}, $schema2);
is "@errors", "", 'object or object against object a';

@errors = $validator->validate({test => {sound => "meow"}}, $schema2);
is "@errors", "", 'object or object against object b nested enum pass';

@errors = $validator->validate({test => {sound => "oink"}}, $schema2);
like "@errors", qr{Value \(HASH\S+ did not match object or object}, 'object or object against object b enum fail';

@errors = $validator->validate({test => {audible => "meow"}}, $schema2);
like "@errors", qr{Value \(HASH.*object}, 'object or object against invalid object';

@errors = $validator->validate({test => 2}, $schema2);
like "@errors", qr{Value \(2.*object}, 'object or object against integer';

@errors = $validator->validate({test => 2.2}, $schema2);
like "@errors", qr{Value \(2\.2.*object}, 'object or object against number';

@errors = $validator->validate({test => !1}, $schema2);
like "@errors", qr{Value \(\).*object}, 'object or object against boolean';

@errors = $validator->validate({test => undef}, $schema2);
like "@errors", qr{Value \(null.*object}, 'object or object against null';

@errors = $validator->validate({test => {dog => undef}}, $schema2);
like "@errors", qr{Value \(HASH.*object}, 'object or object against object a bad inner type';

@errors = $validator->validate({test => {dog => undef}}, $schema3);
is "@errors", "", 'all types against object';

@errors = $validator->validate({test => ['dog']}, $schema3);
is "@errors", "", 'all types against array';

@errors = $validator->validate({test => 'dog'}, $schema3);
is "@errors", "", 'all types against string';

@errors = $validator->validate({test => 1.1}, $schema3);
is "@errors", "", 'all types against number';

@errors = $validator->validate({test => 1}, $schema3);
is "@errors", "", 'all types against integer';

@errors = $validator->validate({test => 1}, $schema3);
is "@errors", "", 'all types against boolean';

@errors = $validator->validate({test => undef}, $schema3);
is "@errors", "", 'all types against null';

done_testing;
