package MyApp;

use Dancer ':syntax';
use Dancer::Plugin::Dispatcher;

set plugins => { Dispatcher => { base => 'MyApp', prefix => 'do_', suffix => '_action' } };

sub do_index_action {
    'Hello World';
}

sub do_setup_action {
    var 'chainsaw' => 1;
    return undef;    # pass down the chain
}

sub do_switch_action {
    redirect '/index';
}

get '/index'          => dispatch '#index';
get '/download/:file' => dispatch 'resource#dlfile';
get '/chainsaw'       => dispatch '#setup', 'resource#chainsaw';
get '/redirect'       => dispatch '#switch', 'resource#dlfile';
get '/error'          => dispatch '#undefined';

package MyApp::Resource;

use Dancer ':syntax';

sub do_dlfile_action {
    'File Downloaded';
}

sub do_chainsaw_action {
    'Got Chainsaw' if vars->{chainsaw};
}

1;
