package Locale::Maketext::Lexicon::DB;
# ABSTRACT: Dynamically load lexicon from a database table

use Locale::Maketext::Lexicon::DB::Handle;
use Moose;
use namespace::autoclean;
use Locale::Maketext 1.22;
use Log::Log4perl qw(:easy);

has dbh => (
    is          => 'ro',
    isa         => 'Object',
    required    => 1,
);

has cache => (
    is          => 'ro',
    isa         => 'Object',
    predicate   => 'has_cache',
);

has cache_expiry_seconds => (
    is          => 'ro',
    isa         => 'Int',
    default     => 60 * 5,
);

has lex => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has auto => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
);

has language_mappings => (
    is          => 'ro',
    isa         => 'HashRef[ArrayRef]',
    required    => 1,
);

{
    my $instance;

    sub get_handle {
        my $class = shift;
        my @requested_langs = @_;

        $instance ||= $class->new;

        @requested_langs = Locale::Maketext->_ambient_langprefs
            unless @requested_langs;

        DEBUG('Languages asked for: ' . join (', ', @requested_langs));

        my $langs = [];
        for (@requested_langs) {
            if (defined $class->new->language_mappings->{ lc $_ }) {
                $langs = $class->new->language_mappings->{ lc $_ };
                last;
            }
        }

        DEBUG('Lexicon will be searched for languages: ' . join(', ', @{ $langs }) );

        return Locale::Maketext::Lexicon::DB::Handle->new(
            _parent => $instance,
            langs   => $langs
        );
    }
}

=method clear_cache

=cut

sub clear_cache {
    my $class = shift;

    my $self = $class->new;

    if (defined $self->cache) {
        for (values %{ $self->language_mappings }) {
            $self->cache->delete( $self->_cache_key_for_langs($_) );
        }
    }
}

sub _cache_key_for_langs {
    my $self = shift;

    return 'lexicon.' . join(
        $self->lex,
        '-', @{ shift() }
    )
}

__PACKAGE__->meta->make_immutable;

1;
