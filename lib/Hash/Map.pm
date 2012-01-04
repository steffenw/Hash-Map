package Hash::Map;

use strict;
use warnings;

our $VERSION = '0.001';

use Carp qw(confess);
use Clone qw(clone);
use Perl6::Export::Attrs;
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
            or confess 'Hash reference ecpected';
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
        $self->_hashref($key, $hashref);
        return $self;
    }

    return %{ $self->_hashref($key) };
}

sub target_ref { return shift->_hashref(target => @_) }
sub source_ref { return shift->_hashref(source => @_) }
sub target     { return shift->_hash(target => @_) }
sub source     { return shift->_hash(source => @_) }

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
        or confess 'Array reference ecpected';
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
        or confess 'Array reference ecpected';
    if ( ref $code_ref eq 'CODE' ) {
        return $self->map_keys_ref({
            map {
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

    if ( @keys && ref $keys[$#keys] eq 'CODE' ) {
        my $code_ref = pop @keys;
        return $self->map_keys_ref({
            map {
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
        or confess 'Hash reference ecpected';
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
        or confess 'Hash reference ecpected';
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
        or confess 'Hash reference ecpected';
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

sub hashref_map :Export {
    my ($source_ref, @more) = @_;

    my $self = Hash::Map->new->source_ref($source_ref);
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

sub hash_map :Export {
    return %{ hashref_map(@_) };
}

# $Id$

1;

__END__

=head1 NAME

Hash::Map - Manipulate Hashes

=head1 VERSION

0.001

=head1 SYNOPSIS

=head2 OO style

    require Hash::Map;

    my $obj = Hash::Map->new;

    # set target hash
    $obj = $obj->target(a => 1);
    $obj = $obj->target_ref({a => 1});

    # get target hash
    $target = $obj->target;
    $target = $obj->target_ref;

    # set source hash
    $obj = $obj->source(b => 2, c => 3);
    $obj = $obj->source_ref({b => 2, c => 3});

    # get source hash
    $source = $obj->source;
    $source = $obj->source_ref;

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

    # merge the given hash into target hash (possible overwrite some keys)
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

=head2 Function style

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

Similar, only the method name and return value has chenged.

    $target_hashref = hashref_map(
        $source_hashref,
        ...
    );

=head1 DESCRIPTION

For array manipulation we have map, for hashes not really.
This was the reason to create this module.

The fuctional interface is wrapped around the OO inferface.
Not all can be implemented functional.

=head1 Code example

Don't be shocked about the fully examples.

If you have nearly 1 type of each mapping.
Map it like before.
Otherwise the module helps you to prevent: Don't repeat yourself.

Often we read in code something like that:

    foo(
        street         => $form->{street},
        city           => $form->{city},
        country_code   => $form->{country_code} eq 'D'
                          ? 'DE'
                          : $form->{country_code},
        zip_code       => $form->{zip},
        name           => "$form->{first_name} $form->{family_name}",
        account        => $bar->get_account,
        mail_name      => $mail->{name},
        mail_address   => $mail->{address},

    );

=head2 OO interface

Now we can write:

    foo(
        Hash::Map
            ->new
            ->source_ref($form)
            ->copy_keys(
                qw(street city country_code)
            )
            ->modify(
                country_code => sub {
                    return $_ eq 'D' ? 'DE' : $_;
                },
            ->map_keys(
                zip => zip_code,
            )
            ->merge_hash(
                name => "$form->{first_name} $form->{family_name}",
            )
            ->source_ref($bar)
            ->copy_keys(
                qw(account),
                sub {
                    my $obj = shift;
                    my $method = "get_$_";
                    return $obj->source_ref->$method,
                },
            )
            ->source_ref($mail)
            ->copy_keys(
                qw(name address),
                sub {
                   return "mail_$_";
                },
            )
            ->target
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

=head2 method target

Set or get the target hash.

Can not set an empty hash, but this is the default.
Otherwise use method target_ref.

    $obj = $obj->target(%target);

    %target = $obj->target;

=head2 method target_ref

Set or get the target hash using a hash reference.

    $obj = $obj->target_ref($target_hashref);

    $target_hashref = $obj->target_ref;

=head2 method source

Set or get the source hash.

Can not set an empty hash, but this is the default.
Otherwise use method target_ref.

    $obj = $obj->source(%source);

    %source = $obj->source;

=head2 method source_ref

Set or get the source hash using a hash reference.

    $obj = $obj->source_ref($source_hashref);

    $source_hashref = $obj->source_ref;

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

    $obj = $obj->modify(key1 => $code_ref1, ...);

=head2 method modify_ref

Similar to method modify.
Only the given parameter is a hash reference and not a hash.

    $obj = $obj->modify_ref({key1 => $code_ref1, ...});
    
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
