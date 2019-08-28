use Nodave;
use strict;




sub _read () {
my ($plcMPI, $localMPI, $ip_address, $rack, $slot, $ip_port, $useProto);
#
# Adjust these variables to your needs:
#
# MPI address for MPI/PPI connections:
#
$plcMPI=2;	# MPI address of PLC
$localMPI=0;	# MPI address of Adapter  (for IBH/MHJ NetLink it MUST be 0)
#
# IP address for TCP connections (CP x43 or NetLink)
#
$ip_address='10.21.118.213'; #left
#$ip_address='10.21.118.214'; #right
$rack=0;	# rack the CPU is in (ISO over TCP only)
$slot=3;	# slot the CPU is in (ISO over TCP only, 3 for some S7-400)
#
# IP port for TCP connections (CP x43 or NetLink)
#
$ip_port=102;	# ISO over TCP for S7 CPx43, VIPA Speed 7, SAIA Burgess
#$ip_port=1099;	# MPI/PPI over IBH/MHJ NetLink MPI to Ethernet Gateways
#
# The protocol to be used on your interface:
#
#$useProto=daveProtoMPI;		# MPI with MPI or TS adapter
#$useProto=daveProtoMPI2;	# MPI with MPI (or TS?) adapter. Try if daveProtoMPI does not work.
#$useProto=daveProtoPPI;	# PPI (S7-200) with PPI cable
$useProto=daveProtoISOTCP;	# ISO over TCP for 300/400 family, VIPA Speed 7, SAIA Burgess
#$useProto=daveProtoISOTCP243;	# ISO over TCP for CP 243
#$useProto=daveProtoMPI_IBH;	# IBH/MHJ NetLink MPI to Ethernet Gateways on MPI/Profibus
#$useProto=daveProtoPPI_IBH;	# IBH/MHJ NetLink MPI to Ethernet Gateways on PPI
#
# Shall the library print out debug information?
# Use daveDebugAll and save the output if you want to report problems.
#
# for TCP/IP connections uncomment openSocket, comment out setPort below.
#
print "set debug level\n";
#Nodave::daveSetDebug(Nodave::daveDebugAll);
Nodave::daveSetDebug(0);

$a=Nodave::daveGetDebug();
print "debug level is: $a\n";
my $ph;
#
# open a serial port or a TCP/IP connection:
#
#$ph=Nodave::setPort("/dev/ttyS0","9600",'E');  # for PPI
#$ph=Nodave::setPort("/dev/ttyS0","38400",'O');
$ph=Nodave::openSocket($ip_port, $ip_address);	# for ISO over TCP or MPI or PPI over IBH NetLink
print "port handle: $ph\n";

my ($a, $res, $di, $dc, $i, @partnerBuf, $partnerList, $by, $el, $SZlen, $row, $SZcount);
my ($answLen, $index, $id, $szl, $orderCode, $x, $pdu, $resultSet, $wbuf, @testbuf2, @values);
my ($asd, @abuf2, $aaa, $buf2);

$di=Nodave::daveNewInterface($ph,$ph,"asdf", $localMPI, $useProto, daveSpeed187k);
print "di: $di ok 5\n";

$res=Nodave::daveInitAdapter($di);
print "res: $res ok 6\n";

$dc=Nodave::daveNewConnection($di, $plcMPI , $rack, $slot);
print "dc: $dc ok 7\n";

$res=Nodave::daveConnectPLC($dc);
print "connect to PLC. function result: $res\n";
#
# Simplest usage of readBytes: result goes into an internal buffer.
#
#Nodave::daveSetDebug(65535);
#
$res=Nodave::daveReadBytes($dc,daveFlags,0,0,16);
print "read from PLC. function result: $res\n";
#
# List usage of readBytes: result goes into an internal buffer, but you also get a scalar value
# that contains the result bytes as a string:
#
($buf2,$res)=Nodave::daveReadBytes($dc,daveInputs,0,0,4); # valid, may be called with or without a buffer
#
# Unpacking and showing the result string:
#
@abuf2=unpack("C*",$buf2);
#
print "res: $res ok 9\n";
for ($i=0; $i<@abuf2; $i++) {
    printf "position %d = %d \n", $i,$abuf2[$i];
}

printf("Trying to read a bit from I0.2\n");
#
#Nodave::daveSetDebug(65535);
#
($aaa,$res)=Nodave::daveReadBits($dc, daveInputs, 0, 2);
@abuf2=unpack("C*",$aaa);
print "res: $res ok 9\n";
printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));
if ($res==0) {	
for ($i=0; $i<@abuf2; $i++) {
    printf "position %d = %d \n", $i,$abuf2[$i];
}
}

if ($res==0) {	
    print $dc,"\n";
    $asd=Nodave::daveGetU8($dc);
    printf("Bit: %d\n",$asd);
}	


printf("Trying to stop the PLC\n");
$res=Nodave::daveStop($dc);
printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));

