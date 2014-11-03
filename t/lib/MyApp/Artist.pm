package MyApp::Artist;

use parent 'MyApp::Base';

use Dancer ':syntax';
use Dancer::Plugin::Dispatcher;

set plugins => { Dispatcher => { services => my $services = {} } };

$services->{myapp} = {
    class => 'MyApp'
};

get '/artists/:id' =>
    dispatch 'myapp#auth', '#find', '#single';

sub new {
    bless {}, shift;
}

sub find {
    var artist => 'artist object';
    return;
}

sub single {
    return var 'artist';
}

1;
