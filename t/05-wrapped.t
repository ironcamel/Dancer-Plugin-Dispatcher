#!perl

use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Plugin::Dispatcher;
use Dancer::Test;

set plugins => { Dispatcher => my $config = {} };

$config->{prefix} = 'do_';
$config->{suffix} = '_action';

get '/' => dispatch '#index';

sub do_index_action { 'responding to request' }

response_content_is [GET => '/'],
    'responding to request', '/ returned expected response';

done_testing;
