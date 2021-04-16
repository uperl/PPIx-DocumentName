use 5.006;    # our
use strict;
use warnings;

package PPIx::DocumentName;

# ABSTRACT: Utility to extract a name from a PPI Document
# VERSION

use PPI::Util qw( _Document );

=for Pod::Coverage log_info log_debug log_trace
=cut

sub log_info(&@);
sub log_debug(&@);
sub log_trace(&@);

my %callers;

BEGIN {
  if ( $INC{'Log/Contextual.pm'} ) {
    ## Hide from autoprereqs
    require 'Log/Contextual/WarnLogger.pm';    ## no critic (Modules::RequireBarewordIncludes)
    my $deflogger = Log::Contextual::WarnLogger->new( { env_prefix => 'PPIX_DOCUMENTNAME', } );
    Log::Contextual->import( 'log_info', 'log_debug', 'log_trace', '-default_logger' => $deflogger );
  }
  else {
    require Carp;
    *log_info  = sub (&@) { Carp::carp( $_[0]->() ) };
    *log_debug = sub (&@) { };
    *log_trace = sub (&@) { };
  }
}

sub import {
  my(undef, %args) = @_;
  if(defined $args{'-api'}) {
    if($args{'-api'} != 0 && $args{'-api'} != 1) {
      Carp::croak("illegal api level: $args{'-api'}");
    }
    if($] < 5.010) {
      my($package) = caller;
      $callers{$package} = $args{'-api'};
      require Carp;
      Carp::carp("Because of the age of your Perl, -api $args{'-api'} " .
                 'will be package scoped instead of block scoped. ' .
                 'Please upgrade to 5.10 or better.');
    } else {
      $^H{'PPIx::DocumentName/api'} = $args{'-api'};  ## no critic (Variables::RequireLocalizedPunctuationVars)
    }
  }
}

sub _api {
  my ( $api ) = @_;
  if($] < 5.010)
  {
    my($package) = caller 1;
    $api = $callers{$package} unless defined $api;
  }
  else
  {
    my $hh = (caller 1)[10];
    $api = $hh->{'PPIx::DocumentName/api'} if defined $hh && !defined $api;
  }
  $api = 0 unless defined $api;
  return $api;
}

sub _result {
  my($name, $ppi_document, $node) = @_;
  require PPIx::DocumentName::Result;
  PPIx::DocumentName::Result->_new($name, $ppi_document, $node);  ## no critic (Subroutines::ProtectPrivateSubs)
}

## OO

=method extract

  my $docname = PPIx::DocumentName->extract( $ppi_document );

This will first attempt to extract a name via the C<PODNAME: > comment notation,
and then fall back to using a C<package Package::Name> statement.

C<$ppi_document> is ideally a C<PPI::Document>, but will be auto-up-cast if it is
any of the parameters C<< PPI::Document->new() >> understands.

=cut

sub extract {
  my ( $self, $ppi_document ) = @_;

  if (_api(undef)) {
    my @result = $self->extract_via_comment($ppi_document, 1);
    @result = $self->extract_via_statement($ppi_document, 1) unless defined $result[0];
    return wantarray ? @result : $result[0];
  } else {
    my $result = $self->extract_via_comment($ppi_document, 0) || $self->extract_via_statement($ppi_document, 0);
    return $result;
  }
}

=method extract_via_statement

  my $docname = PPIx::DocumentName->extract_via_statement( $ppi_document );

This only extract C<package Package::Name> statement based document names.

C<$ppi_document> is ideally a C<PPI::Document>, but will be auto-up-cast if it is
any of the parameters C<< PPI::Document->new() >> understands.

=cut

sub extract_via_statement {
  my ( undef, $ppi_document, $api ) = @_;

  $api = _api($api);

  # Keep alive until done
  # https://github.com/adamkennedy/PPI/issues/112
  my $dom      = _Document($ppi_document);
  my $pkg_node = $dom->find_first('PPI::Statement::Package');
  if ( not $pkg_node ) {
    log_debug { "No PPI::Statement::Package found in <<$ppi_document>>" };
    # The old API was inconsistant here, for just this method, returns
    # empty list on failure.  This is unfortunately different from
    # extract_via_comment.
    return 0 == $api ? () : wantarray ? (undef,undef) : undef;
  }
  if ( not $pkg_node->namespace ) {
    log_debug { "PPI::Statement::Package $pkg_node has empty namespace in <<$ppi_document>>" };
    return 0 == $api ? () : wantarray ? (undef,undef) : undef;
  }
  my $name = $pkg_node->namespace;
  return 1 == $api && wantarray ? ($name, _result($name, $dom, $pkg_node)) : $name;
}

