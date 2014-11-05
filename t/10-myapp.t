#!perl

use lib 't/lib';

use Test::More;
use Dancer::Test;

use MyApp;
use MyApp::Artist;

response_content_is [GET => '/artists/1'],
    'artist object', '/artists/1 returned expected response';

response_content_is [GET => '/artists/report/vars'],
    'MyApp::Artist MyApp::Artist', '/artists/report/vars returned expected response';

done_testing;
