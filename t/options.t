#!/usr/bin/env perl
# Without any options specified, we can generate a recaptcha which links to
# Google in English-language.

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More qw(no_plan);

use_ok('Mojolicious');
use_ok('Mojo::Log');
use_ok('Mojolicious::Plugin::Recaptcha');

# Set up Mojolicious and our plugin.
my $mojolicious = Mojolicious->new;
ok($mojolicious, q{Mojolicious doesn't immediately blow up});
my %default_conf
    = (public_key => 'Public key!', private_key => 'Private key!');
ok($mojolicious->plugin(recaptcha => \%default_conf),
    'We can create a recaptcha plugin');

# Turn off logging to avoid polluting STDERR with warnings about how our
# key is compromised.
# This test only generates a debug log message, so even on systems (e.g.
# Windows) where there isn't such a file as /dev/null, this should be safe.
my $quiet_log = Mojo::Log->new(path => '/dev/null', level => 'fatal');
$mojolicious->log($quiet_log);

# We get the sort of basic markup we expect.
my $html = $mojolicious->recaptcha_html;
ok($html, 'We got some HTML back');
like($html, qr{ google [.] com /recaptcha .+ k= Public . key! }x,
    q{There's a link to Google which includes our public key});
unlike($html, qr{Private . key!}, q{Our private key doesn't appear});

# We can specify SSL or non-SSL via the ssl config option.
# Need to assign the result to an array and then use scalar context because
# in scalar context we just get the first match, iterator-style.
my @matches_http = $html =~ m{http://www [.] google }gx;
is (scalar @matches_http, 2,
    'Both URLs are using insecure http') or diag($html);
ok($mojolicious->plugin(recaptcha => { %default_conf, ssl => 1 }),
    'We can specify SSL as a config option');
my $html_ssl = $mojolicious->recaptcha_html;
my @matches_https = $html_ssl =~ m{https://www [.] google }gx;
is (scalar @matches_https, 2,
    'If we specify the ssl option we get https:// URLs') or diag($html);
