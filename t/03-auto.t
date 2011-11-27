#!perl

use Test::More tests => 7, import => ['!pass'];
use Dancer::Test;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/lib";
    use_ok 'MyAppAuto';
}

response_content_is [GET => '/'], 
    'Hello World', '/ returned Hello World';
    
response_content_is [POST => '/'], 
    'Hello World', '/ returned Hello World';

response_content_is [GET => '/index'], 
    'Hello World', '/index returned Hello World';
    
response_content_is [GET => '/download/test.txt'], 
    'File Downloaded', '/download/test.txt returned File Downloaded';
    
response_content_is [GET => '/chainsaw'], 
    'Got Chainsaw', '/chainsaw returned Got Chainsaw';
    
response_content_is [GET => '/redirect'], 
    '', '/redirect returned Nothing, chain broken as expected';

1;