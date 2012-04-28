#!perl -T

use strict;
use warnings;

use Test::More tests => 56 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('Hash::Map');
}

# constructors
{
    my $package = 'Hash::Map';
    isa_ok(
        scalar $package->new,
        $package,
        'constructor new',
    );
    isa_ok(
        scalar $package->target_ref({t => 1}),
        $package,
        'constructor target_ref',
    );
    isa_ok(
        scalar $package->target(t => 1),
        $package,
        'constructor target',
    );
    isa_ok(
        scalar $package->set_target,
        $package,
        'constructor set_target',
    );
    isa_ok(
        scalar $package->source_ref({s => 1}),
        $package,
        'constructor source_ref',
    );
    isa_ok(
        scalar $package->source(s => 1),
        $package,
        'constructor source',
    );
    isa_ok(
        scalar $package->set_source,
        $package,
        'constructor set_source',
    );
    isa_ok(
        scalar $package->combine,
        $package,
        'constructor combine',
    );
}

# set_source, set_target
{
    my $obj = Hash::Map
        ->set_source(s => 11)
        ->set_target(t => 12);
    eq_or_diff(  
        $obj->source_ref,
        { s => 11 },
        'data of set_souce',
    );    
    eq_or_diff(  
        $obj->target_ref,
        { t => 12 },
        'data of set_target',
    );    
    $obj->set_source;
    eq_or_diff(  
        $obj->source_ref,
        {},
        'data of empty set_souce',
    );    
    $obj->set_source(s => 11)->set_target;
    eq_or_diff(  
        $obj->target_ref,
        {},
        'data of empty set_target',
    );    
}

# combine
{
    my $obj = Hash::Map->target(t1 => 11, t2 => 12);

    $obj->combine(
        Hash::Map->target(t2 => 22, t3 => 23),
        Hash::Map->target(t3 => 33, t4 => 34),
    );
    eq_or_diff(
        { $obj->target },
        {
            t1 => 11,
            t2 => 22,
            t3 => 33,
            t4 => 34,
        },
        'combined target',
    );
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
    eq_or_diff(
        scalar Hash::Map
                ->target(a => 11, b => 12, c => 13, d => 14)
                ->delete_keys(qw(a c))
                ->target_ref,
        {b => 12, d => 14},
        'delete_keys',
    );

    eq_or_diff(
        scalar Hash::Map
            ->target_ref({ a => 21, b => 22, c => 23, d => 24 })
            ->delete_keys_ref([ qw(a c) ])
            ->target_ref,
        {b => 22, d => 24},
        'delete_keys_ref',
    );
}

# copy keys
{
    eq_or_diff(
        scalar Hash::Map
            ->target(a => 11)
            ->source(b => 12, c => 13, d => 14)
            ->copy_keys(qw(c d))
            ->target_ref,
        {a => 11, c => 13, d => 14},
        'copy_keys',
    );

    eq_or_diff(
        scalar Hash::Map
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23, d => 24 })
            ->copy_keys_ref([ qw(c d) ])
            ->target_ref,
        {a => 21, c => 23, d => 24},
        'copy_keys_ref',
    );
}

# copy keys with code_ref
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11)
            ->source(b => 12, c => 13, d => 14)
            ->copy_keys(
                qw(c d),
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
        {a => 11, p_c => 13, p_d => 14},
        'copy_keys with code_ref',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23, d => 24 })
            ->copy_keys_ref(
                [ qw(c d) ],
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
        {a => 21, p_c => 23, p_d => 24},
        'copy_keys_ref with code_ref',
    );
}

# map keys
{
    eq_or_diff(
        scalar Hash::Map
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
        scalar Hash::Map
            ->target_ref({ a => 21 })
            ->source_ref({ b => 22, c => 23 })
            ->map_keys_ref({
                b => q{c},
                c => q{d},
            })
            ->target_ref,
        {a => 21, c => 22, d => 23},
        'map_keys_ref',
    );
}

