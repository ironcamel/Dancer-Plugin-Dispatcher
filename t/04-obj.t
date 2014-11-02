#!perl

use Test::More tests => 3, import => ['!pass'];
use Dancer::Test;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/lib";
    use_ok 'MyAppObj';
}

response_content_is [GET => '/incr'], 
    '1', '/incr returned 1';
    
response_content_is [GET => '/incr'], 
    '2', '/incr returned 2';
    
1;