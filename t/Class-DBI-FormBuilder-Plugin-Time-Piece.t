use strict;
no warnings ;#FATAL => 'all';
$^W = 0;

use Test::More;
use DBI;

use Class::DBI::FormBuilder 0.32 ();

my @DSN;
my $dbh;

BEGIN {
	my $dbname = $ENV{DBD_MYSQL_DBNAME}	|| 'test';
	my $db		= "dbi:mysql:$dbname";
	my $user	=  $ENV{DBD_MYSQL_USER}		|| '';
	my $pass	=  $ENV{DBD_MYSQL_PASSWD}	|| '';

	@DSN = ($db, $user, $pass, {RaiseError=>1});

	eval {
		$dbh = DBI->connect(@DSN) or die $DBI::errstr;
		$dbh->do(qq[ DROP TABLE IF EXISTS movies ]);
		$dbh->do(qq[
		     CREATE TABLE movies (
    	    	id     int(2) unsigned not null primary key auto_increment,
    	    	title  VARCHAR(255),
    	    	d   date,
    	    	t   time,
    	    	dt  datetime,
    	    	ts  timestamp
    		 )
		]) or die $DBI::errstr;
	};
	plan $@ ? (skip_all => 'needs a mysql account with create/drop table privs for testing') : (tests => 7);
}

# clean the db
END {
	$dbh->do(q{ DROP TABLE movies });
};


package My::Film;

use base 'Class::DBI::mysql';
use Class::DBI::FormBuilder;
use Time::Piece::MySQL;

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('movies');
__PACKAGE__->columns(All => qw/id title d t dt ts/);

__PACKAGE__->autoinflate(dates => 'Time::Piece');

__PACKAGE__->has_a(t => 'Time::Piece',
	inflate => sub { Time::Piece->strptime(shift,'%H:%M:%S') },
	deflate => sub { shift->strftime('%H:%M:%S') },
);

package main;

my $null = My::Film->create({
	title	=> 'NULL',
	d		=>	undef,
	t		=>	undef,
	dt		=>	undef,
	ts		=>	undef,
}) or die "failed to create object";

my $not_null = My::Film->create({
	title	=>	'NOT NULL',
	d		=>	'2001-01-01',
	t		=>	'11:11:11',
	dt		=>	'2002-02-02 12:12:12',
	ts		=>	'20010101121212',
}) or die "failed to create object";

my $null_form = $null->as_form->render;
print $null_form;
ok($null_form =~ /name="d" type="text" value=""/,"date IS NULL");
ok($null_form =~ /name="t" type="text" value=""/,"time IS NULL");
ok($null_form =~ /name="dt" type="text" value=""/,"datetime IS NULL");

my $not_null_form = $not_null->as_form->render;
print "\n\n".$not_null_form;
ok($not_null_form =~ /name="d" type="text" value="2001-01-01"/,"date IS NOT NULL");
ok($not_null_form =~ /name="t" type="text" value="11:11:11"/,"time IS NOT NULL");
ok($not_null_form =~ /name="dt" type="text" value="2002-02-02 12:12:12"/,"datetime IS NOT NULL");
ok($not_null_form =~ /name="ts" type="text" value="\d{14}"/,"timestamp IS NOT NULL");

__END__