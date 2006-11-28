package Email::Send::Mailer::STDOUT;
use base qw(Email::Send::Mailer);

use strict;
use warnings;

sub is_available { 1 };

sub send {
  my ($self, $message, $arg) = @_;
  
  my @to = ref $arg->{to} ? @{ $arg->{to} } : $arg->{to};

  print "ENVELOPE TO  : @to\n"
  print "ENVELOPE FROM: $arg->{from}\n"
  print '-' x 10, " begin body\n";

  print $message;

  print '-' x 10, " begin body\n";

  return $self->exception(
    'Email::SendX::Exception::Success',
    failures => { },
  );
}

1;
