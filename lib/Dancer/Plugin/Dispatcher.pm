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

=head1 DESCRIPTION

This Dancer plugin provides a simple mechanism for dispatching code in
controller classes which allows you to better seperate and compartmentalize
your Dancer application. This plugin is a great building block towards giving
your Dancer application an MVC architecture.

=head1 CONFIGURATION

Configuration details will be optionally grabbed from your L<Dancer> config file.
For example: 

    plugins:
      Dispatcher:
        base: MyApp::Controller

If no configuration information is given, this plugin will attempt to use the
calling (or main) namespace to dispatch code from. If the base option is supplied
with the configuration, this plugin will load that class and all sub classes for
your convenience.

=head1 METHODS

=head2 dispatch

This method takes a shortcut and returns a coderef. The shortcut represents a
controller and action (package and sub-routine). The coderef returned wraps that
package and sub-routine to be executed by Dancer. The following is the shortcut
translation map:

    The '#' character is used to seperate the controller and action, same as
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
matching route forcing you to use mega-splat and reparse routes to find the next
match.

Chaining actions with this plugin only requires you to supply multiple shartcuts
to the dispatch keyword:

    get '/secured' => dispatch '#chkdomain', '#chksession', '#secured';
    
    sub chkdomain {
        return undef unless ! param(domain);
        return 'Chain broken, domain is missing!';
    }
    
    sub chksession {
        return undef unless ! session('user');
        return redirect '/'; # maybe flash session timed-out message
    }
    
    sub secured {
        return 'You made it, Joy';
    }
    
If it isn't obvious, when chaining, the dispatch keyword takes multiple
shortcuts and returns a coderef that will execute them sequentially. The first
action to return content or issue a 3xx series redirect will break the chain.

=cut

use strict;
use warnings;
use Dancer qw/:syntax/;
use Dancer::Plugin;
use Module::Find;

our $CONTROLLERS ;

sub dispatcher {
    our $cfg   = plugin_setting;
    our $base  = $cfg->{base};
    
    # check for a base class in the configuration
    if ($base) {
        unless ($CONTROLLERS) {
            my  $base_file = $base;
                $base_file =~ s/::/\//gi;
                $base_file .= '.pm';
                
            eval "require $base" unless $INC{$base_file};
            $CONTROLLERS = [useall $base];
        }
    }
    else {
        ($base) = caller(1); $base ||= 'main';
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
            $class =~ s/([a-z])\-([a-z])/$1::\u$2/gpi;
            $class =~ s/([a-z])\_([a-z])/$1\u$2/gpi;
            
            # prepend base to class if applicable
            $class = join "::", $base, $class if $base;
        }
        else {
            
            $class = $base if $base;
        }
        
        # build the return code (+chain if specified)
        $code = sub {
            debug lc "dispatching $class -> $action";
            $class->$action(@_) if $class && $action;
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

register dispatch       => sub { dispatcher @_ };
register_plugin;

1;
