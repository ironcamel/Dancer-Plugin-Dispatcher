# ABSTRACT: Simple yet Powerful Controller Class dispatcher for Dancer

package Dancer::Plugin::Dispatcher;

# VERSION

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Dispatcher;

    get '/'          => dispatch '#index';
    get '/login'     => dispatch '#login';
    get '/dashboard' => dispatch '#check_session', '#dashboard';

    dance;
    
    # or alternatively, define routes in your config file

    use Dancer;
    use Dancer::Plugin::Dispatcher; # in your scripts

    dance;

=head1 DESCRIPTION

This Dancer plugin provides a simple mechanism for dispatching code in
controller classes which allows you to better separate and compartmentalize
your Dancer application. This plugin is a great building block towards giving
your Dancer application an MVC architecture.

=head1 CONFIGURATION

Configuration details will be optionally grabbed from your L<Dancer> config file
although no configuration is neccessary.
For example: 

    plugins:
      Dispatcher:
        base: MyApp::Controller

If no configuration information is given, this plugin will attempt to use the
calling (or main) namespace to dispatch code from. If the base option is supplied
with the configuration, this plugin will load that class and all sub classes for
your convenience.

Alternatively, you may can specify your routes and handlers in your L<Dancer>
config file.

For example: 

    plugins:
      Dispatcher:
        base: MyApp::Controller
        routes:
          - "any / > #index"
          - "get /dashboard > #check_session,#dashboard"
          - "get,post /login > #login"
          - "get,post /logout > #logout"

In action method can have a prefix and/or a suffix. For example:

    plugins:
      Dispatcher:
        base: MyApp::Controller
        prefix: do_
        suffix: _action

    get '/'          => dispatch '#index';
    sub do_index_action { ... }

=head1 METHODS

=head2 dispatch

This method takes a shortcut and returns a coderef. The shortcut represents a
controller and action (package and sub-routine). The coderef returned wraps that
package and sub-routine to be executed by Dancer. The following is the shortcut
translation map:

    The '#' character is used to separate the controller and action, same as
    RoR and Mojolicious, e.g. (controller#action).
    
    dispatch '#index'; -> Dispatches main->index or MyApp::Controller->index
    where MyApp::Controller is the value of base in your plugin configuration.
    
    dispatch 'event#log'; -> Dispatches main::Event->log or
    MyApp::Controller::Event->log.
    
    dispatch 'post-event#log'; -> Dispatches main::Post::Event->log or
    MyApp::Controller::Post::Event->log.

    dispatch 'post_event#log'; -> Dispatches main::PostEvent->log or
    MyApp::Controller::PostEvent->log.
    
Another benefit in using this plugin is a better method of chaining actions.
The current method of chaining suggests that you create a catch-all* route
which you then you to perform some actions then pass the request to the next
matching route forcing you to use mega-splat and re-parse routes to find the
next match.

Chaining actions with this plugin only requires you to supply multiple shortcuts
to the dispatch keyword:

    get '/secured' => dispatch '#chkdomain', '#chksession', '#secured';
    
    sub chkdomain {
        return undef if param(domain);
        return 'Chain broken, domain is missing!';
    }
    
    sub chksession {
        return undef if session('user');
        return redirect '/'; # maybe flash session timed-out message
    }
    
    sub secured {
        return 'You made it, Joy';
    }
    
If it isn't obvious, when chaining, the dispatch keyword takes multiple
shortcuts and returns a coderef that will execute them sequentially. The first
action to return content or issue a 3xx series redirect will break the chain.

=cut

use Modern::Perl;
use Carp;
use Dancer qw/:syntax/;
use Dancer::Plugin;
use Class::Load qw/load_class/;

# automation ... sorta

our $classes;

sub dispatcher {
    return unless config->{plugins};
    
    our $cfg   = config->{plugins}->{Dispatcher};
    our $base  = $cfg->{base};
    our $prefix = $cfg->{prefix} || '';
    our $suffix = $cfg->{suffix} || '';
    
    # check for a base class in the configuration
    if ($base) {
        load_class($base);
    } else {
        ($base) = caller(0);
        $base ||= 'main';
    }
    
    sub BUILDCODE {

        my $code ;

        # define the input
        my $shortcut = shift;
        
        # format the shortcut
        my ($class, $action) = split /#/, $shortcut;
        if ($class) {
            # run through the filters
            $class = ucfirst $class;
            $class =~ s{-(.)}{::\u$1}g;
            $class =~ s{_(.)}{\u$1}g;
            
            # prepend base to class if applicable
            $class = join "::", $base, $class if $base;
        } else {
            $class = $base if $base;
        }
        
        $action = $prefix.$action.$suffix;
        
        # build the return code (+chain if specified)
        $code = sub {
            debug "dispatching $class -> $action";
            if (exists $classes->{$class}) {
                croak "action $action not found in class $class" unless $classes->{$class}->can($action);
                $classes->{$class}->$action(@_);
            } else {
                load_class($class);
                croak "action $action not found in class $class" unless $class->can($action);
                $class->$action(@_) if $class && $action;
            }
        };
        
        return $code;
    }
    
    my @codes = map { BUILDCODE($_) } @_;
    my $code = sub {
        my @args = @_;
        my $data ;
        foreach my $code (@codes) {
            
            # HOW I WISH IT COULD WORK
            #-- break if content is set
            #-- last if Dancer::SharedData->response->content;
            
            # HOW IT MUST WORK
            # execute code
            # break if content is returned or
            # if redirect was issued
            $data = $code->(@args);
            last if $data || Dancer::SharedData->response->status =~ /^3\d\d$/;
        }
        return $data ;
    };
    
    return $code;
}

sub auto_dispatcher {
    return unless config->{plugins};
    
    our $cfg = config->{plugins}->{Dispatcher};
    foreach my $route (@{$cfg->{routes}}) {
        my $re = qr/([a-z,]+) *([^\s>]+) *> *(.*)/;
        my ($m, $r, $s) = $route =~ $re;
        foreach my $i (split /,/, $m) {
            if ($i && $r && $s) {
                my $c = dispatcher(split(/[\s,]/, $s));
                if ($i eq 'get') {
                    Dancer::App->current->registry->universal_add($_, $r, $c)
                    for ('get', 'head')
                }
                else {
                    Dancer::App->current->registry->universal_add($i, $r, $c)
                }
            }
        }
    }
}

register dispatch => \&dispatcher;

=head2 boot_classes

This methods boots specifed classes and will use them when possible. Classes are instanciated via C<new()>.

    plugins:
      Dispatcher:
        base: MyApp::Controller
        boot:
          MyApp::Controller:
            - 1
            - 2
            - 3
    
    sub new { my ($one, $two, $three) = @_; bless ... }
    sub index { my $self = shift; ... }
    
    boot_classes;
    get '/'          => dispatch '#index';

This also works great with frameworks like L<Moose>.

I<boot_classes> takes optional arguments; they are the same as in the plugin configuration:

    boot_classes(
        'MyApp::Controller' => [ 1, 2, 3 ]
    );

=cut

register boot_classes => sub {
    return unless config->{plugins};

    our $cfg = config->{plugins}->{Dispatcher};
    
    my %def = (%{$cfg->{boot}}, @_);
    
    foreach my $class (keys %def) {
        load_class($class);
        debug "instanciate class $class";
        $classes->{$class} = $class->new(@{$def{$class}});
    }
};

register_plugin;
auto_dispatcher;

1;
