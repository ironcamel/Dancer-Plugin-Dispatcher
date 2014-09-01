package MyAppObj;

BEGIN {
    use Dancer ':syntax';
	set plugins => {
		Dispatcher => {
			base => 'MyAppObj',
			boot => {
				MyAppObj => [ { i => 0 } ]
			}
		}
	};
}

use Dancer::Plugin::Dispatcher;

sub new {
	my ($class, $config) = @_;
	return bless $config => ref $class || $class;
}

sub incr {
	my $self = shift;
	++$self->{i};
}

boot_classes;

get '/incr' => dispatch '#incr';

1;
