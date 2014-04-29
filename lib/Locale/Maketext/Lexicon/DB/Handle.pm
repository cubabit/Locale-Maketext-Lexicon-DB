package Locale::Maketext::Lexicon::DB::Handle;
# ABSTRACT: Maketext handle for L<Locale::Maketext::Lexicon::DB>

use Moose;
use namespace::autoclean;
use Locale::Maketext;
use Carp;
use Data::Dumper;
use Log::Log4perl qw(:easy);

has langs => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
);

has _parent => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

sub _lexicon {
    my $self = shift;

    my $lexicon = {};
    my $cache_key;

    if ($self->_parent->has_cache) {
        $cache_key = $self->_parent->_cache_key_for_langs( $self->langs );

        local $Storable::Eval = 1;
        $lexicon = $self->_parent->cache->get($cache_key);

        TRACE('Retrieved lexicon from cache')
            if (defined $self->_parent->cache);
    }

    unless (keys %{ $lexicon }) {
        TRACE('Hitting database for lexicon');

        my $dbh = $self->_parent->dbh;

        for my $lang (@{ $self->langs }) {
            TRACE('Getting lexicon entries for language ' . $lang);

            my $lexicon_st = $dbh->prepare(q{
                SELECT *
                FROM lexicon
                WHERE lex = ?
                AND lang = ?
            });
            $lexicon_st->execute($self->_parent->lex, $lang);

            while (my $lex_entry = $lexicon_st->fetchrow_hashref) {
                my $key     = $lex_entry->{lex_key};
                next if defined $lexicon->{ $key };

                my $value   = $lex_entry->{lex_value};
                $value      =~ tr/\r//d;
                $value      =~ s/\n/\\n/g;

                $lexicon->{ $key } = Locale::Maketext->_compile($value);
            }
        }

        if ($self->_parent->has_cache and keys %{ $lexicon }) {
            local $Storable::Deparse = 1;
            TRACE('Storing lexicon in cache');
            $self->_parent->cache->set($cache_key => $lexicon, $self->_parent->cache_expiry_seconds);
        }
    }

    TRACE('Compiled lexicon is: ' . Dumper $lexicon);

    return $lexicon;
}

=method maketext ($key)

Return the compiled string represented by C<$key>. If C<$key> does not exist, an exception is
raised, unless C<auto> is set in which case C<$key> is returned.

=cut

sub maketext {
    my $self = shift;
    my $key = shift;

    my $value = $self->_lexicon->{ $key };

    unless (defined $value) {
        if ($self->_parent->auto) {
            $value = Locale::Maketext->_compile($key);
        }
        else {
            croak $key . ' not found in lexicon';
        }
    }

    if (ref $value eq 'SCALAR') {
        return ${ $value };
    }

    TRACE('Returning maketext entry for key ' . $key);

    return $value->( 'Locale::Maketext', @_ );
}

=head1 SEE ALSO

L<Locale::Maketext::Lexicon::DB>

=cut

__PACKAGE__->meta->make_immutable;

1;
