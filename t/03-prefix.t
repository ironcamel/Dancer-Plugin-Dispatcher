#!perl

use Test::More;
use Dancer ':syntax', ':tests';
use Dancer::Plugin::Dispatcher;
use Dancer::Test;

set plugins => { Dispatcher => my $config = {} };

$config->{prefix} = 'request_';

eval { get '/' => dispatch '#bad' };

like $@, qr/doesn't have .* \(request_bad\)/,
    'failure to configure dispatch to prefixed method';

get '/' => dispatch '#good';

sub bad { 'hopefully I never see you' }
sub request_good { 'responding to good req' }

response_content_is [GET => '/'],
    'responding to good req', '/ returned expected response';

done_testing;
