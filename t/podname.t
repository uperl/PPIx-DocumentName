use strict;
use warnings;

use Test::More;

# ABSTRACT: Basic tests

use PPIx::DocumentName;
use PPI::Util qw( _Document );

my $sample = <<'EOF';
package Foo::Bar;

# PODNAME: Override

1;
EOF

{
  note "Sanity Check";
  my $result = _Document( \$sample );
  isa_ok( $result, 'PPI::Document' );
};

{
  note "Composite Extraction";
  my $result = PPIx::DocumentName->extract( \$sample );
  is( $result, 'Override', "Extracted Document matches expectation" );
}

{
  note "Statement Extraction";
  my $result = PPIx::DocumentName->extract_via_statement( \$sample );
  is( $result, 'Foo::Bar', "Extracted Document matches expectation" );
}

{
  note "PODNAME Comment Extraction";
  my $result = PPIx::DocumentName->extract_via_comment( \$sample );
  is( $result, 'Override', "Extracted Document matches expectation" );
}

done_testing;

