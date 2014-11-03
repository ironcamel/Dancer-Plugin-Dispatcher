#!perl

use Test::More;

BEGIN {
    use_ok 'Dancer', ':syntax';
    use_ok 'Dancer::Plugin::Dispatcher';
}

done_testing;