# merge hash
{
    eq_or_diff(
        scalar Hash::Map
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
        scalar Hash::Map
            ->target_ref({ a => 21 })
            ->merge_hashref({
                a => 22,
                b => 23,
            })
            ->target_ref,
        {a => 22, b => 23},
        'merge_hash_ref',
    );
}

# modify
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->target(a => 11, b => 12)
            ->modify(
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'modify, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            )
            ->target_ref,
        {a => 'pa_11', b => 'pb_12'},
        'modify',
    );

    eq_or_diff(
        scalar $obj
            ->target_ref({ a => 21, b => 22 })
            ->modify_ref({
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'modify_ref, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            })
            ->target_ref,
        {a => 'pa_21', b => 'pb_22'},
        'modify_ref',
    );
}

# copy keys + modify
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->source(a => 11, b => 12)
            ->copy_modify(
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_modify, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            )
            ->target_ref,
        {a => 'pa_11', b => 'pb_12'},
        'copy_modify',
    );

    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 21, b => 22 })
            ->copy_modify_ref({
                a => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'copy_modify_ref, object in code_ref',
                    );
                    return "pa_$_";
                },
                b => sub {
                    return "pb_$_";
                },
            })
            ->target_ref,
        {a => 'pa_21', b => 'pb_22'},
        'copy_modify_ref',
    );

    eq_or_diff(
        scalar $obj
            ->source(a => 31, b => 32)
            ->copy_modify_identical(
                qw(a b),
                sub {
                    my ($self, $key) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'copy_modify_identical, object in code_ref',
                    );
                    return "p${key}_$_";
                },
            )
            ->target_ref,
        {a => 'pa_31', b => 'pb_32'},
        'copy_modify_identical',
    );

    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 41, b => 42 })
            ->copy_modify_identical_ref(
                [ qw(a b) ],
                sub {
                    my ($self, $key) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'copy_modify_identical_ref, object in code_ref',
                    );
                    return "p${key}_$_";
                },
            )
            ->target_ref,
        {a => 'pa_41', b => 'pb_42'},
        'copy_modify_identical_ref',
    );
}

# map keys + modify
{
    my $obj = Hash::Map->new;

    eq_or_diff(
        scalar $obj
            ->source(a => 11, b => 12)
            ->map_modify(
                a => b => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'map_modify, object in code_ref',
                    );
                    return "pab_$_";
                },
                b => c => sub {
                    return "pbc_$_";
                },
            )
            ->target_ref,
        {b => 'pab_11', c => 'pbc_12'},
        'map_modify',
    );

    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 21, b => 22 })
            ->map_modify_ref([
                a => b => sub {
                    eq_or_diff(
                        shift,
                        $obj,
                        'map_modify_ref, object in code_ref',
                    );
                    return "pab_$_";
                },
                b => c => sub {
                    return "pbc_$_";
                },
            ])
            ->target_ref,
        {b => 'pab_21', c => 'pbc_22'},
        'map_modify_ref',
    );

    eq_or_diff(
        scalar $obj
            ->source(a => 31, b => 32)
            ->map_modify_identical(
                a => q{b},
                b => q{c},
                sub {
                    my ($self, $key_source, $key_target) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'map_modify_identical, object in code_ref',
                    );
                    return "p${key_source}${key_target}_$_";
                },
            )
            ->target_ref,
        {b => 'pab_31', c => 'pbc_32'},
        'map_modify_identical',
    );

    eq_or_diff(
        scalar $obj
            ->source_ref({ a => 41, b => 42})
            ->map_modify_identical_ref(
                {a => q{b}, b => q{c}},
                sub {
                    my ($self, $key_source, $key_target) = @_;
                    eq_or_diff(
                        $self,
                        $obj,
                        'map_modify_identical_ref, object in code_ref',
                    );
                    return "p${key_source}${key_target}_$_";
                },
            )
            ->target_ref,
        {b => 'pab_41', c => 'pbc_42'},
        'map_modify_identical_ref',
    );
}
