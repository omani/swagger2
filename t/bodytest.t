use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Test::Warnings;
use File::Spec::Functions;
use t::Api;

my $json_file = 't/data/bodytest.json';

{
  use Mojolicious::Lite;
  plugin Swagger2 => {controller => 't::Api', url => $json_file};
}

my $t = Test::Mojo->new;
ok $t->app->routes->lookup('add_pet'), 'add route add_pet';
$t::Api::RES = {};

# invalid input
$t->post_ok('/api/pets' => json => {id => 123})->status_is(400)->json_is('/errors/0/message', 'Missing property.')
  ->json_is('/errors/0/path', '/pet/name');

# invalid input
$t->post_ok('/api/pets' => json => {id => "123", name => "kit-cat"})->status_is(400)
  ->json_is('/errors/0/message', 'Expected integer - got string.')->json_is('/errors/0/path', '/pet/id');

# valid input and output
$t::Api::RES = [{id => 123, name => "kit-cat"}];
$t->post_ok('/api/pets' => json => {id => 123, name => "kit-cat"})->status_is(200)->json_is('/0/id', 123);

# do it again to check if clobbered
$t->post_ok('/api/pets' => json => {id => 123, name => "kit-cat"})->status_is(200)->json_is('/0/id', 123);

# invalid output
$t::Api::RES = [{id => "123", name => "kit-cat"}];
$t->post_ok('/api/pets' => json => {id => 123, name => "kit-cat"})->status_is(500)->json_is('/errors/0/path', '/0/id')
  ->json_is('/errors/0/message', 'Expected integer - got string.');

# invalid output
$t::Api::RES = {some_parent_key => {id => "123", name => "kit-cat"}};
$t->get_ok('/api/pets' => json => {id => 123, name => "kit-cat"})->status_is(500)
  ->json_is('/errors/0/path', '/some_parent_key/id')->json_is('/errors/0/message', 'Expected integer - got string.');

# invalid output
$t::Api::RES = {};
$t->post_ok('/api/pets' => json => {id => 123, name => "kit-cat"})->status_is(500)->json_is('/errors/0/path', '/')
  ->json_is('/errors/0/message', 'Expected array - got object.');

# no output rules defined
$t::Api::CODE = 204;
$t->post_ok('/api/pets' => json => {id => 123, name => "kit-cat"})->status_is(500)->json_is('/valid', 0)
  ->json_is('/errors/0/path', '/')->json_is('/errors/0/message', 'No validation rules defined.');

done_testing;
