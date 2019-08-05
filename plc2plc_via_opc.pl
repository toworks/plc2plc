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
 use _opc;
 
 my $DEBUG: shared;

 $| = 1;  # make unbuffered

 my $VERSION = "0.1 (20190805)";
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

	# opc create object
	my $opc = _opc->new($log);
	$opc->set('DEBUG' => $DEBUG);
	$opc->set('progid' => $conf->get('opc')->{progid});
	$opc->set('name' => $conf->get('opc')->{name});
	$opc->set('host' => $conf->get('opc')->{host});
	$opc->set('groups' => $conf->get('groups'));

	while (1) {
		$opc->connect() if $opc->get('error') == 1;

		my $values = $opc->read('read');
		$opc->write('write', $values) if defined($values);

        print "cycle: ",$conf->get('app')->{'cycle'}, "\n" if $DEBUG;
        select undef, undef, undef, $conf->get('app')->{'cycle'} || 10;
	}
  }
