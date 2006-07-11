package Email::Send::Mailer::Maildir;
use base qw(Email::Send::Mailer);

use strict;
use warnings;

use File::Spec;
use Email::LocalDelivery;

sub is_available { 1 };

sub dir {
  my ($self) = @_;
  
  $self->{dir} ||= File::Spec->catdir(File::Spec->curdir, 'Maildir');
}

sub _deliver {
  my ($self, $arg) = @_;

  my $message = Email::Simple->new($arg->{message}->as_string);

  $message->header_set('X-ICG-Env-To'   => join(', ', @{ $arg->{to} }));
  $message->header_set('X-ICG-Env-From' => $arg->{from});

  for my $dir (qw(cur tmp new)) { 
    my $subdir = File::Spec->catdir($self->dir, $dir);
    next if -d $subdir;
    File::Path::mkpath( File::Spec->catdir($self->dir, $dir) )
  }

  Email::LocalDelivery->deliver($message->as_string, $self->dir);
}

sub send {
  my ($self, $message, $arg) = @_;
  
  my @to = ref $arg->{to} ? @{ $arg->{to} } : $arg->{to};

  my $ok = $self->_deliver({
    message   => $message,
    to        => \@to,
    from      => $arg->{from},
  });

  if ($ok) {
    return $self->exception(
      'Email::SendX::Exception::Success',
      failures => { },
    );
  } else {
    return $self->exception('Email::SendX::Exception::Failure');
  }
}

1;
