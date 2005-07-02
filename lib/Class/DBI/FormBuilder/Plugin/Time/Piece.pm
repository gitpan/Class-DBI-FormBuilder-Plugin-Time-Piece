package Class::DBI::FormBuilder::Plugin::Time::Piece;
use strict;
use warnings;

use Class::DBI::FormBuilder 0.32 ();

our $VERSION = '0.03';

sub field {
	my($class,$them,$form,$field) = @_;
	my $type = $them->column_type($field);

	# this is called as a class method
	# there's no data to get, so just create the empty field
	unless(ref $them) {
		return $form->field(
			name		=>	$field,
			value		=>	'',
			required	=>	0, # ??
			validate	=>	{
					date		=>	'/^(?:|\d{4}-\d\d-\d\d)$/',
					time		=>	'/^(?:|\d\d:\d\d:\d\d)$/',
					datetime	=>	'/^(?:|\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)$/',
					timestamp	=>	'/^(?:|\d{14})$/',
				}->{$type},
		);
	}

	my $value = $them->$field.''; # lousy default
	my $validate = undef;
	my $required = 0;
	if($type eq 'time') {
		if(UNIVERSAL::can($them->$field,'hms')) {
			$value		= $them->$field->hms;
			$validate	= '/^\d\d:\d\d:\d\d$/';
			$required	= 1;
		} else {
			$value		= '';
			$validate	= '/^(?:|\d\d:\d\d:\d\d)$/';
			$required	= 0;
		}
	} elsif($type eq 'date') {
		if(UNIVERSAL::can($them->$field,'ymd')) {
			$value		= $them->$field->ymd;
			$validate	= '/^(?:|\d{4}-\d\d-\d\d)$/';
			$required	= 1;
		} else {
			$value		= '';
			$validate	= '/^(?:|\d{4}-\d\d-\d\d)$/';
			$required	= 0;
		}
	} elsif($type eq 'timestamp') {
		if(UNIVERSAL::can($them->$field,'strftime')) {
			$value		= $them->$field->strftime('%Y%m%d%H%M%S');
			$validate	= '/^\d{14}$/';
			$required	= 1;
		} else {
			$value		= '';
			$validate	= '/^(?:|\d{14})$/';
			$required	= 0;
		}
	} elsif($type eq 'datetime') {
		if(UNIVERSAL::can($them->$field,'strftime')) {
			$value		= $them->$field->strftime('%Y-%m-%d %H:%M:%S');
			$validate	= '/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$/';
			$required	= 1;
		} else {
			$value		= '';
			$validate	= '/^(?:|\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)$/';
			$required	= 0;
		}
	} else {
		die "don't understand column type '$type'";
	}

	$form->field(
		name		=>	$field,
		value		=>	$value,
		required	=>	$required,
		validate	=>	$validate,
	);
}


1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::DBI::FormBuilder::Plugin::Time::Piece - Output Dates/Times Properly

=head1 SYNOPSIS

  Class::DBI::FormBuilder::Plugin::Time::Piece->require;
  my $ok = Class::DBI::FormBuilder::Plugin::Time::Piece->field();

=head1 DESCRIPTION

This is called implicitly by CDBI::FormBuilder 0.32 and later, when it encounters
a Time::Piece object as a has_a field within a Class::DBI object/class. When that happens,
Class::DBI::FormBuilder::Plugin::Time::Piece->field($obj,$form,$field) is called.



=head2 my $ok = $class->field($obj,$form,$field)

Like all CDBI::FB plugins, this holds one crucial sub: field(), which is called implicitly
upon CDBI::FB finding a Time::Piece object in a has_a relationship within a Class::DBI
object/class. This routine will accept the object for which a form is being created,
the CGI::FormBuilder object we're working with, and the field in question. field() is
then expected to call (and return the return value of) $form->field(%args). As a result, a
text field will be created within the form.

At this point, CDBI::FB::Plugin::Time::Piece serializes itself based upon MySQL
types. Patches are most welcome!

WARNING: We call column_type() on $obj, so it must be a Class::DBI::mysql object, or 
it needs to have used Class::DBI::Plugin::Type.

=head1 SEE ALSO

Class::DBI, CGI::FormBuilder, Class::DBI::FormBuilder

=head1 AUTHOR

James Tolley, E<lt>james@bitperfect.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by James Tolley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
