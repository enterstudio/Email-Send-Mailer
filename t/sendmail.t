#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use Email::Send;
BEGIN { use_ok('Email::Send::Mailer::Sendmail'); }

my $mailer = Email::Send::Mailer::Sendmail->new;

isa_ok($mailer, 'Email::Send::Mailer');
isa_ok($mailer, 'Email::Send::Mailer::Sendmail');

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
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
      to   => [ 'devnull@pobox.com' ],
    }
  );

  isa_ok($result, 'Email::SendX::Exception');
  isa_ok($result, 'Email::SendX::Exception::Success')
    or diag $result;
}
