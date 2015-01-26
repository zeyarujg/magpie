package Magpie::Resource::File;
# ABSTRACT: INCOMPLETE - Basic file Resource implementation.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Plack::App::File;

has root => (
    #traits => [ qw(MooseX::UndefTolerant::Attribute)],
    is          => 'rw',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_root {
    my $self = shift;
    warn "buildroot called";
    my $docroot = undef;
    if ( defined $self->request->env->{DOCUMENT_ROOT} ) {
        $docroot = $self->request->env->{DOCUMENT_ROOT};
    }
    else {
        $docroot = Cwd::getcwd;
    }

    return Cwd::realpath($docroot);
}

sub absolute_path {
    my $self = shift;
    return Cwd::realpath($self->root . $self->request->env->{PATH_INFO});
}

sub mtime {
    my @stat = stat(shift->absolute_path);
    return scalar @stat ? $stat[9] : -1;
}

sub content_type {
    my $self = shift;

    return $self->{CONTENT_TYPE} if $self->{CONTENT_TYPE};

    my $content_type = Plack::MIME->mime_type( $self->absolute_path ) || 'text/plain';
 
    # this is consistent /w PAF's default
    if ($content_type =~ m!^text/!) {
        $content_type .= '; charset=UTF-8';
    }

    return $content_type;
}

sub content_length {
    my $self = shift;

    return $self->{CONTENT_LENGTH} if $self->{CONTENT_LENGTH};

    my @stat = stat(shift->absolute_path);
    return scalar @stat ? $stat[7] : 0;
}

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my %paf_args = ();
    my $paf = Plack::App::File->new(root => $self->root);
    my $r = $paf->call($self->request->env);

    my %hds = @{$r->[1]};
   
    unless ( $r->[0] == 200 ) {
        use Data::Printer;
        $self->set_error({
            status_code => $r->[0],
            additional_headers => $r->[1],
            reason => join "\n", @{$r->[2]},
        });
    }
    $self->parent_handler->resource($self);
    $self->response->header('Last-Modified', 
                            $self->{LAST_MODIFIED} = $hds{'Last-Modified'} );
    $self->response->content_type( $self->{CONTENT_TYPE} = $hds{'Content-Type'} );
    $self->response->content_length( $self->{CONTENT_LENGTH} = $hds{'Content-Length'} ); 
    $self->data( $r->[2] );
    
    return OK;
}

1;

__END__
=pod

# SEALSO: Magpie, Magpie::Resource
