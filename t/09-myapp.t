#!perl

use lib 't/lib';

use Test::More;
use Dancer::Test;

use MyApp;
use MyApp::Artist;

response_content_is [GET => '/artists/1'],
    'artist object', '/ returned expected response';

done_testing;
