package MyAppAuto;

use Dancer ':syntax';
use Dancer::Plugin::Dispatcher;

set plugins => {
    Dispatcher => {
        base   => 'MyApp',
        routes => [
            "get /index          > #index",
            "get /download/:file > resource#dlfile",
            "get /chainsaw       > #setup resource#chainsaw",
            "get /redirect       > #switch resource#dlfile"
        ]
    }
};

dispatch_auto;

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

package MyAppAuto::Resource;

use Dancer ':syntax';

sub dlfile {
    'File Downloaded';
}

sub chainsaw {
    'Got Chainsaw' if vars->{chainsaw};
}

1;
