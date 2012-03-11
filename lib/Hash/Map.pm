package Hash::Map; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.004';

use Carp qw(confess);
use Clone qw(clone);
use Perl6::Export::Attrs;
use Scalar::Util qw(blessed);
use Try::Tiny;

sub new {
    return bless
        {
            target => {},
            source => {},
        },
        shift;
}

sub _hashref {
    my ($self, $key, $hashref) = @_;

    if ( defined $hashref ) {
        ref $hashref eq 'HASH'
            or confess 'Hash reference expected';
        if ( ! blessed $self ) {
            $self = $self->new; # this method used as constructor
        }
        $self->{$key} = $hashref;
        return $self;
    }

    return $self->{$key};
}

sub _hash {
    my ($self, $key, @more) = @_;

    if (@more) {
        my $hashref;
        try {
            $hashref = { @more };
        }
        catch {
            confess 'Hash expected ', $_;
        };
        if ( ! blessed $self ) {
            $self = $self->new; # this method used as constructor
        }
        $self->_hashref($key, $hashref);
        return $self;
    }

    return %{ $self->_hashref($key) };
}

## no critic (ArgUnpacking);
sub target_ref { return shift->_hashref(target => @_) }
sub source_ref { return shift->_hashref(source => @_) }
sub target     { return shift->_hash(target => @_) }
sub source     { return shift->_hash(source => @_) }
## use critic (ArgUnpacking);

sub combine {
    my ($self, @hash_maps) = @_;

    if ( ! blessed $self ) {
        $self = $self->new; # this method used as constructor
    }
    for my $hash_map (@hash_maps) {
        $self->merge_hashref( $hash_map->target_ref );
    }

    return $self;
}

sub clone_target {
    my $self = shift;

    $self->target_ref( clone( $self->target_ref ) );

    return $self;
}

sub clone_source {
    my $self = shift;

    $self->source_ref( clone( $self->source_ref ) );

    return $self;
}

sub delete_keys_ref {
    my ($self, $keys_ref) = @_;

    ref $keys_ref eq 'ARRAY'
        or confess 'Array reference expected';
    delete @{ $self->target_ref }{ @{$keys_ref} };

    return $self;
}

sub delete_keys {
    my ($self, @keys) = @_;

    return $self->delete_keys_ref(\@keys);
}

sub copy_keys_ref {
    my ($self, $keys_ref, $code_ref) = @_;

    ref $keys_ref eq 'ARRAY'
        or confess 'Array reference expected';
    if ( ref $code_ref eq 'CODE' ) {
        return $self->map_keys_ref({
            map { ## no critic (MutatingListFunctions VoidMap)
                $_ => do {
                    local $_ = $_;
                    scalar $code_ref->($self);
                };
            } @{$keys_ref}
        });
    }

    @{ $self->target_ref }{ @{$keys_ref} }
        = @{ $self->source_ref }{ @{$keys_ref} };

    return $self;
}

sub copy_keys {
    my ($self, @keys) = @_;

    if ( @keys && ref $keys[-1] eq 'CODE' ) {
        my $code_ref = pop @keys;
        return $self->map_keys_ref({
            map { ## no critic (MutatingListFunctions VoidMap)
                $_ => do {
                    local $_ = $_;
                    scalar $code_ref->($self);
                };
            } @keys
        });
    }

    return $self->copy_keys_ref(\@keys);
}

sub map_keys_ref {
    my ($self, $map_ref) = @_;

    ref $map_ref eq 'HASH'
        or confess 'Hash reference expected';
    @{ $self->target_ref }{ values %{$map_ref} }
        = @{ $self->source_ref }{ keys %{$map_ref} };

    return $self;
}

sub map_keys {
    my ($self, @more) = @_;

    my $map_ref;
    try {
        $map_ref = { @more };
    }
    catch {
        confess 'Hash expected ', $_;
    };

    return $self->map_keys_ref($map_ref);
}

sub merge_hashref {
    my ($self, $hashref) = @_;

    ref $hashref eq 'HASH'
        or confess 'Hash reference expected';
    @{ $self->target_ref }{ keys %{$hashref} } = values %{$hashref};

    return $self;
}

