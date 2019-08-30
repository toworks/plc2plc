#0!/usr/bin/perl

 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Data::Dumper;
 use threads;
 use threads::shared;
 use POSIX qw(strftime);
 use lib ('libs', '.');
 use logging;
 use configuration;
 use plc;
 
 my $DEBUG: shared;

 $| = 1;  # make unbuffered

 my $VERSION = "0.1 (20190828)";
 my $log = LOG->new();
 my $conf = configuration->new($log);

 $log->save('i', "program version: ".$VERSION);
 
 $DEBUG = $conf->get('app')->{'debug'};

 $SIG{'TERM'} = $SIG{'HUP'} = $SIG{'INT'} = sub {
                      local $SIG{'TERM'} = 'IGNORE';
#						$log->save('d', "SIGNAL TERM | HUP | INT | $$");
					  $log->save('i', "stop app");
                      kill TERM => -$$;
 };

 # main
 threads->new(\&main, $$, $conf, $log);

 # main loop
 {
   $log->save('i', "start main loop");

   while (threads->list()) {
#        $log->save('d', "thread main");
	   sleep(1);
	   #select undef, undef, undef, 1;
       if ( ! threads->list(threads::running) ) {
#            $daemon->remove_pid();
           $SIG{'TERM'} = 'DEFAULT'; # Восстановить стандартный обработчик
           kill TERM => -$$;
		   $log->save('i', "PID $$");
        }
    }
  }

 
 
 sub main {
    my($id, $conf, $log) = @_;
    $log->save('i', "start thread pid $id");

	# plc in create object
	my $plc_in = plc->new($log);
	$plc_in->set('DEBUG' => $DEBUG);
	$plc_in->set('host' => $conf->get('plc')->{'in'}->{host});
	$plc_in->set('port' => $conf->get('plc')->{'in'}->{port});
	$plc_in->set('rack' => $conf->get('plc')->{'in'}->{rack});
	$plc_in->set('slot' => $conf->get('plc')->{'in'}->{slot});

	$plc_in->connect() if $plc_in->get('error') == 1;

	# plc out create object
	my $plc_out = plc->new($log);
	$plc_out->set('DEBUG' => $DEBUG);
	$plc_out->set('host' => $conf->get('plc')->{'out'}->{host});
	$plc_out->set('port' => $conf->get('plc')->{'out'}->{port});
	$plc_out->set('rack' => $conf->get('plc')->{'out'}->{rack});
	$plc_out->set('slot' => $conf->get('plc')->{'out'}->{slot});

	$plc_out->connect() if $plc_out->get('error') == 1;

	while (1) {
#		$opc->connect() if $opc->get('error') == 1;
		foreach my $tag ( keys %{$conf->get('write')} ) {
#			$log->save('d', "start read tag: " . $tag) if $DEBUG;
			my $value = $plc_in->read($conf->get('read')->{$tag});
#			$log->save('d', "end read tag: " . $tag) if $DEBUG;
			if ( defined($conf->get('write')->{$tag}) ) {
#				$log->save('d', "start write tag: " . $tag) if $DEBUG;
				$plc_out->write($conf->get('write')->{$tag}, $value);
#				$log->save('d', "end write tag: " . $tag) if $DEBUG;
			}
		}
		
#		my $values = $opc->read('read');
#		$opc->write('write', $values) if defined($values);

        print "cycle: ",$conf->get('app')->{'cycle'}, "\n" if $DEBUG;
        select undef, undef, undef, $conf->get('app')->{'cycle'} || 10;
	}
  }
