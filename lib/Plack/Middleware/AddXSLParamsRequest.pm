package Plack::Middleware::AddXSLParamsRequest;

use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Request;

sub call {
    my ($self, $env) = @_; 
    my $req  = Plack::Request->new( $env );    
    my $allowed_groups = $self->{XSLParamGroups} || ['Request-Common'];

    # Slight deviation from Apache::AxKit::Plugin::AddXSLParams::Request’s
    # behavior: 'HTTPHeaders' does not imply 'Cookie'
    if ( grep { $_ eq 'HTTPHeaders' } @$allowed_groups ) {
        my $headers = $req->headers;
        foreach my $field ( $headers->header_field_names ) {
            next if lc($field) eq 'cookie';
            $req->parameters->set('request.headers.' . lc( $field ), $headers->header($field) ); 
        }
    }
    if ( grep { $_ eq 'Cookies' } @$allowed_groups ) {
        my $cookies = $req->cookies;
        foreach my $cookie ( keys(%$cookies) ) {
            $req->parameters->set('request.cookie.' . lc( $cookie ), $cookies->{$cookie});  
        }
    }
    
    # Apache::AxKit::Plugin::AddXSLParams::Request’s "Request-Common" group
    if ( grep { $_ eq 'Request-Common' } @$allowed_groups ) {

        # Deviation: set path_info independent from its length
        $req->parameters->set( 'request.uri', $env->{'psgi.input'}->uri );
        $req->parameters->set( 'request.filename',
            $env->{'psgi.input'}->filename );
        $req->parameters->set( 'request.method',
            $env->{'psgi.input'}->method );
        $req->parameters->set( 'request.path_info',
            $env->{'psgi.input'}->path_info )
            if length( $env->{'psgi.input'}->path_info ) > 0;
    }


    # Apache::AxKit::Plugin::AddXSLParams::Request’s "VerboseURI" group
    if ( grep { $_ eq 'VerboseURI' } @$allowed_groups ) {
        my $value;
        foreach my $method ( qw(scheme hostinfo user password hostname port path rpath query fragment) ) {
            $value = $req->uri->can($method) ? $req->uri->$method : '';
            $req->parameters->set('request.uri.' . $method, $value ) if length $value > 0;
        }
    }
    
    return $self->app->($env);
}


1;

__END__

=pod

=head1 SYNOPSIS

   enable "AddXSLParamsRequest";  # defaults to the 'Request-Common' group

   # activate all groups 
   enable "AddXSLParamsRequest", XSLParamGroups => ['Request-Common', 'VerboseURI', 'HTTPHeaders', 'Cookies'];

=head ABSTRACT

   A reincarnation of Apache::AxKit::Plugin::AddXSLParams::Request for use with Magpie::Transformer::XSLT.

=cut

