#!/usr/bin/perl -s
use warnings;
use strict;
use POSIX;
use SDBM_File;

    # This program is free software: you can redistribute it and/or modify
    # it under the terms of the GNU General Public License as published by
    # the Free Software Foundation, either version 3 of the License, or
    # (at your option) any later version.

    # This program is distributed in the hope that it will be useful,
    # but WITHOUT ANY WARRANTY; without even the implied warranty of
    # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    # GNU General Public License for more details.

    # You should have received a copy of the GNU General Public License
    # along with this program.  If not, see <https://www.gnu.org/licenses/>.

our ($v, $h, $y);
print "AC/NL Catalog Tracker v1.0 Copyright 2018 Joshua Figard (https://joshuacf.cf/)\n" and exit if defined $v;
print<<EOF and exit if defined $h;
Usage: acatrack [-h -v -y]
Options
-v 	shows version information
-h 	shows this help text
-y 	auto-answer "yes" when prompted
EOF

my %closet;
my %catalog;
my $closet_file  = "closet";
my $catalog_file = "catalog";
tie %catalog,  'SDBM_File', $catalog_file,  O_CREAT|O_RDWR, 0644;
if (-e $closet_file or -e "$closet_file\.dir"){	#Two different arguments for if the DBM gets changed.
	tie %closet,  'SDBM_File', $closet_file,  O_CREAT|O_RDWR, 0644;
} else {
	makecloset();	#Lable inventory slots if a catalog.pdb doesn't exist.
}
$_ = "";

while(1) {
	print "Please give input ('o' for options): ";
	my ($mode, $item) = getinput();
	if ($mode eq "o") { menuoptions() }
	elsif ($mode eq "add") { addcloset($item); addcatalog($item); }
	elsif ($mode eq "give") { givecloset($item); }
	elsif ($mode eq "closet") { listcloset(); }
	elsif ($mode eq "catalog") { listcatalog(); }
	elsif ($mode eq "remove") { unlistcloset($item); }
	elsif ($mode eq "delete") { unlistcatalog($item); }
	elsif ($mode eq "clean") { cleanall(); }
	elsif ($mode eq "q") { exit;  } 
	else { print "Sorry, not a recognized option.\n"; }
}

##User Input subroutines
sub getinput {	#Takes user input from <STDIN> and parses it into a command and extra text.
	$_ = <STDIN>;
	chomp;
	/(\w+)\s*(.*)/;
	return($1, $2);
}

sub menuoptions {
	print<<EOF;
		Options available:
		catalog - list catalog
		closet  - list closet
		add     - add item
		give    - list and remove randomly from closet
		remove  - remove entry from closet
		delete  - delete entry from catalog
		clean - delete saved data and quit
		o - view options
		q - quit program
EOF
}

sub comfirm {
	return 1 if defined $y;
	print "Are you sure you want to do this? ";
	$_ = <STDIN>;
	if (/^y/i){
		return 1;
	}
}

##Inventory subroutines
#Catalog subroutines
sub addcatalog {
	my $item = pop;
	return if exists $catalog{$item};
	$catalog{$item} = "";
	print "$item added to catalog.\n";
}

sub incatalog {
	my $item = pop;
	if (exists $catalog{$item}){
		print "$item is already in catalog! ";
		return 1;
	}
}

sub listcatalog {
	for(sort keys %catalog){
		print "$_\n";
	}
}

sub unlistcatalog {
	return if not comfirm();
	my $item = pop;
	delete $catalog{$item};
}

#Closet subroutines
sub makecloset {
	tie %closet, 'SDBM_File', $closet_file, O_CREAT|O_RDWR, 0644;
	for my $page (1..6){ #Each 'for' adds an index. If wanted, more indexes can be added with more 'for' loops.
		for my $slot ("01".."10"){
			$closet{"$page-$slot"} = "";
		}
	}

}
sub addcloset {
	my $item = pop;
	if (incatalog($item)) {
		return if not comfirm();
	}
	foreach my $slot (sort keys %closet) {
		if ($closet{$slot} eq "") {	#Empty slot found.
			$closet{$slot} = $item;
			print "$item added to closet slot $slot.\n";
			return;
		}
	}
	print "Couldn't add $item, closet database is full.\n";
}

sub givecloset {
	my $num = pop;
	my @slots;
	for(1..$num) {
		for my $key (keys %closet) {
			@slots = (@slots, $key) if not $closet{$key} eq "";
		}
		my $item = $slots[rand @slots];
		print "$item $closet{$item}\n";
		$closet{$item} = "";
	}
}

sub listcloset {
	for(sort keys %closet) {
		print "$_:";
		print " $closet{$_}\n";
		}
}

sub unlistcloset {
	return if not comfirm();
	my $item = pop;
	if (exists $closet{$item}) {	#If user input an inventory slot
	print print "Deleted $closet{$item} in slot $item from closet.";
	$closet{$item} = "";
	}
	for my $slot (keys %closet) {	#If user input an item name.
		if ($closet{$slot} eq $item) {
			$closet{$slot} = "";
			print "Deleted $item in slot $slot from closet.\n";
			return;
		}
	}
	print "Couldn't find $item in closet.";
}

#Other subroutines

sub cleanall { 
	return if not comfirm();
	unlink glob "closet.*";
	unlink glob "catalog.*";
	exit;
}

sub END {
	untie %closet;
	untie %catalog;	
}