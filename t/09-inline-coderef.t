#!perl

use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Plugin::Dispatcher;
use Dancer::Test;

get '/' => dispatch '#stash1', '#stash2', sub { var stash3 => 3 }, '#destination';

sub stash1 { var stash1 => 1; }
sub stash2 { var stash2 => 2; }

sub destination { join ' ', 'data contains', map var("stash$_"), 1..3 }

response_content_is [GET => '/'], 'data contains 1 2 3',
    '/ returned expected response';

done_testing;
