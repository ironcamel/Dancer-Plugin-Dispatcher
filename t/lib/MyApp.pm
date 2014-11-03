package MyApp;

use Dancer ':syntax';
use Dancer::Plugin::Dispatcher;

get '/auth' => dispatch '#auth';

sub new {
    bless {}, shift;
}

sub auth {
    return; # pass-thru
}

1;
