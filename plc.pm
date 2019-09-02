package plc;{ 
  use strict;
  use warnings;
  use utf8;
  use Nodave;
  use Data::Dumper;

  sub new {
    my($class, $log) = @_;
    my $self = bless {	'plc' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }

  sub get {
    my($self, $name) = @_;
    return $self->{plc}->{$name};
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{plc}->{$key} = $set{$key};
    }
  }

  sub connect {
	my($self) = @_;
	
	# MPI address of PLC
	my $plcMPI = 2;
	# MPI address of Adapter  (for IBH/MHJ NetLink it MUST be 0)
	my $localMPI = 0;
	
	# The protocol to be used on your interface:
	my $useProto = daveProtoISOTCP;	# ISO over TCP for 300/400 family, VIPA Speed 7, SAIA Burgess
	#$useProto=daveProtoISOTCP243;	# ISO over TCP for CP 243

    eval{
		if ( $self->{plc}->{'DEBUG'} ) {
			Nodave::daveSetDebug(Nodave::daveDebugAll);
		} else {
			Nodave::daveSetDebug(0);
		}
		
		$self->{log}->save('d', "debug level is: ".Nodave::daveGetDebug()) if $self->{plc}->{'DEBUG'};
		$self->{plc}->{ph} = Nodave::openSocket($self->{plc}->{port}, $self->{plc}->{host}) or die "$!";
		$self->{plc}->{di} = Nodave::daveNewInterface($self->{plc}->{ph}, $self->{plc}->{ph}, "asdf", $localMPI, $useProto, daveSpeed187k) or die "$!";
		my $res = Nodave::daveInitAdapter($self->{plc}->{di});
		exit 1 if $res != 0;
		$self->{plc}->{dc} = Nodave::daveNewConnection($self->{plc}->{di}, $plcMPI , $self->{plc}->{rack}, $self->{plc}->{slot}) or die "$!";
		$res = Nodave::daveConnectPLC($self->{plc}->{dc});
		exit 1 if $res != 0;
		$self->{plc}->{error} = 0;
		$self->{log}->save('i', "connect: ".$self->{plc}->{host});
	};
	if($@) { $self->{plc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

  sub disconnect {
	my($self) = @_;
    eval{
			Nodave::daveDisconnectPLC($self->{plc}->{dc});
			Nodave::daveDisconnectAdapter($self->{plc}->{di});
			Nodave::closeSocket($self->{plc}->{ph});
			$self->{plc}->{error} = 1;
			$self->{log}->save('i', "disconnect: ".$self->{plc}->{host});
	};
	if($@) { $self->{plc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

  sub dec {
	my($self, $hex) = @_;
	#return hex(unpack "H*", $hex);
	my $value = hex(unpack "H*", $hex);
	$value -= 0x1000000 if $value >= 0x800000;
	return $value;
  }

  sub read {
	my($self, $tag) = @_;
	my $result;
	if ( defined($tag->{db}) ) {
		eval {
				my ($value, $res) = Nodave::daveReadBytes(	$self->{plc}->{dc},
															daveDB,
															$tag->{db},
															$tag->{start},
															$tag->{bytes} );
				if ($res == 0) {
					$result = Nodave::daveGetS8($self->{plc}->{dc}) if $tag->{bytes} == 1;
					$result = Nodave::daveGetS16($self->{plc}->{dc}) if $tag->{bytes} == 2;
					$result = Nodave::daveGetS32($self->{plc}->{dc}) if $tag->{bytes} == 4;

					#$value = $self->dec($value);
					print scalar time ." ", "val = ", $result, "\n";
					$self->{log}->save('i', "read tag: DB: $tag->{db}  start: $tag->{start}  bytes: $tag->{bytes}    value: $result") if $self->{plc}->{'DEBUG'};
				} else {
					$self->{log}->save('e', "result: $res    error: ".Nodave::daveStrerror($res));
				}
		};
		if($@) { 	$self->{plc}->{error} = 1;
					$self->{log}->save('e', "$@"); 
					$self->disconnect; }
	}
	
	if ( defined($tag->{m}) ) {
		# DB14.DBX5.4 I have to:
		# dc.readBits(libnodave.daveDB, 14, 44, 1, null);
		# (5 * 8) + 4 = 44
		# 492.0, 492.1...etc if I read 1 bit at a time?
		# Reading 1 bit at a time, with daveReadBits, you have to set the start address to 8*492+0, 8*492+1... etc.
=comm
		my($aaa,$res)=Nodave::daveReadBits($self->{plc}->{dc}, daveFlags, 8*$tag->{m}+$tag->{bit}, 1);
		
		$self->{log}->save('e', Nodave::daveStrerror($res)) if $res != 0;
		
		my @abuf2=unpack("C*",$aaa);
		print "res: $res ok 9\n";
		printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));
		if ($res==0) {	
			for (my $i=0; $i<@abuf2; $i++) {
				$result = $abuf2[$i];
				printf "position %d = %d \n", $i, $result;
				$self->{log}->save('i', "read tag: M: $tag->{m}  bit: $tag->{bit}    value: $result") if $self->{plc}->{'DEBUG'};
			}
		}
=cut
		eval {
				my ($value, $res) = Nodave::daveReadBytes(	$self->{plc}->{dc},
															daveFlags,
															0,
															$tag->{m},
															1 );
				
				$self->{log}->save('e', Nodave::daveStrerror($res)) if $res != 0;

		#		print "----\n", scalar reverse unpack("B*", $value), "\n----\n";
		#		print "read tag: M: $tag->{m}  bit: $tag->{bit}    value: ". unpack("B8",$res) ."\n" if $self->{plc}->{'DEBUG'};
				my @buf = split ('',  scalar reverse unpack("B*", $value));
		#		printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));
				if ($res == 0) {
					$result = $buf[$tag->{bit}];
					printf "position %d = %d \n", $tag->{bit}, $result if $self->{plc}->{'DEBUG'};
					$self->{log}->save('i', "read tag: M: $tag->{m}  bit: $tag->{bit}    value: $result") if $self->{plc}->{'DEBUG'};
				} else {
					$self->{log}->save('e', "result: $res    error: ".Nodave::daveStrerror($res));
				}
		};
		if($@) { 	$self->{plc}->{error} = 1;
					$self->{log}->save('e', "$@"); 
					$self->disconnect; }
	}
	return $result;
  }

  sub write {
	my($self, $tag, $value) = @_;

	if ( defined($tag->{db}) and  defined($tag->{bytes}) ) {
		eval {
				if ( $tag->{type} =~ /int/i ) {
					$value = Nodave::daveSwapIed_8($value) if $tag->{bytes} == 1;
					$value = Nodave::daveSwapIed_16($value) if $tag->{bytes} == 2;
					$value = Nodave::daveSwapIed_32($value) if $tag->{bytes} == 4;
				}
				if ( $tag->{type} =~ /float|real/i ) {
					$value = Nodave::daveToPLCfloat($value);
				}

				print $value, "|--\n";
				$value = pack("L*", $value);
				my $res = Nodave::daveWriteBytes(	$self->{plc}->{dc},
													daveDB,
													$tag->{db},
													$tag->{start},
													$tag->{bytes},
													$value );
				printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res)) if $self->{plc}->{'DEBUG'};
				if ($res == 0) {
					$self->{log}->save('i', "write tag: DB: $tag->{db}  start: $tag->{start}  bytes: $tag->{bytes}    value: $value") if $self->{plc}->{'DEBUG'};
				} else {
					$self->{log}->save('e', "result: $res    error: ".Nodave::daveStrerror($res));
				}
		};
		if($@) { 	$self->{plc}->{error} = 1;
					$self->{log}->save('e', "$@"); 
					$self->disconnect; }
	}

	if ( defined($tag->{bit}) ) {
		eval {
				my ($areas, $msg, $msg_error, $db, $bit);
				if ( defined($tag->{db}) ) {
					$areas = daveDB;
					$db = $tag->{db};
					$bit = (8*$tag->{start})+$tag->{bit};
				}
				if ( defined($tag->{m}) ) {
					$areas = daveFlags;
					$db = 0;
					# m18.0 = 8*18+0 = 144
					$bit = (8*$tag->{m})+$tag->{bit};
				}

				$value = '' if $value eq 0; # bit 0 -> empty or undef
				my $res = Nodave::daveWriteBits(	$self->{plc}->{dc},
													$areas,
													$db,
													$bit,
													1,
													$value );
				printf("function %s result:%d=%s\n", "$areas", $res, Nodave::daveStrerror($res)) if $self->{plc}->{'DEBUG'};
				if ($res == 0) {
					$value = 0 if $value eq '';
					$msg = "write $areas tag: DB: $tag->{db}  start: $tag->{start}  bit: $tag->{bit}    value: $value" if defined($tag->{db});
					$msg = "write $areas tag: M: $tag->{m}  bit:  $tag->{bit}  address: $bit    value: $value" if defined($tag->{m});
					$self->{log}->save('i', $msg) if $self->{plc}->{'DEBUG'};
				} else {
					$msg_error = "    DB: $tag->{db}  start: $tag->{start}  bit: $tag->{bit}" if defined($tag->{db});
					$msg_error = "    M: $tag->{m}  bit:  $tag->{bit}  address: $bit" if defined($tag->{m});
					$self->{log}->save('e', "result: $res    error: ". Nodave::daveStrerror($res). $msg_error);
				}
		};
		if($@) { 	$self->{plc}->{error} = 1;
					$self->{log}->save('e', "$@"); 
					$self->disconnect; }
	}
  }
}
1;
