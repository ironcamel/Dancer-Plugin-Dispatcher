#!perl

use Test::More tests => 6, import => ['!pass'];
use Dancer::Test;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/lib";
    use_ok 'MyApp';
}

response_content_is [GET => '/index'], 
    'Hello World', '/index returned Hello World';
    
response_content_is [GET => '/download/test.txt'], 
    'File Downloaded', '/download/test.txt returned File Downloaded';
    
response_content_is [GET => '/chainsaw'], 
    'Got Chainsaw', '/chainsaw returned Got Chainsaw';
    
response_content_is [GET => '/redirect'], 
    '', '/redirect returned Nothing, chain broken as expected';

read_logs;
dancer_response GET => '/error';
like(read_logs()->[1]->{message}, qr{\Qrequest to GET /error crashed: action do_undefined_action not found in class MyApp\E});

1;