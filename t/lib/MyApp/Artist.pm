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

get '/artists/report/vars' =>
    dispatch 'myapp#auth', '#find', '#single', '#report';

sub find {
    var find_arg1 => ref shift;
    var artist    => 'artist object';
    return;
}

sub single {
    var single_arg1 => ref shift;
    return var 'artist';
}

sub report {
    return join ' ', var('find_arg1'), var('single_arg1');
}

1;
