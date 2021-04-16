# PPIx::DocumentName ![linux](https://github.com/uperl/PPIx-DocumentName/workflows/linux/badge.svg) ![macos](https://github.com/uperl/PPIx-DocumentName/workflows/macos/badge.svg) ![windows](https://github.com/uperl/PPIx-DocumentName/workflows/windows/badge.svg) ![cygwin](https://github.com/uperl/PPIx-DocumentName/workflows/cygwin/badge.svg) ![msys2-mingw](https://github.com/uperl/PPIx-DocumentName/workflows/msys2-mingw/badge.svg)

Utility to extract a name from a PPI Document

# SYNOPSIS

New API:

```perl
use PPIx::DocumentName 1.00 -api => 1;
my $result = PPIx::DocumentName->extract( $ppi_document );

# say the "name" of the document
say $result->name;

# the result object can also be stringified into the name found:
say "$result";

# the line number, column, filename etc. where the name was found
my $location = $result->node->location;
```

Old API:

```perl
use PPIx::DocumentName;  # assumes -api => 0
my $name = PPIx::DocumentName->extract( $ppi_document );

# say the "name" of the document
say $name;
```

# DESCRIPTION

This module contains a few utilities for extracting a "name" out of an arbitrary Perl file.

Typically, this is the `module` name, in the form:

```
package Foo
```

However, it also supports extraction of an override statement in the form:

```
# PODNAME: OverrideName::Goes::Here
```

Which may be more applicable for documents that lack a `package` statement, or the `package`
statement may be "wrong", but they still need the document parsed under the guise of having a name
( for purposes such as POD )

# METHODS

## extract

```perl
my $result = PPIx::Document->extract( $ppi_document);
```

This will first attempt to extract a name via the `PODNAME: ` comment notation,
and then fall back to using a `package Package::Name` statement.

`$ppi_document` is ideally a `PPI::Document`, but will be auto-up-cast if it is
any of the parameters `PPI::Document->new()` understands.

The `$result` is the found name under `-api => 0` and a [PPIx::DocumentName::Result](https://metacpan.org/pod/PPIx::DocumentName::Result) object
under `-api => 1`.  If the name is not found, then it will be `undef` (with either API).
Note that [PPIx::DocumentName::Result](https://metacpan.org/pod/PPIx::DocumentName::Result) is stringified to the name found, so in many circumstances
the new API can be used in the same way as the old.

## extract\_via\_statement

```perl
my $docname = PPIx::DocumentName->extract_via_statement( $ppi_document );
```

This only extract `package Package::Name` statement based document names.

`$ppi_document` is ideally a `PPI::Document`, but will be auto-up-cast if it is
any of the parameters `PPI::Document->new()` understands.

## extract\_via\_comment

```perl
my $docname = PPIx::DocumentName->extract_via_comment( $ppi_document );
```

This will only extract `PODNAME: ` comment based document names.

`$ppi_document` is ideally a `PPI::Document`, but will be auto-up-cast if it is
any of the parameters `PPI::Document->new()` understands.

# CAVEATS

The newer API (`-api => 1`) is packaged scoped in Perl 5.6 and 5.8.  In newer Perls the API is block
scoped as it should be.  Because this can cause bugs if you are using an older version of Perl this module
will complain loudly if you are using an older Perl with the newer API.  If you don't like the warning,
then either use the old API or upgrade to Perl 5.10+.

Under the older API (`-api => 0`; the default), `extract_via_statement`, unlike the other
methods in this module, returns empty list instead of undef when it does find a name.  When
using the newer API (`-api => 1`), calls are consistent in scalar and list context.  New
code should therefore use the newer API.

# ALTERNATIVE NAMES

Other things I could have called this

- `PPIx::PodName` - But it isn't, because it doesn't extract from `POD`, only returns data that may be useful **FOR**
`POD`
- `PPIx::ModuleName` - But it kinda isn't either, because its more generic than that and is tailored to extracting
"a name" out of any PPI Document, and they're _NOT_ all modules.

# SEE ALSO

Modules that are perceptibly similar to this ones tasks ( but are subtly different in important ways ) are as follows:

- [`Module::Metadata`](https://metacpan.org/pod/Module::Metadata) - Module::Metadata does a bunch of things this module explicitly doesn't
want or need to do, and it lacks a bunch of features this module needs.

    Module::Metadata is predominantly concerned with extracting _ALL_ name spaces and _ALL_ versions from a module for the
    purposes of indexing and indexing related tasks. This also means it has a notion of "hideable" name spaces with the purpose
    of hiding them from `CPAN`.

    Due to being core as well, it is not able to use `PPI` for its features, so the above concerns mean it is also mostly
    based on careful regex parsing, which can easily be false tripped on miscellaneous in document content.

    Whereas `PPIx::DocumentName` only cares about the _first_ name of a given class, and it cares much more about nested
    strings being ignored intentionally. It also has a motive to show names _even_ for documents that won't be indexed
    ( And `Module::Metadata` has no short term plans on exposing hidden document names ).

    `PPIx::DocumentName` also has special logic for the `PODNAME: ` declaration, and may eventually support other
    mechanisms for extracting a name from "a document", which will be not in `Module::Metadata`'s collection of desired
    use-cases.

- [`Module::Extract::Namespaces`](https://metacpan.org/pod/Module::Extract::Namespaces) - This is probably closer to
`PPIx::DocumentName`'s requirements, using `PPI` to extract content.

    Most of `Module::Extract::Namespaces`'s code seems to be glue for legacy versions of `PPI` and the remaining
    code is for loading modules from `@INC` ( Which we don't need ), or special casing IO ( Which is also not necessary,
    as this module assumes you're moderately acquainted with `PPI` and can do IO yourself )

    `Module::Extract::Namespaces` also obliterates document comments, which of course stands in the way of our auxiliary
    requirements re `PODNAME: ` declarations.

    It will also not be flexible enough to support other name extraction features we may eventually add.

    And like `Module::Metadata`, it also focuses on extracting _many_ `package` declarations where this module prefers
    to extract only the _first_.

- [`PPIx::DocumentName::Result`](https://metacpan.org/pod/PPIx::DocumentName::Result) - comes with this module, and contains the results of
this module, when using the newer `-api => 1` API.

# ACKNOWLEDGEMENTS

The bulk of this logic was extrapolated from [`Pod::Weaver::Section::Name`](https://metacpan.org/pod/Pod::Weaver::Section::Name)
and a related role, [`Pod::Weaver::Role::StringFromComment`](https://metacpan.org/pod/Pod::Weaver::Role::StringFromComment).

Thanks to [`RJBS`](cpan:///author/RJBS) for the initial implementation and [`DROLSKY`](cpan:///author/DROLSKY) for some of the improvement patches.

# AUTHORS

- Kent Fredric <kentnl@cpan.org>
- Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2021 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
