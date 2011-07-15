package Loader;
use strict;
use warnings;
use parent qw( Exporter );
our @EXPORT = qw( machine match match_env);
use Scalar::Util qw(reftype blessed);

use Data::Dumper::Concise;

our @pipeline = ();
our $OM = our $current = [
    [ undef, undef, undef, undef, [] ]
];
our @stack = ();

sub add_to_pipe {
    push @pipeline, @_;
}

sub machine (&) {
    my $block = shift;
    $block->();
    #return ();
    return @stack;

#     push @pipeline, $current;
#     return @pipeline;
#    return $current;
}

our $nested = undef;
my $depth = 0;

sub match {
    my $to_match = shift;
    my $input    = shift;
    warn "IN " . Dumper($to_match, \@_ ) . "--------\n";
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input];
    push @stack, $frame;
}

sub match_env {
    my $to_match = shift;
    my $input    = shift;
    warn "ENVIN " . Dumper($to_match, \@_ ) . "--------\n";
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input];
    push @stack, $frame;
}

1;
=cut

sub match {
    my $to_match = shift;
    my $input    = shift;
    my @extra = @_;
    warn "IN " . Dumper($to_match, $input, \@extra) . "--------\n";
    my $match_type   = reftype $to_match || 'STRING';
    #my $add_type     = undef;
    #my $handler_list = undef;
    my $add_type = reftype $input;
    my $frame = [$match_type, $to_match, $input, \@extra];
    push @stack, $frame unless scalar @extra;
    return $frame;

my @children = ();
#     if ( scalar @to_add > 1 ) {
#         warn "LIST " . Dumper($to_match, \@to_add ) . "******\n";
#         my $handler_list = $to_add[0];
#         my $add_type = reftype $handler_list;
#         @children = splice(@to_add, 1,-1 );
#         warn "yeah? " . Dumper(\@children);
#      }
#
#      my $frame = [ $match_type, $to_match, $handler_list, \@children ];
#      $current = $frame;
#      return @$frame;
#
#     if ( ! defined $add_type ) {
#         #warn "MAGIC $to_match\n";
#         my $t = shift @stack;
#         push @{$frame->[3]}, $t;
#         push @stack, $frame;
#         $depth++;
#         return undef;
#     }
#     else {
#         $frame->[2] = $handler_list;
#         $depth--;
#         push @stack, $frame;
#         return $to_match;
#     }
#     my $frame = [ $match_type, $to_match, $add_type, undef, [] ];
#     if ( reftype $to_add[0] == undef ) {
#         $frame->[2] = 'PARENT';
#     }
#     else {
#         $frame->[2] = reftype $to_add[0];
#         $frame->[3] = $to_add[0];
#     }
#    push @pipeline, $frame;
    #return $frame;
}

1;