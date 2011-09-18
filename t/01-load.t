#!perl

package MyApp;

use Test::More tests => 3, import => ['!pass'];;

BEGIN {
    use_ok 'Dancer', ':syntax';
    use_ok 'Dancer::Plugin::Dispatcher';
}

sub greet {
    'Hello World'
}

my $action = dispatch '#greet';
ok 'Hello World' eq $action->(), 'Dancer::Plugin::Dispatcher is ok';

1;