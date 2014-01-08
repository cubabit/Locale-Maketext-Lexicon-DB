#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use DBI;
use File::Temp qw(tempfile);

(undef, my $db_file) = tempfile();
my $dbh = DBI->connect('dbi:SQLite:dbname=' . $db_file, '', '');

{
    package Test::Maketext;

    use Moose;

    BEGIN { extends 'Locale::Maketext::Lexicon::DB'; }

    has '+dbh' => (
        builder => '_build_dbh',
    );

    sub _build_dbh {
        my $self = shift;

        return $dbh;
    }

    has '+lex' => (
        default => 'test',
    );

    has '+auto' => (
        default => 1,
    );

    has '+language_mappings' => (
        default => sub {
            {
                en_gb   => [qw(en_gb en)],
                en_us   => [qw(en_us en)],
                en      => [qw(en)],
            }
        },
    );
}

$dbh->do(q{
    CREATE TABLE lexicon (
        id INTEGER PRIMARY KEY NOT NULL,
        lang VARCHAR(45) NOT NULL DEFAULT 'en',
        lex VARCHAR(45) NOT NULL DEFAULT 'santa',
        lex_key TEXT(65535) NOT NULL DEFAULT '',
        lex_value TEXT(65535) NOT NULL DEFAULT ''
    )
});

my $lex_insert_sth = $dbh->prepare(q{
    INSERT INTO lexicon(lex, lang, lex_key, lex_value)
    VALUES (?, ?, ?, ?)
});

$lex_insert_sth->execute('test', 'en', 'foo', 'foo');
$lex_insert_sth->execute('test', 'en_gb', 'foo', 'foo_gb');
$lex_insert_sth->execute('test', 'en_gb', 'bar', 'bar [_1]'),

use_ok('Test::Maketext');

ok(my $handle = Test::Maketext->get_handle('en_gb'), 'get_handle');

is(
    $handle->maketext('foo') => 'foo_gb',
    'maketext',
);

is(
    $handle->maketext('bar', 2) => 'bar 2',
    'maketext with value',
);

ok(my $handle_2 = Test::Maketext->get_handle('en_us'), 'get_handle');

is(
    $handle_2->maketext('foo') => 'foo',
    'maketext',
);

done_testing();
