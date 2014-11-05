# ABSTRACT: Controller Class Dispatching System for Dancer
package Dancer::Plugin::Dispatcher;

use Beam::Wire;
use Dancer::Plugin;

use Dancer ':syntax';

# VERSION

my %handlers;
my %services;

register dispatch => sub {
    my $config = plugin_setting;
    my ($self, @directions) = plugin_args(@_);

    my $caller    = caller(0) // 'main';
    my $container = Beam::Wire->new(config => $config->{services} // {});
    my $prefix    = $config->{prefix} // '';
    my $suffix    = $config->{suffix} // '';
    my $handlers  = [];

    for my $direction (@directions) {
        next if 'CODE' eq ref $direction;
        next if $handlers{$caller}{$direction};

        my ($service, $method) = split /#/, $direction;

        my $object = bless {}, $caller;
        $object = $services{$service} //= $container->get($service) if $service;
        $method = join '', $prefix, $method, $suffix;

        my $class = ref $object;
        my $code  = $object->can($method)
            or die "Class ($class) doesn't have method ($method)";

        $handlers{$caller}{$direction} = {
            class   => $class,
            service => $service,
            object  => $object,
            method  => $method,
            code    => $code,
        };
    }

    return sub {
        my @args = @_;
        my ($data, $invocant);
        for my $direction (@directions) {
            my $is_code = 'CODE' eq ref $direction;
            my $handler = $is_code ? {} : $handlers{$caller}{$direction};
            my $coderef = $is_code ? $direction : $handler->{code};
            my $class   = $handler->{class};
            my $object  = $handler->{object};
            my $service = $handler->{service};
            my $method  = $handler->{method};

            # make best effort to pass an invocant
            if ($service or $class) {
                $invocant = $object // $class;
                unshift @args, $invocant if $invocant;
                # dispatch log message
                debug "Dispatching to class ($class) and method ($method)"
                    . $service ? " using service ($service)" : "";
            } else {
                # dispatch log message
                debug "Dispatching to anonymous inline code reference";
            }

            $data = $coderef->(@args);

            # the dispatch chain will be broken and return immediately if a 3xx
            # series redirect is issued or if execution is explicitly halted
            if (my $response = Dancer::SharedData->response) {
                last if $response->status =~ /^3/; # redirect
                last if $response->halted; # halted
            }
        }
        return $data;
    }
};

register_plugin for_versions => [1, 2];

=encoding utf8

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Dispatcher;

    get '/login'     => dispatch '#login';
    get '/dashboard' => dispatch '#check_session', '#dashboard';

    sub login {
        halt 'Unauthorized' unless login_okay scalar params;
        redirect '/dashboard';
    }

    sub check_session {
        var sessions => generate_session;
    }

    sub dashboard {
        template 'dashboard';
    }

    dance;

=head1 DESCRIPTION

Dancer::Plugin::Dispatcher provides a mechanism for dispatching HTTP requests to
controller classes allowing you to better separate and compartmentalize your
L<Dancer> application. This simple approach is a building block towards giving
your Dancer application a more scalable MVC architecture. B<Note: This is an
early release available for testing and feedback and as such is subject to
change. The latest release of this distribution breaks backwards compatibility
with version 0.12 or anything prior.> This plugin leverages dependency injection
to load the objects that the HTTP requests will be dispatched to. The invesion
of control container is provided by L<Beam::Wire> which supports various
patterns for dynamically loading controllers.

=head1 CONFIGURATION

Configuration details will be optionally grabbed from your L<Dancer> config file
although no configuration is neccessary. For example:

    plugins:
      Dispatcher:
        services:
            artists:
                class: MyApp::Artist
            albums:
                class: MyApp::Album
            songs:
                class: MyApp::Song

If no configuration information is given, this plugin will attempt to use the
calling (or main) namespace as the controller where requests will be dispatched.
Controller methods can have a prefix and/or a suffix automatically applied
before dispatch. For example:

    plugins:
        Dispatcher:
            prefix: do_
            suffix: _action
            services:
                artists:
                    class: MyApp::Artist
                albums:
                    class: MyApp::Album
                songs:
                    class: MyApp::Song

The prefix and suffix values are optional and will be applied be resolving the
controller dispatch chain.

    get '/' => dispatch '#index'; # will execute do_index_action

=method dispatch

This method takes a string, referred to as a dispatch string, and returns a
coderef. The dispatch string represents a controller service and action. The
controller service is a L<Beam::Wire> service container configuration. All
controller services should be specified under the services property in the
plugin configuration. The controller service action is a method on the object
which the service loads. The following are the dispatch string semantics:

    plugins:
        Dispatcher:
            services:
                artists:
                    class: MyApp::Artist

    The '#' character is used to separate the controller service name and
    action (method): e.g. (service#action).

    dispatch '#index'; -> dispatches main->index or caller->index
    where caller is the namespace of whichever package loads the plugin

    dispatch 'artists#find'; # dispatches MyApp::Artist->new->find
    dispatch 'artists#single'; # dispatches MyApp::Artist->new->single

Another benefit in using this plugin is a better method of chaining actions.
The current method of chaining suggests that you create a catch-all* route
which you then use to perform some actions then pass the request to the next
matching route forcing you to use mega-splat and re-parse routes to find the
next match.

Chaining actions with this plugin only requires you to supply multiple dispatch
strings to the dispatch keyword:

    get '/secured' => dispatch '#check_session', '#secured';

    sub chksession {
        return redirect '/' unless session 'user';
    }

    sub secured {
        template 'secured';
    }

If it isn't obvious, when chaining, the dispatch keyword takes multiple
dispatch strings and returns a coderef that will execute them sequentially. The
first action to explicitly halt execution, by calling Dancer's halt keyword, or
issue a 3xx series redirect will break the dispatch chain.

=cut
