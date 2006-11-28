#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use File::Temp;
use Email::Simple;
use Email::Simple::FromHandle;
use Email::Send;
use ICG::TestTools::Mail;
BEGIN { use_ok('Email::Send::Mailer::OldSMTP'); }

my $mailer = Email::Send::Mailer::OldSMTP->new({
  host => 'mx-all.pobox.com',
  port => 31145,
});

isa_ok($mailer, 'Email::Send::Mailer');
isa_ok($mailer, 'Email::Send::Mailer::OldSMTP');

my $rcpt = "recipient+$^T\@nowhere.example.net";
my $message = <<"END_MESSAGE";
From: sender\@test.example.com
To: $rcpt
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

{
  my $sender = Email::Send->new({ mailer => $mailer });
  my $result = $sender->send(
    $message,
    {
      from => 'devnull@pobox.com',
      to   => [ 'devnull@pobox.com', 'bounce@pobox.com', ],
    }
  );

  isa_ok($result, 'Email::SendX::Exception');
  isa_ok($result, 'Email::SendX::Exception::Success')
    or diag $result;

  is_deeply(
    $result->failures,
    { 'bounce@pobox.com' => 'rejected by smtp server' },
    "delivery indicates failure to 'bounce\@pobox.com'",
  );
}

my %tmp;
for my $key (qw(handle fromhandle code)) {
  my $fh = $tmp{$key} = File::Temp->new;
  print {$fh} $message;
  seek $fh, 0, 0;
}

# XXX duplicating tests from smtpsend, but we're paranoid -- hdp, 2006-11-28
for my $input (
  $message, 
  Email::Simple->new($message),
  Email::Simple::FromHandle->new($tmp{fromhandle}),
  # Email::Send doesn't recognize these yet -- hdp, 2006-11-28
#  $tmp{handle},
#  sub { my $fh = $tmp{code}; <$fh> },
) {
  my $sender = Email::Send->new({
    mailer => Email::Send::Mailer::OldSMTP->new({
      host => 'localhost',
      port => 25,
    }),
  });
  $sender->send(
    $input,
    {
      from => 'devnull@pobox.com',
      # XXX stupid address to hard-code
      to   => [ 'hdp+test-tools@vex.pobox.com' ],
    },
  );
  my $mail = eval {
    ICG::TestTools::Mail->wait_for_message(
      [ env_to => $rcpt ],
    );
  };
  is $@, "";

  my $msg_obj = Email::Simple->new($message);
  is $mail->message->header('From'),
    $msg_obj->header('From'),
    'From: unchanged';

  is $mail->message->body,
    $msg_obj->body,
    'body unchanged';

}