printf("Trying to start the PLC\n");
$res=Nodave::daveStart($dc);
printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));

while ( 1 ) {

	($aaa,$res)=Nodave::daveReadBytes($dc,daveDB,82,14,2);
	
	my $val = hex(unpack "H*", $aaa), "\n";
	print "val = ", $val, "\n";
=comm
	@abuf2=unpack("C*",$aaa);
	print "res: $res ok 100\n";
	printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));
	if ($res==0) {	
		for ($i=0; $i<@abuf2; $i++) {
			printf "position %d = %d \n", $i,$abuf2[$i];
		}
	}
=cut
	($aaa,$res)=Nodave::daveReadBytes($dc,daveFlags,0,0,2);
	@abuf2=split ('',  unpack("B*",$aaa));
	print "res: $res ok 101\n";
	printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));
	if ($res==0) {	
		printf "position %d = %d \n", 7, $abuf2[7];
		&_write($val);
#		for ($i=0; $i<@abuf2; $i++) {
#			printf "position %d = %d \n", $i, $abuf2[$i];
#		}
	}
	
	select undef, undef, undef, 0.5;
}

$res=Nodave::daveDisconnectPLC($dc);
$res=Nodave::daveDisconnectAdapter($di);
$res=Nodave::closeSocket($ph);


}


_read;
#exit;

#&_write;


sub _write()  {
	my $val = shift;


######################
my ($plcMPI, $localMPI, $ip_address, $rack, $slot, $ip_port, $useProto);
#
# Adjust these variables to your needs:
#
# MPI address for MPI/PPI connections:
#
$plcMPI=2;	# MPI address of PLC
$localMPI=0;	# MPI address of Adapter  (for IBH/MHJ NetLink it MUST be 0)
#
# IP address for TCP connections (CP x43 or NetLink)
#
$ip_address='10.21.122.135';
$rack=0;	# rack the CPU is in (ISO over TCP only)
$slot=1;	# slot the CPU is in (ISO over TCP only, 3 for some S7-400)
#
# IP port for TCP connections (CP x43 or NetLink)
#
$ip_port=102;	# ISO over TCP for S7 CPx43, VIPA Speed 7, SAIA Burgess

$useProto=daveProtoISOTCP;	# ISO over TCP for 300/400 family, VIPA Speed 7, SAIA Burgess

print "set debug level\n";
#Nodave::daveSetDebug(Nodave::daveDebugAll);
Nodave::daveSetDebug(0);

$a=Nodave::daveGetDebug();
print "debug level is: $a\n";
my $ph;
#
# open a serial port or a TCP/IP connection:
#

$ph=Nodave::openSocket($ip_port, $ip_address);	# for ISO over TCP or MPI or PPI over IBH NetLink
print "port handle: $ph\n";

my ($a, $res, $di, $dc, $i, @partnerBuf, $partnerList, $by, $el, $SZlen, $row, $SZcount);
my ($answLen, $index, $id, $szl, $orderCode, $x, $pdu, $resultSet, $wbuf, @testbuf2, @values);
my ($asd, @abuf2, $aaa, $buf2);

$di=Nodave::daveNewInterface($ph,$ph,"asdf", $localMPI, $useProto, daveSpeed187k);
print "di: $di ok 5\n";

$res=Nodave::daveInitAdapter($di);
print "res: $res ok 6\n";

$dc=Nodave::daveNewConnection($di, $plcMPI , $rack, $slot);
print "dc: $dc ok 7\n";

$res=Nodave::daveConnectPLC($dc);
print "connect to PLC. function result: $res\n";
#
# Simplest usage of readBytes: result goes into an internal buffer.
#
#Nodave::daveSetDebug(65535);
#
$res=Nodave::daveReadBytes($dc,daveFlags,0,0,16);
print "read from PLC. function result: $res\n";

=comm
my $count=0;
while (1) {

my @values;
@values = ("50") if $count == 0;
@values = ("1111") if $count == 1;
@values = ("3333") if $count == 2;
@values = ("9911") if $count == 3;
=cut
my @values = ($val);
print $values[0], "--\n";
$values[0]=Nodave::daveSwapIed_16($values[0]);
print $values[0], "|--\n";
#$wbuf=pack("H*",@values);
print $wbuf, "--\n";
$wbuf=pack("L*", @values);

#$wbuf=unpack("H2",$values);

#my $out = pack "c", $values;
#$wbuf = unpack "H2", $out; 

#Nodave::daveGetU16($dc)

	$res=Nodave::daveWriteBytes($dc,daveDB,10,16,2,$wbuf);
	printf("function result:%d=%s\n", $res, Nodave::daveStrerror($res));
#	$count++;
#	$count = 0 if $count == 4;
#	select undef, undef, undef, 0.9;
#}

$res=Nodave::daveDisconnectPLC($dc);
$res=Nodave::daveDisconnectAdapter($di);
$res=Nodave::closeSocket($ph);

}