use 5.006;    # our
use strict;
use warnings;

package PPIx::DocumentName;

our $VERSION = '0.001000';

# ABSTRACT: Utility to extract a name from a PPI Document

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use PPI::Util qw( _Document );

## Exporter Interface
use Exporter 5.57 qw( import );
our @EXPORT_OK = qw( extract_docname extract_docname_via_statement extract_docname_via_comment );
sub extract_docname               { __PACKAGE__->extract(@_) }
sub extract_docname_via_statement { __PACKAGE__->extract_via_statement(@_) }
sub extract_docname_via_comment   { __PACKAGE__->extract_via_comment(@_) }

BEGIN {
  if ( $INC{'Log/Contextual.pm'} ) {
    require "Log/Contextual/WarnLogger.pm";
    my $deflogger = Log::Contextual::WarnLogger->new( { env_prefix => 'PPIX_DOCUMENTNAME', } );
    Log::Contextual->import( 'log_info', 'log_debug', 'log_trace', '-default_logger' => $deflogger );
  }
  else {
    *log_info  = sub (&) { warn $_[0]->() };
    *log_debug = sub (&) { };
    *log_trace = sub (&) { };

  }
}

## OO
sub extract_via_statement {
  my ( undef, $ppi_document ) = @_;

  # Keep alive until done
  # https://github.com/adamkennedy/PPI/issues/112
  my $dom      = _Document($ppi_document);
  my $pkg_node = $dom->find_first('PPI::Statement::Package');
  if ( not $pkg_node ) {
    log_debug { "No PPI::Statement::Package found in <<$ppi_document>>" };
    return;
  }
  if ( not $pkg_node->namespace ) {
    log_debug { "PPI::Statement::Package $pkg_node has empty namespace in <<$ppi_document>>" };
    return;
  }
  return $pkg_node->namespace;
}

sub extract_via_comment {
  my ( undef, $ppi_document ) = @_;
  my $regex = qr{ ^ \s* \#+ \s* PODNAME: \s* (.+) $ }x;    ## no critic (RegularExpressions)
  my $content;
  my $finder = sub {
    my $node = $_[1];
    return 0 unless $node->isa('PPI::Token::Comment');
    log_trace { "Found comment node $node" };
    if ( $node->content =~ $regex ) {
      $content = $1;
      return 1;
    }
    return 0;
  };

  # Keep alive until done
  # https://github.com/adamkennedy/PPI/issues/112
  my $dom = _Document($ppi_document);
  $dom->find_first($finder);

  log_debug { "<<$ppi_document>> has no PODNAME comment" } if not $content;

  return $content;
}

sub extract {
  my ( $self, $ppi_document ) = @_;
  my $docname = $self->extract_via_comment($ppi_document)
    || $self->extract_via_statement($ppi_document);

  return $docname;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PPIx::DocumentName - Utility to extract a name from a PPI Document

=head1 VERSION

version 0.001000

=head1 DESCRIPTION

This module contains a few utilities for extracting a "name" out of an arbitrary Perl file.

Typically, this is the C<module> name, in the form:

  package Foo

However, it also supports extraction of an override statement in the form:

  # PODNAME: OverrideName::Goes::Here

Which may be more applicable for documents that lack a C<package> statement, or the C<package>
statement may be "wrong", but they still need the document parsed under the guise of having a name
( for purposes such as POD )

=head1 USAGE

The recommended approach is simply:

  use PPIx::DocumentName;

  # Get a PPI Document Somehow
  return PPIx::DocumentName->extract( $ppi_document );

However, if you require multiple invocations of this, that could quickly become tiresome.

  use PPIx::DocumentName qw( extract_docname );

  return extract_docname( $ppi_document );

=head1 ALTERNATIVE NAMES

Other things I could have called this

=over 4

=item * C<PPIx::PodName> - But it isnt, because it doesnt extract from C<POD>, only returns data that may be useful B<FOR> C<POD>

=item * C<PPIx::ModuleName> - But it kinda isn't either, because its more generic than that and is tailored to extracting "a name" out of any PPI Document, and they're I<NOT> all modules.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
