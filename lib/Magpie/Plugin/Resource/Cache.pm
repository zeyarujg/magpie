package Magpie::Plugin::Resource::Cache;
use Moose::Role;

# ABSTRACT: A Role to add Caching to a Resource;
#
use Magpie::Constants;

requires qw(mtime);

has cache => (
    is          => 'ro',
    lazy_build  => 1,
);


sub stale {
    my $deps = shift;
    my @stat;
    foreach (keys %{$deps} ) {
        @stat = stat($_);
        next if scalar @stat and $stat[9] == $deps->{$_}->{mtime};
        warn "Stale: $_\n";
        return 1;
    }
    return 0;
}
    
around 'GET' => sub {
    my $orig = shift;
    my $self = shift;
    my $mtime = $self->mtime;
    my $content_type = $self->content_type;
    my $uri = $self->request->uri->as_string;

    if ( $mtime && $mtime > 0 ) {
        my $data = $self->cache->get($uri);
        #use Data::Printer;
        #warn "Cached: $uri\n\n" . p($data);
        if ($data && defined $data->{resource} 
                  && defined defined $data->{resource}->{mtime} 
                  && $mtime == $data->{resource}->{mtime} 
                  && !stale( $data->{resource}->{dependencies} ) ) {
            warn "Serving cached '$uri'\n";
            my $content = $data->{content};
            $self->data($content);
            $self->response->content_type( $data->{content_type} );
            $self->response->content_length( $data->{content_length} );
            $self->response->header( 'Last-Modified' => $data->{last_modified} );
            $self->response->header( 'X-Magpie-Cache-Hit' => 'Aye!' );
            return DONE;
        }
        else {
            warn "Set cache '$uri'\n";
            # actual content will be added at the end of the pipeline process
            my $data = { content => '', resource => { mtime => $mtime, }};
            $self->cache->set($uri, $data);
            $self->parent_handler->add_handler('Magpie::Component::ContentCache');
            $self->response->header( 'X-Magpie-Cache-Hit' => 'Nay!' );
        }
    }

    return $self->$orig(@_);
};

after [qw(add_dependency delete_dependency)] => sub {
    my $self = shift;
    my $uri = $self->request->uri->as_string;
    my $data = $self->cache->get($uri);

    unless ( $data ) {
        $data = {};
    }

    $data->{resource}->{dependencies} = $self->dependencies;

    $self->cache->set($uri, $data);
};

1;
