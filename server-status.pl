#!/usr/bin/perl
=cut
	Apache Server-Status Collector
	XMPP: pype@0day.rocks
	ref: https://httpd.apache.org/docs/2.4/mod/mod_status.html
=cut
use warnings;
use LWP::UserAgent;


my $ua = LWP::UserAgent->new(ssl_opts => { SSL_verify_mode => 0},); # Accept HTTPS targets without error messages / LWP::Simple have the same option? 

sub uniq {my %s;grep !$s{$_}++, @_;} # remove duplicates / thx SoF

sub banner {
	print "\nApache Server-Status Collector:\n";
	print "Usage => perl $0 http://zebussa.com/server-status\n\n";
	exit(0);	
}

sub test_con {
	my $th = shift;

	my $test_req = HTTP::Request->new(GET=>$th);
	my $test_con = $ua->request($test_req);
	if ($test_con->is_success) {

		print "[-] Failed to obtain information from server\n" and exit unless ($test_con->content =~ m/Server Version:(.*?)\<\/dt>/ms);
		print "[+] Target 	-> $th\n";
		print "[+] INFO 	->$1";

		my @vhosts = uniq $test_con->content =~ /\<\/td\>\<td nowrap\>(.*?)\<\/td\>\<td/g;
		print "\n[+] VHosts 	-> /";
		foreach(@vhosts){ print " $_ /"; }
		return @vhosts;
				
	}else {
		print "[-] Failed to obtain information from server\n";
	}
}

sub l00p_collector {
	my $url = shift;
	my $hosts = shift;
	my $l00p_req = HTTP::Request->new(GET=>$url);
	
	%arrang; # bad mod for globals
	foreach (@{$hosts}){
		$arrang{'$_'} = {};
	}

	$| = 1;
	while(1){
		my $l00p_con = $ua->request($l00p_req);
		if ($l00p_con->is_success) {
			foreach(@{$hosts}){
				my $thost = $_;
				print "\n\n[+] $thost \n";
				#sleep(2);
				print "\n\n[-] Failed Match $_\n" unless (my @tmp = uniq $l00p_con->content =~ /nowrap\>$_\<\/td>\<td nowrap\>\S+ (.*?) HTTP/g);
				foreach(@tmp){
					print "	-> $_\n";
					push(@{$arrang{$thost}}, $_);
				}
			}
		}else{
			print "\n\n[-] Failed for some reason :(\n";
			exit(1);
		}
	}
}

my $host = shift || banner();

print "\nApache Server-Status Collector:\n\n";
my @vh = test_con($host);
print "\n\nStarting, press Crtl+C to stop.\n\n";

$SIG{'INT'} = sub { 
	print "Stoping, arranging the URIs";

	foreach(@vh){
		my $arr_t = $_;
		print "-"x50 . "\n\n[+] $arr_t\n" . "\n";
		my @arr_l = sort { (lc($a) cmp lc($b)) or ($a cmp $b) }uniq @{$arrang{$_}}; #<- thx monks
		foreach(@arr_l){
			print "	$arr_t$_\n";
			open(my $log, '>>', "server-status.log") or print "[-] Cannot save into file ";
			print $log "$arr_t$_\n" and close $log;
		}	
	}
	
	print "\n\nLock above everything we got from server\n\nThx for use this shit";
 	exit(0);
	}; 

l00p_collector($host,\@vh);
