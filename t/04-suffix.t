#!perl

use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Plugin::Dispatcher;
use Dancer::Test;

set plugins => { Dispatcher => my $config = {} };

$config->{suffix} = '_request';

eval { get '/' => dispatch '#bad' };

like $@, qr/doesn't have .* \(bad_request\)/,
    'failure to configure dispatch to suffixed method';

get '/' => dispatch '#good';

sub bad { 'hopefully I never see you' }
sub good_request { 'responding to good req' }

response_content_is [GET => '/'],
    'responding to good req', '/ returned expected response';

done_testing;
