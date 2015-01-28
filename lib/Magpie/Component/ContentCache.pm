package Magpie::Component::ContentCache;
# ABSTRACT: Internally added content cache component

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;

__PACKAGE__->register_events( qw(cache_content));

sub load_queue { return qw( cache_content ) }


sub cache_content {
    my $self = shift;
    my $ctxt = shift;
    return OK unless $self->resource->can('cache');
    return OK if $self->has_error;
    my $content = undef;
    my $uri = $self->request->uri->as_string;
    my $cache = $self->resource->cache;
    
    if ($self->resource->has_data) {
        if ( Scalar::Util::blessed($self->resource->data) ) {
            Plack::Util::foreach($self->resource->data, sub { $content .= @_ });
        }
        else {
            $content = $self->resource->data;
        }
    }
    else {
        $content = $self->response->body;
    }

    my $cached = $cache->get($uri) || {};
    $cached->{content} = $content;
    
    # reading from response->content_type strips the 'encoding=' part?    
    $cached->{content_type} = $self->response->header('Content-Type');   
    $cached->{content_length} = $self->response->content_length;
    $cached->{last_modified} = $self->response->header('Last-Modified');   

    $cache->set($uri, $cached);
    return OK;
}

# SEEALSO: Magpie

1;
