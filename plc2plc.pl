#0!/usr/bin/perl

 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Data::Dumper;
 use threads;
 use threads::shared;
 use Time::HiRes qw(gettimeofday tv_interval time);
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

	# plc out create object
	my $plc_out = plc->new($log);
	$plc_out->set('DEBUG' => $DEBUG);
	$plc_out->set('host' => $conf->get('plc')->{'out'}->{host});
	$plc_out->set('port' => $conf->get('plc')->{'out'}->{port});
	$plc_out->set('rack' => $conf->get('plc')->{'out'}->{rack});
	$plc_out->set('slot' => $conf->get('plc')->{'out'}->{slot});

	while (1) {
		my $t0 = [gettimeofday];
		$plc_in->connect() if $plc_in->get('error') == 1;
		foreach my $tag ( keys %{$conf->get('write')} ) {
			my $t0_read = [gettimeofday];
			my $value = $plc_in->read($conf->get('read')->{$tag}) if $plc_in->get('error') != 1;
			my $t1_read = [gettimeofday];
			my $tread_between = tv_interval $t0_read, $t1_read;
			$log->save('d', "read:    time:  $tread_between  tag: $tag") if $DEBUG;
			if ( defined($conf->get('write')->{$tag}) ) {
				$plc_out->connect() if $plc_out->get('error') == 1;
				my $t0_write = [gettimeofday];
				$plc_out->write($conf->get('write')->{$tag}, $value) if $plc_out->get('error') != 1;
				my $t1_write = [gettimeofday];
				my $twrite_between = tv_interval $t0_read, $t1_read;
			    $log->save('d', "write:    time: $twrite_between  tag: $tag") if $DEBUG;
			}
		}
		#$plc_in->disconnect();
		#$plc_out->disconnect();
		my $t1 = [gettimeofday];
		my $tbetween = tv_interval $t0, $t1;
		my $cycle;
		if ( $tbetween < $conf->get('app')->{'cycle'} ) {
			$cycle = $conf->get('app')->{'cycle'} - $tbetween;
		} else {
			$cycle = 0;
		}

		$log->save('d', "cycle:  setting: ". $conf->get('app')->{'cycle'} ."  current: ". $cycle) if $DEBUG;
        print "cycle:  setting: ", $conf->get('app')->{'cycle'}, "  current: ", $cycle, "\n" if $DEBUG;
        select undef, undef, undef, $cycle;
	}
  }
