#0!/usr/bin/perl

 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Data::Dumper;
 use POSIX qw(strftime);
 use lib ('libs', '.');
 use logging;
 use configuration;
 use _opc;
 
 $| = 1;  # make unbuffered

 my $log = LOG->new();
 my $conf = configuration->new($log);

 my $DEBUG = $conf->get('app')->{'debug'};


 opc_write($conf, $log, [1,'','','']);
 
 
 sub opc_write {
	my($conf, $log, $values) = @_;
	
	$log->save('i', "------ start ------");
	
	my $bof = $values->[0];

	# opc create object
	my $opc = _opc->new($log);
	$opc->set('DEBUG' => $DEBUG);
	$opc->set('progid' => $conf->get('opc')->{progid});
	$opc->set('name' => $conf->get('opc')->{name});
	$opc->set('host' => $conf->get('opc')->{host});
	$opc->set('groups' => $conf->get('groups'));

	$opc->connect();

#	$opc->read("reads");
#	exit;
		
	# установка признака 1 в конец
	push @{$values}, '1';
	# удаляем 1 элемент - номер конвертера
	splice(@{$values}, 0, 1);

	foreach (1..1000) {
		$opc->read('reads');
		select undef, undef, undef, 0.2;
	}
	#$opc->write($values->[0], [4, 3, 2, 1 , 2]);
#	$opc->write($bof, $values);
#	$opc->read($bof);
	$log->save('i', "------ stop ------");
  }
