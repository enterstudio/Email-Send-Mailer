#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use Email::Simple;
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

{
  my $sender = Email::Send->new({
    mailer => Email::Send::Mailer::OldSMTP->new({
      host => 'localhost',
      port => 25,
    }),
  });
  # sending a plain string -- other message types are tested by smtpsend's
  # tests -- hdp, 2006-11-28
  $sender->send(
    $message,
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

  $msg_obj = Email::Simple->new($message);
  is $mail->message->header('From'),
    $msg_obj->header('From'),
    'From: unchanged';

  is $mail->message->body,
    $msg_obj->body,
    'body unchanged';

}
