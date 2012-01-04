#!perl -T

use strict;
use warnings;

use Test::More tests => 21 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('Hash::Map');
}

# get
{
    my $obj = Hash::Map->new;

    $obj->target_ref->{t} = 't',
    $obj->source_ref->{s} = 's',

    eq_or_diff(
        { $obj->target },
        { t => 't' },
        'target',
    );

    eq_or_diff(
        { $obj->source },
        { s => 's' },
        'source',
    );
}

# clone
{
    my $obj = Hash::Map->new;

    isnt(
        scalar $obj->target_ref,
        scalar $obj->clone_target->target_ref,
        'clone target',
    );

    isnt(
        scalar $obj->source_ref,
        scalar $obj->clone_source->source_ref,
        'clone source',
    );
}

# delete
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
                ->target(a => 11, b => 12, c => 13)
                ->delete_keys(qw(a c))
                ->target_ref,
        {b => 12},
        'delete_keys',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21, b => 22, c => 23 })
            ->delete_keys_ref([ qw(b) ])
            ->target_ref,
        {a => 21, c => 23},
        'delete_keys_ref',
    );
}

# copy keys
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->source(b => 12, c => 13)
            ->copy_keys(qw(c))
            ->target_ref,
        {a => 11, c => 13},
        'copy_keys',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23 })
            ->copy_keys_ref([ qw(c) ])
            ->target_ref,
        {a => 21, c => 23},
        'copy_keys_ref',
    );
}

# copy keys with code_ref
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->source(b => 12, c => 13)
            ->copy_keys(
                qw(c),
                sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_keys with code_ref, object in code_ref',
                    );
                    return "p_$_";
                },
            )
            ->target_ref,
        {a => 11, p_c => 13},
        'copy_keys with code_ref',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23 })
            ->copy_keys_ref(
                [ qw(c) ],
                sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_keys_ref with code_ref, object in code_ref',
                    );
                    return "p_$_";
                },
            )
            ->target_ref,
        {a => 21, p_c => 23},
        'copy_keys_ref with code_ref',
    );
}

# map keys
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->source(b => 12, c => 13)
            ->map_keys(
                b => q{c},
                c => q{d},
            )
            ->target_ref,
        {a => 11, c => 12, d => 13},
        'map_keys',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23 })
            ->map_keys_ref({
                b => q{c},
                c => q{d},
            })
            ->target_ref,
        {a => 21, c => 22, d => 23},
        'copy_keys_ref',
    );
}

# merge hash
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->merge_hash(
                a => 12,
                b => 13,
            )
            ->target_ref,
        {a => 12, b => 13},
        'merge_hash',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->merge_hashref({
                a => 22,
                b => 23,
            })
            ->target_ref,
        {a => 22, b => 23},
        'copy_keys_ref',
    );
}

# modify
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->modify(
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'modify, object in code_ref',
                    );
                    return "p_$_";
                },
            )
            ->target_ref,
        {a => 'p_11'},
        'modify',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->modify_ref({
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'modify_ref, object in code_ref',
                    );
                    return "p_$_";
                },
            })
            ->target_ref,
        {a => 'p_21'},
        'copy_keys_ref with code_ref',
    );
}