sub merge_hash {
    my ($self, @more) = @_;

    my $hashref;
    try {
        $hashref = { @more };
    }
    catch {
        confess 'Hash expected ', $_;
    };

    return $self->merge_hashref($hashref);
}

sub modify_ref {
    my ($self, $modify_ref) = @_;

    ref $modify_ref eq 'HASH'
        or confess 'Hash reference expected';
    my $target_ref = $self->target_ref;
    while ( my ($key, $code_ref) = each %{$modify_ref} ) {
        local $_ = $target_ref->{$key};
        $target_ref->{$key} = $code_ref->($self);
    }

    return $self;
}

sub modify {
    my ($self, @more) = @_;

    my $modify_ref;
    try {
        $modify_ref = { @more };
    }
    catch {
        confess 'Hash expected ', $_;
    };

    return $self->modify_ref($modify_ref);
}

sub copy_modify_ref {
    my ($self, $copy_modify_ref) = @_;

    ref $copy_modify_ref eq 'HASH'
        or confess 'Hash reference expected';
    $self->copy_keys( keys %{$copy_modify_ref} );

    return $self->modify_ref($copy_modify_ref);
}

sub copy_modify {
    my ($self, @more) = @_;

    my $copy_modify_ref;
    try {
        $copy_modify_ref = { @more };
    }
    catch {
        confess 'Hash expected ', $_;
    };

    return $self->copy_modify_ref($copy_modify_ref);
}

sub copy_modify_identical_ref {
    my ($self, $keys_ref, $code_ref) = @_;

    ref $keys_ref eq 'ARRAY'
        or confess 'Array reference for keys expected';
    ref $code_ref eq 'CODE'
        or confess 'Code reference for modify expected';
    my $source_ref = $self->source_ref;
    my $target_ref = $self->target_ref;
    for my $key ( @{$keys_ref} ) {
        $target_ref->{$key} = $source_ref->{$key};
        local $_ = $target_ref->{$key};
        $target_ref->{$key} = $code_ref->($self, $key);
    }

    return $self;
}

sub copy_modify_identical {
    my ($self, @keys) = @_;

    my $code_ref = pop @keys;
    ref $code_ref eq 'CODE'
        or confess 'Code reference as last parameter expected';

    return $self->copy_modify_identical_ref(\@keys, $code_ref);
}

sub map_modify_ref {
    my ($self, $map_modify_ref) = @_;

    ref $map_modify_ref eq 'ARRAY'
        or confess 'Array reference expected';

    @{$map_modify_ref} % 3 ## no critic (MagicNumber)
        and confess
            scalar @{$map_modify_ref},
            ' elements in array are not a group of 3';
    my @map_modify = @{$map_modify_ref};
    my $source_ref = $self->source_ref;
    my $target_ref = $self->target_ref;
    while ( my ($source_key, $target_key, $code_ref) = splice @map_modify, 0, 3 ) { ## no critic (MagicNumber)
        $target_ref->{$target_key} = $source_ref->{$source_key};
        local $_ = $target_ref->{$target_key};
        $target_ref->{$target_key} = $code_ref->($self);
    };

    return $self;
}

sub map_modify {
    my ($self, @map_modify) = @_;

    return $self->map_modify_ref(\@map_modify);
}

sub map_modify_identical_ref {
    my ($self, $hash_ref, $code_ref) = @_;

    ref $hash_ref eq 'HASH'
        or confess 'Hash reference expected';
    ref $code_ref eq 'CODE'
        or confess 'Code reference as last parameter expected';
    my $source_ref = $self->source_ref;
    my $target_ref = $self->target_ref;
    while ( my ($source_key, $target_key) = each %{$hash_ref} ) {
        $target_ref->{$target_key} = $source_ref->{$source_key};
        local $_ = $target_ref->{$target_key};
        $target_ref->{$target_key} = $code_ref->($self, $source_key, $target_key);
    };

    return $self;
}

