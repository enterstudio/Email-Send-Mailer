use Test::More tests => 1;

BEGIN {
  use_ok('Email::Send::Mailer');
}

diag( "Testing Email::Send::Mailer $Email::Send::Mailer::VERSION" );
