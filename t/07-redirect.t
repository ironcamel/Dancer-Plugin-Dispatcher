#!perl

use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Plugin::Dispatcher;
use Dancer::Test;

get '/' => dispatch '#stash1', '#stash2', '#intercept', '#destination';
get '/next' => sub { 'data contains 3 4' };

sub stash1 { var stash1 => 1; }
sub stash2 { var stash2 => 2; }

sub intercept { redirect '/next' }
sub destination { join ' ', 'data contains', var('stash1'), var('stash2') }

response_content_is [GET => '/'], '', '/ returned expected response';

done_testing;