=method extract_via_comment

  my $docname = PPIx::DocumentName->extract_via_comment( $ppi_document );

This will only extract C<PODNAME: > comment based document names.

C<$ppi_document> is ideally a C<PPI::Document>, but will be auto-up-cast if it is
any of the parameters C<< PPI::Document->new() >> understands.

=cut

sub extract_via_comment {
  my ( undef, $ppi_document, $api ) = @_;

  $api = _api($api);
  my $node;

  my $regex = qr{ ^ \s* \#+ \s* PODNAME: \s* (.+) $ }x;    ## no critic (RegularExpressions)
  my $content;
  my $finder = sub {
    my $maybe = $_[1];
    return 0 unless $maybe->isa('PPI::Token::Comment');
    log_trace { "Found comment node $maybe" };
    if ( $maybe->content =~ $regex ) {
      $content = $1;
      $node = $maybe;
      return 1;
    }
    return 0;
  };

  # Keep alive until done
  # https://github.com/adamkennedy/PPI/issues/112
  my $dom = _Document($ppi_document);
  $dom->find_first($finder);

  log_debug { "<<$ppi_document>> has no PODNAME comment" } if not $content;

  return 1 == $api && wantarray ? ($content, defined $content ? _result($content, $dom, $node) : undef) : $content;
}

1;
__END__
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

=head1 CAVEATS

Under the older API (C<< -api => 0 >>; the default), C<extract_via_statement>, unlike the other
methods in this module, returns empty list instead of undef when it does find a name.  When
using the newer API (C<< -api => 1 >>), calls are consistent in scalar and list context.  New
code should therefore use the newer API.

=head1 ALTERNATIVE NAMES

Other things I could have called this

=over 4

=item * C<PPIx::PodName> - But it isn't, because it doesn't extract from C<POD>, only returns data that may be useful B<FOR>
C<POD>

=item * C<PPIx::ModuleName> - But it kinda isn't either, because its more generic than that and is tailored to extracting
"a name" out of any PPI Document, and they're I<NOT> all modules.

=back

=head1 SIMILAR MODULES

Modules that are perceptibly similar to this ones tasks ( but are subtly different in important ways ) are as follows:

=over 4

=item * L<< C<Module::Metadata>|Module::Metadata >> - Module::Metadata does a bunch of things this module explicitly doesn't
want or need to do, and it lacks a bunch of features this module needs.

Module::Metadata is predominantly concerned with extracting I<ALL> name spaces and I<ALL> versions from a module for the
purposes of indexing and indexing related tasks. This also means it has a notion of "hideable" name spaces with the purpose
of hiding them from C<CPAN>.

Due to being core as well, it is not able to use C<PPI> for its features, so the above concerns mean it is also mostly
based on careful regex parsing, which can easily be false tripped on miscellaneous in document content.

Whereas C<PPIx::DocumentName> only cares about the I<first> name of a given class, and it cares much more about nested
strings being ignored intentionally. It also has a motive to show names I<even> for documents that won't be indexed
( And C<Module::Metadata> has no short term plans on exposing hidden document names ).

C<PPIx::DocumentName> also has special logic for the C<PODNAME: > declaration, and may eventually support other
mechanisms for extracting a name from "a document", which will be not in C<Module::Metadata>'s collection of desired
use-cases.

=item * L<< C<Module::Extract::Namespaces>|Module::Extract::Namespaces >> - This is probably closer to
C<PPIx::DocumentName>'s requirements, using C<PPI> to extract content.

Most of C<Module::Extract::Namespaces>'s code seems to be glue for legacy versions of C<PPI> and the remaining
code is for loading modules from C<@INC> ( Which we don't need ), or special casing IO ( Which is also not necessary,
as this module assumes you're moderately acquainted with C<PPI> and can do IO yourself )

C<Module::Extract::Namespaces> also obliterates document comments, which of course stands in the way of our auxiliary
requirements re C<PODNAME: > declarations.

It will also not be flexible enough to support other name extraction features we may eventually add.

And like C<Module::Metadata>, it also focuses on extracting I<many> C<package> declarations where this module prefers
to extract only the I<first>.

=back

=head1 ACKNOWLEDGEMENTS

The bulk of this logic was extrapolated from L<< C<Pod::Weaver::Section::Name>|Pod::Weaver::Section::Name >>
and a related role, L<< C<Pod::Weaver::Role::StringFromComment>|Pod::Weaver::Role::StringFromComment >>.

Thanks to L<< C<RJBS>|cpan:///author/RJBS >> for the initial implementation and L<< C<DROLSKY>|cpan:///author/DROLSKY >> for some of the improvement patches.

=cut
