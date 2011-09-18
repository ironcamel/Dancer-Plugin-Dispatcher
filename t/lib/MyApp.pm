package MyApp;

use Dancer ':syntax';
use Dancer::Plugin::Dispatcher;

set plugins => { Dispatcher => { base => 'MyApp' } };

sub index {
    'Hello World';
}

sub setup {
    var 'chainsaw' => 1;
    return undef;    # pass down the chain
}

sub switch {
    redirect '/index';
}

get '/index'          => dispatch '#index';
get '/download/:file' => dispatch 'resource#dlfile';
get '/chainsaw'       => dispatch '#setup', 'resource#chainsaw';
get '/redirect'       => dispatch '#switch', 'resource#dlfile';

package MyApp::Resource;

use Dancer ':syntax';

sub dlfile {
    'File Downloaded';
}

sub chainsaw {
    'Got Chainsaw' if vars->{chainsaw};
}

1;
