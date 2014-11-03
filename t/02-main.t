#!perl

use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Plugin::Dispatcher;
use Dancer::Test;

get '/' => dispatch '#greet';

sub greet { 'hello world' }

response_content_is [GET => '/'],
    'hello world', '/ returned expected response';

done_testing;