sub map_modify_identical {
    my ($self, @map_modify) = @_;

    my $code_ref = pop @map_modify;
    @map_modify % 2
        and confess
            scalar @map_modify,
            ' elements in array are not pairwise';
    ref $code_ref eq 'CODE'
        or confess 'Code reference as last parameter expected';

    return $self->map_modify_identical_ref({ @map_modify }, $code_ref);
}

sub hashref_map :Export {
    my ($source_ref, @more) = @_;

    my $self = Hash::Map->source_ref($source_ref);
    ITEM:
    for my $item (@more) {
        if ( ref $item eq 'ARRAY' ) {
            $self->copy_keys( @{$item} );
            next ITEM;
        }
        if ( ref $item eq 'HASH' ) {
            while ( my ($key, $value) = each %{$item} ) {
                ref $value eq 'CODE'
                    ? $self->modify($key, $value)
                    : $self->map_keys($key, $value);
            }
            next ITEM;
        }
        confess 'Array- or hash reference expected';
    }

    return $self->target_ref;
}

sub hash_map :Export { ## no critic (ArgUnpacking)
    return %{ hashref_map(@_) };
}

# $Id$

1;

__END__

=head1 NAME

Hash::Map - Manipulate hashes map like

=head1 VERSION

0.004

=head1 SYNOPSIS

=head2 Hint

When I write

    $obj = $obj->this_method;

I mean, that the Hash::Map object itself will be returned.
So it is possible to build chains like that:

    $obj->this_method->next_method;

It is typical used for setter or worker methods.

=head2 OO style

    require Hash::Map;

    # Constructor typical not called directly.
    # Methods "target", "target_ref", "source", "source_ref"
    # and combine are alternative constructors.
    my $obj = Hash::Map->new;

    # set target hash
    $obj = $obj->target(a => 1);
    $obj = $obj->target_ref({a => 1});

    # get target hash (no set parameters)
    $target = $obj->target;
    $target = $obj->target_ref;

    # set source hash
    $obj = $obj->source(b => 2, c => 3);
    $obj = $obj->source_ref({b => 2, c => 3});

    # get source hash (no set parameters)
    $source = $obj->source;
    $source = $obj->source_ref;

    # combine - merge targets of other Hash::Map objects into $obj target
    $obj = $obj->combine(@objects);

    # clone target
    $obj = $obj->clone_target;

    # clone source
    $obj = $obj->clone_source;

    # delete keys in target
    $obj = $obj->delete_keys( qw(x y) );
    $obj = $obj->delete_keys_ref([ qw(x y) ]);

    # copy data from source to target using keys
    $obj = $obj->copy_keys(qw(b c))
    $obj = $obj->copy_keys_ref([ qw(b c) ]);
    # including a key rewrite rule as code reference
    $obj = $obj->copy_keys(
        qw(b c),
        sub {
            my $obj = shift;
            my $key = $_;
            return "new $key";
        },
    );
    $obj = $obj->copy_keys_ref(
        [ qw(b c) ],
        sub {
            my $obj = shift;
            my $key = $_;
            return "new $key";
        },
    );

    # copy data from source (key of map) to target (value of map)
    $obj = $obj->map_keys(b => 'bb', c => 'cc');
    $obj = $obj->map_keys_ref({b => 'bb', c => 'cc'});

    # merge the given hash into target hash
    $obj = $obj->merge_hash(d => 4, e => 5);
    $obj = $obj->merge_hashref({d => 4, e => 5});

    # modify target inplace by given code
    $obj = $obj->modify(
        f => sub {
            my $obj = shift;
            my $current_value_of_key_f_in_target = $_;
            return; # $target{f} will be undef because of scalar context
        },
        ...
    );
    $obj = $obj->modify_ref({
        f => sub {
            my $obj   = shift;
            my $current_value_of_key_f_in_target = $_;
            return "new $value";
        },
        ...
    });

    # copy data from source to target using keys
    # and then
    # modify target inplace by given code
    $obj = $obj->copy_modify(
        f => sub {
            my $obj = shift;
            my $current_value_of_key_f_in_target = $_;
            return; # $target{f} will be undef because of scalar context
        },
        ...
    );
    $obj = $obj->copy_modify_ref({
        f => sub {
            my $obj   = shift;
            my $current_value_of_key_f_in_target = $_;
            return "new $value";
        },
        ...
    });
    $obj = $obj->copy_modify_identical(
        qw(b c),
        sub {
            my $obj = shift;
            my $current_value_of_each_key_in_target = $_;
            return; # $target{key} will be undef because of scalar context
        },
    );
    $obj->copy_modify_identical_ref(
        [ qw(b c) ],
        sub {
            my $obj = shift;
            my $current_value_of_each_key_in_target = $_;
            return; # $target{key} will be undef because of scalar context
        },
    );

    # copy data from source (key of map) to target (value of map)
    # and then
    # modify target inplace by given code
    $obj = $obj->map_modify(
        f => ff => sub {
            my $obj = shift;
            my $current_value_of_key_f_in_source = $_;
            return; # $target{ff} will be undef because of scalar context
        },
        ...
    );
    $obj = $obj->map_modify_ref([
        f => ff => sub {
            my $obj   = shift;
            my $current_value_of_key_f_in_source = $_;
            return "new $value";
        },
        ...
    ]);
    $obj = $obj->map_modify_identical(
        (
            f => ff,
            ...
        ),
        sub {
            my $obj = shift;
            my $current_value_of_each_key_in_source = $_;
            return; # $target{key} will be undef because of scalar context
        },
    );
    $obj = $obj->map_modify_identical_ref(
        {
            f => ff,
            ...
        },
        sub {
            my $obj   = shift;
            my $current_value_of_each_key_in_source = $_;
            return "new $value";
        },
    );

