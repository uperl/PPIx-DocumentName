use strict;
use warnings;
use Test::More;
use PPIx::DocumentName::Result;

my $result = PPIx::DocumentName::Result->_new(
  'My::Name',
  bless({}, 'PPI::Document'),
  bless({}, 'PPI::Statement::Package'),
);

isa_ok $result, 'PPIx::DocumentName::Result';
is $result->name, 'My::Name';
isa_ok $result->document, 'PPI::Document';
isa_ok $result->node, 'PPI::Statement::Package';


done_testing;
