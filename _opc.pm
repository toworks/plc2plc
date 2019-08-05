package _opc;{ 
  use strict;
  use warnings;
  use utf8;
  use lib 'libs';
  use parent "opc";
  use Win32::OLE::OPC qw($OPCCache $OPCDevice);
  use Data::Dumper;


  sub read {
	my($self, $group) = @_;

	print Dumper($self->{opc}->{tags}) if $self->{opc}->{'DEBUG'};
	
	$self->_set_group_tags($group) if ! defined($self->{opc}->{tags}->{$group});
	
	my @values;

	eval{   $self->{opc}->{opcintf}->MoveToRoot;
			$self->{opc}->{opcintf}->Leafs;

			for ( my $count = 1 ; $count <= scalar @{$self->{opc}->{groups}->{$group}}; $count++ ) {
				my $item = $self->{opc}->{$group}->{items}->Item($count);
				my $_timestamp = $item->Read($OPCCache)->{'TimeStamp'};
				my $timestamp = $_timestamp->Date("yyyy-MM-dd"). " " .$_timestamp->Time("HH:mm:ss");
				my $value = $item->Read($OPCCache)->{'Value'};
				$values[$count-1] = $value;
				$self->{log}->save('i', "read tags: group: $group    value: $value    timestamp: $timestamp") if $self->{opc}->{'DEBUG'};
#				print "read tags: group: $group    value: $value    timestamp: $timestamp", "\n" if $self->{opc}->{'DEBUG'};
			}
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
	print Dumper(@values) if $self->{opc}->{'DEBUG'};
	return \@values || undef;
  }

  sub write {
	my($self, $group, $values) = @_;

	$self->_set_group_tags($group) if ! defined($self->{opc}->{tags}->{$group});

	eval{	$self->{opc}->{opcintf}->MoveToRoot;
			$self->{opc}->{opcintf}->Leafs;
			for ( my $count = 1 ; $count <= scalar @{$self->{opc}->{groups}->{$group}}; $count++ ) {
				my $item = $self->{opc}->{$group}->{items}->Item($count);
				my $index = $count-1;
				eval {  $item->Write($values->[$index]) or die "$!";  };
				my $tag = $self->{opc}->{groups}->{$group}->[$index];
				$self->{log}->save('i', "write tags: group: $group\tcount: ".$count."\ttag: ".$tag."\tvalue: ".$values->[$index]) if $self->{opc}->{'DEBUG'};
			}
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

  sub _set_group_tags {
	my($self, $group) = @_;
	eval{
	print Dumper( \@{$self->{opc}->{groups}->{$group}} );
			$self->{opc}->{opcintf}->MoveToRoot;
			for ( my $count = 1 ; $count <= scalar @{$self->{opc}->{groups}->{$group}}; $count++ ) {
				my $tag = $self->{opc}->{groups}->{$group}->[$count-1];
				$self->{opc}->{$group}->{items}->AddItem($tag, $self->{opc}->{opcintf});
				#print "count: $count tag: $tag\n";
				$self->{log}->save('d', "add tag: count: $count    tag: $tag") if $self->{opc}->{'DEBUG'};
			}
			$self->{opc}->{tags}->{$group} = 1;
			$self->{opc}->{error} = 0;
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }
}
1;