=head2 Functional style

    use Hash::Map qw(hash_map hashref_map);

    %target_hash = hash_map(
        \%source_hash,
        # The following references are sorted anyway.
        # Running in order like written.
        [ qw(key1 key2) ],               # copy_keys from source to target hash
        [ qw(key3 key4), $code_ref ],    # copy_keys, code_ref to rename keys
        {
            source_key1 => 'target_key', # map_keys from source to target hash
            source_key2 => $code_ref,    # modify values in target hash
        },
    );

Similar, only the method name and return value has changed.

    $target_hashref = hashref_map(
        $source_hashref,
        ...
    );

=head2 Automatic construction

Methods "target", "target_ref", "source", "source_ref" and "combine"
can work as constructor too.

    Hash::Map->new->target(...);
    Hash::Map->new->target_ref(...);
    Hash::Map->new->source(...);
    Hash::Map->new->source_ref(...);
    Hash::Map->new->combine(...);

shorter written as:

    Hash::Map->target(...);
    Hash::Map->target_ref(...);
    Hash::Map->source(...);
    Hash::Map->source_ref(...);
    Hash::Map->combine(...);

=head1 DESCRIPTION

For array manipulation we have map, for hashes not really.
This was the reason to create this module.

The fuctional interface is wrapped around the OO inferface.
Not all can be implemented functional.

=head1 Code example

Don't be shocked about the big examples.

If you have nearly 1 type of each mapping.
Map it like before.
Otherwise the module helps you to prevent: Don't repeat yourself.

Often we read in code something like that:

    foo(
        street       => $form->{street},
        city         => $form->{city},
        country_code => $form->{country_code} eq 'D'
                        ? 'DE'
                        : $form->{country_code},
        zip_code     => $form->{zip},
        name         => "$form->{first_name} $form->{family_name}",
        account      => $bar->get_account,
        mail_name    => $mail->{name},
        mail_address => $mail->{address},
    );

=head2 OO interface

