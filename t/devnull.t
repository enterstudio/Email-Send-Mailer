
use strict;
use warnings;

use Test::More 'no_plan';

use Email::Send;
BEGIN { use_ok('Email::Send::Mailer::DevNull'); }

my $mailer = Email::Send::Mailer::DevNull->new;
isa_ok($mailer, 'Email::Send::Mailer');
isa_ok($mailer, 'Email::Send::Mailer::DevNull');

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

my $sender = Email::Send->new({ mailer => $mailer });
isa_ok($sender, 'Email::Send');

cmp_ok($sender->mailer, '==', $mailer, "sender's mailer is what we asked for");

my $result = $sender->send($message);
isa_ok($result, 'Email::SendX::Exception');
isa_ok($result, 'Email::SendX::Exception::Success');
