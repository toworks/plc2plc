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

	$self->_set_all_tags($group) if ! defined($self->{opc}->{set_all_tags});

	eval{   $self->{opc}->{opcintf}->MoveToRoot;
			$self->{opc}->{opcintf}->Leafs;

			for ( my $count = 1 ; $count <= scalar @{$self->{opc}->{groups}->{$group}}; $count++ ) {
				my $item = $self->{opc}->{$group}->{items}->Item($count);
				my $_timestamp = $item->Read($OPCCache)->{'TimeStamp'};
				my $timestamp = $_timestamp->Date("yyyy-MM-dd"). " " .$_timestamp->Time("HH:mm:ss");
				my $value = sprintf("%.4f", $item->Read($OPCCache)->{'Value'} );
				$self->{log}->save('i', "read tags: group: $group    value: $value    timestamp: $timestamp");
				print "read tags: group: $group    value: $value    timestamp: $timestamp", "\n";
			}
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

  sub write {
	my($self, $bof, $values) = @_;

	$self->_set_all_tags() if ! defined($self->{opc}->{set_all_tags});

	eval{	$self->{opc}->{opcintf}->MoveToRoot;
			$self->{opc}->{opcintf}->Leafs;
=comm
			foreach my $count ( sort { $a <=> $b } keys %{$self->{opc}->{tags}->{$bof}} ) {
				my $item = $self->{opc}->{items}->Item($count);
				#print(join "\t", "write tag: ", $self->{opc}->{tags}->{$name}, "\n") if $self->{opc}->{'DEBUG'};
				$self->{log}->save('d', "write tag: $count") if $self->{opc}->{'DEBUG'};
				eval {  $item->Write('4.321') or die "$!";  };
			}
=cut
			for ( my $count = 1 ; $count <= scalar @{$self->{opc}->{tags}}; $count++ ) {
				my $item = $self->{opc}->{items}->Item($count);
				my $index = $count-1;
				eval {  $item->Write($values->[$index]) or die "$!";  };
				my $tag;
				foreach (values %{$self->{opc}->{tags}->[$index]}) {
					$tag = $_;
				}
				$self->{log}->save('i', "write tag: bof: $bof count: ".$count."\ttag: ".$tag."\tvalue: ".$values->[$index]);
			}
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

=comm
  sub _set_all_tags {
	my($self) = @_;
	eval{	$self->{opc}->{opcintf}->MoveToRoot;
			foreach my $bof ( sort { $a <=> $b } keys %{$self->{opc}->{tags}} ) {
				#print "bof: ", $bof, "\n";
				foreach my $count ( sort { $a <=> $b } keys %{$self->{opc}->{tags}->{$bof}} ) {
					my $tag = $self->{opc}->{tags}->{$bof}->{$count};
					#print "bof: $bof    count: $count tag: $tag\n";
					$self->{log}->save('d', "bof: $bof    count: $count    tag: $tag") if $self->{opc}->{'DEBUG'};
					$self->{opc}->{items}->AddItem($tag, $count);
				}
			}
			$self->{opc}->{set_all_tags} = 1;
			$self->{opc}->{error} = 0;
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }
=cut

  sub _set_all_tags {
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
			$self->{opc}->{set_all_tags} = 1;
			$self->{opc}->{error} = 0;
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }
}
1;