Now we can write:

    foo(
        Hash::Map->combine(
            Hash::Map
                ->source_ref($form)
                ->copy_keys(
                    qw(street city)
                )
                ->copy_modify(
                    country_code => sub {
                        return $_ eq 'D' ? 'DE' : $_;
                    },
                ->map_keys(
                    zip => zip_code,
                )
                ->merge_hash(
                    name => "$form->{first_name} $form->{family_name}",
                ),
            Hash::Map
                ->source_ref($bar)
                ->copy_keys(
                    qw(account),
                    sub {
                        my $obj = shift;
                        my $method = "get_$_";
                        return $obj->source_ref->$method,
                    },
                ),
            Hash::Map
                ->source_ref($mail)
                ->copy_keys(
                    qw(name address),
                    sub {
                        return "mail_$_";
                    },
                ),
        )->target
    );

=head2 Functional interface

Now we can write:

    foo(
        hash_map(
            $form,
            [ qw(street city country_code) ],
            {
                country_code => sub {
                    return $_ eq 'D' ? 'DE'; $_;
                },
                zip_code     => 'zip',
            },
        ),
        name => "$form->{first_name} $form->{family_name}",
        hash_map(
            $bar,
            [
                qw(account),
                sub {
                    my $obj    = shift;
                    my $method = "get_$key";
                    return $obj->source_ref->$method;
                },
            ]
        ),
        hash_map(
            $mail,
            [
                qw(name address),
                sub {
                    return "mail_$_";
                },
            ],
        ),
    );

=head1 SUBROUTINES/METHODS

=head2 method new

A simple constructor without any parameters.

    my $obj = Hash::Map->new;

Typical you don't call method new directly.

=head2 method target

Set or get the target hash.

Can not set an empty hash, but this is the default.
Otherwise use method target_ref.

    $obj = $obj->target(%target);

    %target = $obj->target;

This method is able to construct the object first.

    Hash::Map->target(...);

=head2 method target_ref

Set or get the target hash using a hash reference.

    $obj = $obj->target_ref($target_hashref);

    $target_hashref = $obj->target_ref;

This method is able to construct the object first.

    Hash::Map->target_ref(...);

=head2 method source

Set or get the source hash.

Can not set an empty hash, but this is the default.
Otherwise use method source_ref.

    $obj = $obj->source(%source);

    %source = $obj->source;

This method is able to construct the object first.

    Hash::Map->source(...);

=head2 method source_ref

Set or get the source hash using a hash reference.

    $obj = $obj->source_ref($source_hashref);

    $source_hashref = $obj->source_ref;

This method is able to construct the object first.

    Hash::Map->source_ref(...);

=head2 method combine

Merge targets of other Hash::Map objects into $obj target.

    $obj = $obj->combine(@objects);

This method is able to construct the object first.

    Hash::Map->combine(...);

=head2 method clone_target

Using Module Clone to clone the target hash.

    $obj = $obj->clone_target;

=head2 method clone_source

Using Module Clone to clone the source hash.

    $obj = $obj->clone_source;

=head2 method delete_keys

Delete keys in target hash.

    $obj = $obj->delete_keys(@keys);

=head2 method delete_keys_ref

Delete keys in target hash.

    $obj = $obj->delete_keys_ref($keys_array_ref);

=head2 method copy_keys

Copy data from source to target hash using keys.

    $obj = $obj->copy_keys(@keys);

And rename all keys during copy.

    $obj = $obj->copy_keys(
        @keys,
        sub {
            my $obj = shift;
            my $key = $_;
            return "new $key";
        },
    );

The first parameter of the callback subroutine is the object itself.
The current key is in $_.
Return the new key.

=head2 method copy_keys_ref

Copy data from source to target hash using keys.

    $obj = $obj->copy_keys_ref($keys_array_ref);

And rename all keys during copy.

    $obj = $obj->copy_keys_ref(
        $keys_array_ref,
        sub {
            my $obj = shift;
            my $key = $_;
            return "new $key";
        },
    );

The first parameter of the callback subroutine is the object itself.
The current key is in $_.
Return the new key.

=head2 method map_keys

Copy data from source hash (key is key of map)
to target hash (key is value of map).

    $obj = $obj->map_keys(%map);

=head2 method map_keys_ref

Copy data from source hash (key is key of map)
to target hash (key is value of map).

    $obj = $obj->map_keys_ref($map_hashref);

=head2 method merge_hash

Merge the given hash into the target hash.

    $obj = $obj->merge_hash(%hash);

=head2 method merge_hashref

Merge the given hash into the target hash.

    $obj = $obj->merge_hashref($hashref);

=head2 method modify

Modify the target hash inplace by given key and code for.

The first parameter of the callback subroutine is the object itself.
The old value of the target hash is in $_;
Return the new value.

    $obj = $obj->modify(
        key1 => $code_ref1,
        ...
    );

=head2 method modify_ref

Similar to method modify.
Only the given parameter is a hash reference and not a hash.

    $obj = $obj->modify_ref({
        key1 => $code_ref1,
        ...
    });

=head2 method copy_modify

This is a combination of copy_keys and modify.

The first parameter of the callback subroutine is the object itself.
The old value of the target hash is in $_;
Return the new value.

    $obj = $obj->copy_modify(
        key1 => $code_ref1,
        ...
    );

It is not possible to rename all keys during copy.
Use method map_modify instead.

=head2 method copy_modify_ref

Similar to method copy_modify.
Only the given parameter is a hash reference and not a hash.

    $obj = $obj->copy_modify_ref({
        key1 => $code_ref1,
        ...
    });

It is not possible to rename all keys during copy.
Use method map_modify_ref instead.

=head2 method copy_modify_identical

This is another combination of copy_keys and modify.
All values are modified using a common code reference.

The 1st parameter of the callback subroutine is the object itself.
The 2nd parameter is the key.
The old value of the target hash is in $_;
Return the new value.

    $obj = $obj->copy_modify_identical(
        @keys,
        $code_ref,
    );

It is not possible to rename all keys during copy.
Use method map_modify_identical instead.

=head2 method copy_modify_identical_ref

Similar to method copy_modify_identical.
Only the given parameter is an array reference and not an array.

    $obj = $obj->copy_modify_identical_ref(
        $keys_array_ref,
        $code_ref,
    );

It is not possible to rename all keys during copy.
Use method map_modify_identical_ref instead.

=head2 method map_modify

This is a combination of map_keys and modify.

The first parameter of the callback subroutine is the object itself.
The old value of the target hash is in $_;
Return the new value.

    $obj = $obj->map_modify(
        source_key1 => target_key1 => $code_ref1,
        ...
    );

=head2 method map_modify_ref

Similar to method map_modify.
Only the given parameter is a array reference and not a array.

    $obj = $obj->map_modify_ref([
        source_key1 => target_key1 => $code_ref1,
        ...
    ]);

=head2 method map_modify_identical

This is a combination of map_keys and modify.

The 1st parameter of the callback subroutine is the object itself.
The 2nd parameter is the source key and the 3rd parameter is the target key.
The old value of the target hash is in $_;
Return the new value.

    $obj = $obj->map_modify_identical(
        source_key1 => target_key1,
        ...
        $code_ref,
    );

=head2 method map_modify_identical_ref

Similar to method map_modify_identical.
Only the given parameter is a array reference and not a array.

    $obj = $obj->map_modify_identical_ref(
        {
            source_key1 => target_key1,
            ...
        },
        $code_ref,
    );

=head2 subroutine hash_map

This subroutine is for the fuctional interface only.

    %target_hash = hash_map(
        \%source_hash,
        # The following references are sorted anyway.
        # Running in order like written.
        [ qw(key1 key2) ],               # copy_keys from source to target hash
        [ qw(key3 key4), $code_ref ],    # copy_keys, code_ref to rename keys
        {
            source_key1 => 'target_key', # map_keys from source to target hash
            source_key2 => $code_ref,    # modify values in target hash
        },
    );

=head2 subroutine hashref_map

Similar, only the method name and return value has chenged.

    $target_hashref = hashref_map(
        $source_hashref,
        ...
    );

=head1 DIAGNOSTICS

nothing

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Carp|Carp>

L<Clone|Clone>

L<Perl6::Export::Attrs|Perl6::Export::Attrs>

L<Scalar::Util|Scalar::Util>

L<Try::Tiny|Try::Tiny>

=head1 INCOMPATIBILITIES

none

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

map

=head1 AUTHOR

Steffen Winkler

inspired by: Andreas Specht C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
