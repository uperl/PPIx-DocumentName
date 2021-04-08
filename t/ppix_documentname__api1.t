use strict;
use warnings;
use Test::More;
use PPIx::DocumentName -api => 1;
use PPI::Util qw( _Document );

subtest 'basic' => sub {

  my $sample = <<'EOF';
package Foo::Bar;

1;
EOF

  {
    my $result = _Document( \$sample );
    isa_ok( $result, 'PPI::Document', "_Document(\\\$sample)" );
  };

  {
    my $result = PPIx::DocumentName->extract( \$sample );
    is( $result, 'Foo::Bar', "->extract() is package statement" );
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    subtest '->extract() is package statement (list context)' => sub {
      is $result[0], 'Foo::Bar';
      isa_ok $result[1], 'PPI::Statement::Package';
      is scalar(@result), 2;
    };
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    is( $result, 'Foo::Bar', "->extract_via_statement() is correct" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    subtest '->extract_via_statement() is correct (list context)' => sub {
      is $result[0], 'Foo::Bar';
      isa_ok $result[1], 'PPI::Statement::Package';
      is scalar(@result), 2;
    };
  }


  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    is( $result, undef, "->extract_via_comment() is undef" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    is_deeply( \@result, [undef,undef], "->extract_via_comment() is undef (list context)" );
  }

};

subtest 'Override tests' => sub {

  my $sample = <<'EOF';
package Foo::Bar;

# PODNAME: Override

1;
EOF

  {
    my $result = _Document( \$sample );
    isa_ok( $result, 'PPI::Document', '_Document(\\$sample)' );
  };

  {
    my $result = PPIx::DocumentName->extract( \$sample );
    is( $result, 'Override', "->extract() gets comment override" );
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    subtest '->extract() gets comment override (list context)' => sub {
      is $result[0], 'Override';
      isa_ok $result[1], 'PPI::Token::Comment';
      is scalar(@result), 2;
    };
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    is( $result, 'Foo::Bar', "->extract_via_statement() gets package statement" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    subtest '->extract_via_statement() gets package statement (list context)' => sub {
      is $result[0], 'Foo::Bar';
      isa_ok $result[1], 'PPI::Statement::Package';
      is scalar(@result), 2;
    };
  }

  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    is( $result, 'Override', "->extract_via_comment() gets PODNAME" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    subtest '->extract_via_comment() gets PODNAME (list context)' => sub {
      is $result[0], 'Override';
      isa_ok $result[1], 'PPI::Token::Comment';
      is scalar(@result), 2;
    };
  }
};

subtest 'Empty test' => sub {

  my $sample = '';

  {
    my $result = PPIx::DocumentName->extract( \$sample );
    is( $result, undef, "->extract()" );
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    is_deeply( \@result, [undef,undef], "->extract() (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    is( $result, undef, "->extract_via_statement()" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    is_deeply( \@result, [undef,undef], "->extract_via_statement() (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    is( $result, undef, "->extract_via_comment()" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    is_deeply( \@result, [undef,undef], "->extract_via_comment() (list context)" );
  }
};

done_testing;
