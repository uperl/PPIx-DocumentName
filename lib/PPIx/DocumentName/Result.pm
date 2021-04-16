package PPIx::DocumentName::Result;

use strict;
use warnings;
use 5.006;

# ABSTRACT: Full result set for PPIx::DocumentName
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 name

 my $name = $result->name;

Returns the name that was found in the document.

=head2 document

 my $ppi = $result->document;

Returns the L<PPI::Document> of the document.

=head2 node

 my $node = $result->node;

Returns the L<PPI::Node> where the name was found.  This will usually be either
L<PPI::Statement::Package> or L<PPI::Token::COmment>, although other types could
be used in the future.

=cut

sub _new
{
  my($class, $name, $document, $node) = @_;
  bless {
    name     => $name,
    document => $document,
    node     => $node,
  }, $class;
}

sub name     { shift->{name}     }
sub document { shift->{document} }
sub node     { shift->{node}     }

1;
