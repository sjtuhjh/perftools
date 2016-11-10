#!/usr/bin/perl
use strict;
use Getopt::Long;   
use POSIX qw(strftime);    
Getopt::Long::Configure qw(no_ignore_case); 
use DBI;    
use DBI qw(:sql_types);

select (STDOUT); $| = 1;
select (STDERR); $| = 1;

my %opt;
my $interval = 5;
my $topn=5;
my $topview="sys_stats";

my ($user,$password,$PORT,$host);

my %viewlist2 ;
my %viewlist1 ;
my %viewlist_diff;
my @viewlist_keys;
my $print_not_first = 0;
my $snap_time;
my $pgcount=0;
my $mysqlversion;


&noodba_main();

sub noodba_main{	
	
	&get_options();
	&init_mysql_version();
	
	while(1) {

		if("table_io_latency" eq $topview){	
			&print_top_table_io_latency();			
		}elsif("table_io_ops" eq $topview){	
			&print_top_table_io_ops();				
		}elsif("table_lock_latency" eq $topview){									
			&print_top_table_lock_latency();
		}elsif("file_io_latency" eq $topview){	
			&print_top_file_io_latency();
		}elsif("stages_latency" eq $topview){		
			&print_top_stages_latency();
		}elsif("top_sql_latency" eq $topview){
			&print_top_sql('topsql_latency');
		}elsif("top_sql_exe" eq $topview){
			&print_top_sql('topsql_exe');
		}elsif("top_sql_lock" eq $topview){
			&print_top_sql('topsql_lock');	
		}elsif("top_sql_examined" eq $topview){
			&print_top_sql('topsql_examined');	
		}elsif("top_sql_tmptab" eq $topview){
			&print_top_sql('topsql_tmptab');
		}elsif("sys_stats" eq $topview){			
			&print_sys_stats();
			$pgcount++;
		}elsif("top_event" eq $topview){		
			&print_top_events();
		}elsif("top_mutex_latency" eq $topview){			
			&print_top_mutex_latency();
		}elsif("blocking_tree" eq $topview){
			&get_blocking_tree();
			exit;
		}elsif("long_op" eq $topview){
			&get_long_op();
			exit;
		}elsif("sql:" eq substr($topview,0,4)){
			&print_sql_detail(substr($topview,4));
			exit;
		}else{			
			exit;
		}		

	    sleep($interval);
	}	
}

sub print_top_mutex_latency {

	my ($sumTimerWait,$eventName,$countStar);
	my $topnum=0;
	my $sql="SELECT EVENT_NAME, SUM_TIMER_WAIT, COUNT_STAR FROM events_waits_summary_global_by_event_name WHERE SUM_TIMER_WAIT > 0 AND EVENT_NAME LIKE 'wait/synch/mutex/%'";
	my $hashkeystr="EVENT_NAME";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
	 		}			
	 	}
	 	
		printf("%11s %50s | %15s %15s \n", " Time ", "EventName", "TimeWait", "Count") ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$sumTimerWait=$viewlist2{"$key"}{"SUM_TIMER_WAIT"}-$viewlist1{"$key"}{"SUM_TIMER_WAIT"};
				$countStar=$viewlist2{"$key"}{"COUNT_STAR"}-$viewlist1{"$key"}{"COUNT_STAR"};
			
			    printf "%11s %50s | %15s %15s \n",
			    $snap_time,$key,&fun_format_time($sumTimerWait), $countStar;
			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n"	; 	
		
	}
     $print_not_first=1;
}

sub print_top_stages_latency {

	my ($sumTimerWait,$eventName,$countStar);
	my $topnum=0;
	my $sql="SELECT EVENT_NAME, SUM_TIMER_WAIT, COUNT_STAR FROM events_stages_summary_global_by_event_name WHERE SUM_TIMER_WAIT > 0 ";
	my $hashkeystr="EVENT_NAME";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
	 		}			
	 	}
	 	
		printf("%11s %50s | %15s %15s \n", " Time ", "EventName", "TimeWait", "Count") ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$sumTimerWait=$viewlist2{"$key"}{"SUM_TIMER_WAIT"}-$viewlist1{"$key"}{"SUM_TIMER_WAIT"};
				$countStar=$viewlist2{"$key"}{"COUNT_STAR"}-$viewlist1{"$key"}{"COUNT_STAR"};
			
			    printf "%11s %50s | %15s %15s \n",
			    $snap_time,$key,&fun_format_time($sumTimerWait), $countStar;
			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n"	; 	
		
	}
     $print_not_first=1;
}

sub print_top_events {

	my ($sumTimerWait,$eventName,$countStar);
	my $topnum=0;
	my $sql="SELECT EVENT_NAME, SUM_TIMER_WAIT, COUNT_STAR FROM events_waits_summary_global_by_event_name WHERE SUM_TIMER_WAIT > 0 AND EVENT_NAME NOT LIKE 'idle%'";
	my $hashkeystr="EVENT_NAME";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
	 		}			
	 	}
	 	
		printf("%11s %50s | %15s %15s \n", " Time ", "EventName", "TimeWait", "Count") ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$sumTimerWait=$viewlist2{"$key"}{"SUM_TIMER_WAIT"}-$viewlist1{"$key"}{"SUM_TIMER_WAIT"};
				$countStar=$viewlist2{"$key"}{"COUNT_STAR"}-$viewlist1{"$key"}{"COUNT_STAR"};
			
			    printf "%11s %50s | %15s %15s \n",
			    $snap_time,$key,&fun_format_time($sumTimerWait), $countStar;
			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n"	; 	
		
	}
     $print_not_first=1;
}


sub print_top_table_io_ops {

	my ($sumTimerWait,$sumTimerRead,$sumTimerWrite,$sumTimerFetch,$sumTimerInsert,$sumTimerUpdate,$sumTimerDelete);
	my ($countStar,$countRead,$countWrite,$countFetch,$countInsert,$countUpdate,$countDelete);
	my $topnum=0;
	my $sql="SELECT OBJECT_SCHEMA, OBJECT_NAME, COUNT_STAR, SUM_TIMER_WAIT, COUNT_READ, SUM_TIMER_READ, COUNT_WRITE, SUM_TIMER_WRITE, COUNT_FETCH, SUM_TIMER_FETCH, COUNT_INSERT, SUM_TIMER_INSERT, COUNT_UPDATE, SUM_TIMER_UPDATE, COUNT_DELETE, SUM_TIMER_DELETE FROM table_io_waits_summary_by_table WHERE SUM_TIMER_WAIT > 0";
	my $hashkeystr="OBJECT_SCHEMA,OBJECT_NAME";
	
	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	

	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"COUNT_STAR"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"COUNT_STAR"}-$viewlist1{"$_"}{"COUNT_STAR"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"COUNT_STAR"};
	 		}			
	 	}
	 	
		printf("%11s %14s | %14s %14s %14s %14s |  %s \n", " Time ", "OP", "Fetch", "Insert", "Update", "Delete", "TName",) ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$countStar=$viewlist2{"$key"}{"COUNT_STAR"}-$viewlist1{"$key"}{"COUNT_STAR"};
				$countRead=$viewlist2{"$key"}{"COUNT_READ"}-$viewlist1{"$key"}{"COUNT_READ"};
				$countWrite=$viewlist2{"$key"}{"COUNT_WRITE"}-$viewlist1{"$key"}{"COUNT_WRITE"};
				$countFetch=$viewlist2{"$key"}{"COUNT_FETCH"}-$viewlist1{"$key"}{"COUNT_FETCH"};
				$countInsert=$viewlist2{"$key"}{"COUNT_INSERT"}-$viewlist1{"$key"}{"COUNT_INSERT"};
				$countUpdate=$viewlist2{"$key"}{"COUNT_UPDATE"}-$viewlist1{"$key"}{"COUNT_UPDATE"};
				$countDelete=$viewlist2{"$key"}{"COUNT_DELETE"}-$viewlist1{"$key"}{"COUNT_DELETE"};				
				
			    printf "%11s %14s | %14s %14s %14s %14s |  %s \n",
			    $snap_time,$countStar,$countFetch, $countInsert,$countUpdate,$countDelete,$key;			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n"	; 	
		
	}
     $print_not_first=1;
}


sub print_top_table_io_latency {

	my ($sumTimerWait,$sumTimerRead,$sumTimerWrite,$sumTimerFetch,$sumTimerInsert,$sumTimerUpdate,$sumTimerDelete);
	my ($countStar,$countRead,$countWrite,$countFetch,$countInsert,$countUpdate,$countDelete);
	my $topnum=0;
	my $sql="SELECT OBJECT_SCHEMA, OBJECT_NAME, COUNT_STAR, SUM_TIMER_WAIT, COUNT_READ, SUM_TIMER_READ, COUNT_WRITE, SUM_TIMER_WRITE, COUNT_FETCH, SUM_TIMER_FETCH, COUNT_INSERT, SUM_TIMER_INSERT, COUNT_UPDATE, SUM_TIMER_UPDATE, COUNT_DELETE, SUM_TIMER_DELETE FROM table_io_waits_summary_by_table WHERE SUM_TIMER_WAIT > 0";
	my $hashkeystr="OBJECT_SCHEMA,OBJECT_NAME";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
	 		}			
	 	}

		printf("%11s %14s | %14s %14s %14s %14s |  %s \n", " Time ", "Latency", "Fetch", "Insert", "Update", "Delete", "TName",) ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$sumTimerRead=$viewlist2{"$key"}{"SUM_TIMER_READ"}-$viewlist1{"$key"}{"SUM_TIMER_READ"};
				$sumTimerWrite=$viewlist2{"$key"}{"SUM_TIMER_WRITE"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE"};
				$sumTimerFetch=$viewlist2{"$key"}{"SUM_TIMER_FETCH"}-$viewlist1{"$key"}{"SUM_TIMER_FETCH"};
				$sumTimerInsert=$viewlist2{"$key"}{"SUM_TIMER_INSERT"}-$viewlist1{"$key"}{"SUM_TIMER_INSERT"};
				$sumTimerUpdate=$viewlist2{"$key"}{"SUM_TIMER_UPDATE"}-$viewlist1{"$key"}{"SUM_TIMER_UPDATE"};
				$sumTimerDelete=$viewlist2{"$key"}{"SUM_TIMER_DELETE"}-$viewlist1{"$key"}{"SUM_TIMER_DELETE"};
			
			    printf "%11s %14s | %14s %14s %14s %14s |  %s \n",
			    $snap_time,&fun_format_time($viewlist_diff{"$key"}),&fun_format_time($sumTimerFetch), &fun_format_time($sumTimerInsert),&fun_format_time($sumTimerUpdate), &fun_format_time($sumTimerDelete),$key;
			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n";	 	
		
	}
     $print_not_first=1;
}


sub print_top_table_lock_latency {

	my ($sumTimerWait,$sumTimerRead,$sumTimerWrite,$sumTimerReadWithSharedLocks,$sumTimerReadHighPriority,$sumTimerReadNoInsert,$sumTimerReadNormal,$sumTimerReadExternal);
	my ($sumTimerWriteAllowWrite,$sumTimerWriteConcurrentInsert,$sumTimerWriteLowPriority,$sumTimerWriteNormal,$sumTimerWriteExternal);
	my $topnum=0;
	my $sql="SELECT  OBJECT_SCHEMA,OBJECT_NAME,SUM_TIMER_WAIT,SUM_TIMER_READ,SUM_TIMER_WRITE,SUM_TIMER_READ_WITH_SHARED_LOCKS,SUM_TIMER_READ_HIGH_PRIORITY,SUM_TIMER_READ_NO_INSERT,SUM_TIMER_READ_NORMAL,SUM_TIMER_READ_EXTERNAL,SUM_TIMER_WRITE_ALLOW_WRITE,SUM_TIMER_WRITE_CONCURRENT_INSERT,SUM_TIMER_WRITE_LOW_PRIORITY,SUM_TIMER_WRITE_NORMAL,SUM_TIMER_WRITE_EXTERNAL FROM  table_lock_waits_summary_by_table WHERE COUNT_STAR > 0";
	my $hashkeystr="OBJECT_SCHEMA,OBJECT_NAME";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
	 		}				
	 	}

		printf("%11s %8s|%8s %8s|%7s %7s %7s %7s %7s|%7s %7s %7s %7s %7s| %s \n",
		" Time ", "Latency","Read", "Write","S.Lock", "High", "NoIns", "Normal", "Extrnl",
		"AlloWr", "CncIns", "Low", "Normal", "Extrnl",	"TName") ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$sumTimerRead=$viewlist2{"$key"}{"SUM_TIMER_READ"}-$viewlist1{"$key"}{"SUM_TIMER_READ"};
				$sumTimerWrite=$viewlist2{"$key"}{"SUM_TIMER_WRITE"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE"};
				$sumTimerReadWithSharedLocks=$viewlist2{"$key"}{"SUM_TIMER_READ_WITH_SHARED_LOCKS"}-$viewlist1{"$key"}{"SUM_TIMER_READ_WITH_SHARED_LOCKS"};
				$sumTimerReadHighPriority=$viewlist2{"$key"}{"SUM_TIMER_READ_HIGH_PRIORITY"}-$viewlist1{"$key"}{"SUM_TIMER_READ_HIGH_PRIORITY"};
				$sumTimerReadNoInsert=$viewlist2{"$key"}{"SUM_TIMER_READ_NO_INSERT"}-$viewlist1{"$key"}{"SUM_TIMER_READ_NO_INSERT"};
				$sumTimerReadNormal=$viewlist2{"$key"}{"SUM_TIMER_READ_NORMAL"}-$viewlist1{"$key"}{"SUM_TIMER_READ_NORMAL"};
				$sumTimerReadExternal=$viewlist2{"$key"}{"SUM_TIMER_READ_EXTERNAL"}-$viewlist1{"$key"}{"SUM_TIMER_READ_EXTERNAL"};
				
				$sumTimerWriteAllowWrite=$viewlist2{"$key"}{"SUM_TIMER_WRITE_ALLOW_WRITE"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE_ALLOW_WRITE"};
				$sumTimerWriteConcurrentInsert=$viewlist2{"$key"}{"SUM_TIMER_WRITE_CONCURRENT_INSERT"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE_CONCURRENT_INSERT"};
				$sumTimerWriteLowPriority=$viewlist2{"$key"}{"SUM_TIMER_WRITE_LOW_PRIORITY"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE_LOW_PRIORITY"};
				$sumTimerWriteNormal=$viewlist2{"$key"}{"SUM_TIMER_WRITE_NORMAL"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE_NORMAL"};
				$sumTimerWriteExternal=$viewlist2{"$key"}{"SUM_TIMER_WRITE_EXTERNAL"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE_EXTERNAL"};		

			    printf "%11s %8s|%8s %8s|%7s %7s %7s %7s %7s|%7s %7s %7s %7s %7s| %s \n",
			    $snap_time,&fun_format_time($viewlist_diff{"$key"}),&fun_format_time($sumTimerRead), &fun_format_time($sumTimerWrite),
			    &fun_format_time($sumTimerReadWithSharedLocks), &fun_format_time($sumTimerReadHighPriority),&fun_format_time($sumTimerReadNoInsert), &fun_format_time($sumTimerReadNormal),&fun_format_time($sumTimerReadExternal),
			    &fun_format_time($sumTimerWriteAllowWrite), &fun_format_time($sumTimerWriteConcurrentInsert),&fun_format_time($sumTimerWriteLowPriority), &fun_format_time($sumTimerWriteNormal),&fun_format_time($sumTimerWriteExternal),
			    $key;
			    			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n";	 	
		
	}
     $print_not_first=1;
}


sub print_top_file_io_latency {

	my ($countStar,$countRead,$countWrite,$countMisc,$sumTimerWait,$sumTimerRead,$sumTimerWrite,$sumTimerMisc,$sumNumberOfBytesRead,$sumNumberOfBytesWrite);
	my $topnum=0;
	my $sql='SELECT  SUBSTRING_INDEX(REPLACE(FILE_NAME,\'\\\\\',\'/\'),\'/\',-2) AS FILE_NAME,SUM(SUM_TIMER_WAIT) AS SUM_TIMER_WAIT,SUM(SUM_TIMER_READ) AS SUM_TIMER_READ,SUM(SUM_TIMER_WRITE) AS SUM_TIMER_WRITE,SUM(SUM_TIMER_MISC) AS SUM_TIMER_MISC,SUM(COUNT_STAR) AS COUNT_STAR,SUM(COUNT_READ) AS COUNT_READ,SUM(COUNT_WRITE) AS COUNT_WRITE,SUM(COUNT_MISC) AS COUNT_MISC,SUM(SUM_NUMBER_OF_BYTES_READ) AS SUM_NUMBER_OF_BYTES_READ,SUM(SUM_NUMBER_OF_BYTES_WRITE) AS SUM_NUMBER_OF_BYTES_WRITE FROM file_summary_by_instance  WHERE SUM_TIMER_WAIT > 0 and LOWER(SUBSTRING_INDEX(FILE_NAME,\'.\',-1)) != \'frm\'  AND EVENT_NAME not in  (\'wait/io/file/sql/binlog\',\'wait/io/file/sql/relaylog\') GROUP BY FILE_NAME';
	my $hashkeystr="FILE_NAME";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
	 		}else{
	 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
	 		}		 		
	 	}
	 	
		printf("%11s %8s | %8s %8s %8s | %8s %8s | %7s %7s %7s %7s | %s \n",
		" Time ", "Latency","Read","Write","Misc","RdB","WrB","OP","R OP","W OP","M OP","FlName") ;
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$sumTimerRead=$viewlist2{"$key"}{"SUM_TIMER_READ"}-$viewlist1{"$key"}{"SUM_TIMER_READ"};
				$sumTimerWrite=$viewlist2{"$key"}{"SUM_TIMER_WRITE"}-$viewlist1{"$key"}{"SUM_TIMER_WRITE"};
				$sumTimerMisc=$viewlist2{"$key"}{"SUM_TIMER_MISC"}-$viewlist1{"$key"}{"SUM_TIMER_MISC"};
				$sumNumberOfBytesRead=$viewlist2{"$key"}{"SUM_NUMBER_OF_BYTES_READ"}-$viewlist1{"$key"}{"SUM_NUMBER_OF_BYTES_READ"};
				$sumNumberOfBytesWrite =$viewlist2{"$key"}{"SUM_NUMBER_OF_BYTES_WRITE"}-$viewlist1{"$key"}{"SUM_NUMBER_OF_BYTES_WRITE"};
				
				$countStar=$viewlist2{"$key"}{"COUNT_STAR"}-$viewlist1{"$key"}{"COUNT_STAR"};
				$countRead=$viewlist2{"$key"}{"COUNT_READ"}-$viewlist1{"$key"}{"COUNT_READ"};
				$countWrite=$viewlist2{"$key"}{"COUNT_WRITE"}-$viewlist1{"$key"}{"COUNT_WRITE"};
				$countMisc=$viewlist2{"$key"}{"COUNT_MISC"}-$viewlist1{"$key"}{"COUNT_MISC"};
		
			    printf "%11s %8s | %8s %8s %8s | %8s %8s | %7s %7s %7s %7s | %s \n",
			    $snap_time,&fun_format_time($viewlist_diff{"$key"}),&fun_format_time($sumTimerRead), &fun_format_time($sumTimerWrite),
			    &fun_format_time($sumTimerMisc), &fun_format_bytes($sumNumberOfBytesRead),&fun_format_bytes($sumNumberOfBytesWrite), 
			    $countStar, $countRead,$countWrite, $countMisc,  $key;
			    			    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n"	; 	
		
	}
     $print_not_first=1;
}

sub print_sys_stats {

	my ($countStar,$countRead,$countWrite,$countMisc,$sumTimerWait,$sumTimerRead,$sumTimerWrite,$sumTimerMisc,$sumNumberOfBytesRead,$sumNumberOfBytesWrite);
	my $topnum=0;
	my $sql;
	

	$sql="SHOW GLOBAL STATUS  where VARIABLE_NAME in ('Bytes_received','Bytes_sent','Handler_commit','Questions','Innodb_buffer_pool_read_requests','Innodb_buffer_pool_reads','Innodb_buffer_pool_wait_free','Innodb_buffer_pool_write_requests','Innodb_data_pending_reads','Innodb_data_pending_writes','Innodb_log_waits','Innodb_log_write_requests','Innodb_log_writes','Innodb_os_log_pending_writes','Innodb_os_log_written')";

	my $hashkeystr="Variable_name";

	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
		
	$snap_time = strftime "%m%d %H%M%S", localtime;
	
 	if($pgcount%10 == 0){
	 	print "\n";	
		printf("%11s %6s %6s %7s %7s %8s %7s %7s %8s %6s %6s %6s %8s %7s %7s %7s\n",
		" Time ", "Quests","Hcomt","RecvB","SendB","BufRRs","BufRs","BufWFs","BufWRs","DtPRs",
		"DtPWs","LogWt","LogWRs","LogWs","LogPWs","LogWB") ;	 		
 	}	
	
	if($print_not_first){	
	 	foreach (keys %viewlist2) {
			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"Value"}-$viewlist1{"$_"}{"Value"};
	 	}

		printf("%11s %6s %6s %7s %7s %8s %7s %7s %8s %6s %6s %6s %8s %7s %7s %7s\n",
		$snap_time, $viewlist_diff{"Questions"},$viewlist_diff{"Handler_commit"}, &fun_format_bytes($viewlist_diff{"Bytes_received"}),&fun_format_bytes($viewlist_diff{"Bytes_sent"}),
		&fun_format_number($viewlist_diff{"Innodb_buffer_pool_read_requests"}),$viewlist_diff{"Innodb_buffer_pool_reads"},$viewlist_diff{"Innodb_buffer_pool_wait_free"},&fun_format_number($viewlist_diff{"Innodb_buffer_pool_write_requests"}),$viewlist2{"Innodb_data_pending_reads"}{"Value"},
		$viewlist2{"Innodb_data_pending_writes"}{"Value"},$viewlist_diff{"Innodb_log_waits"},&fun_format_number($viewlist_diff{"Innodb_log_write_requests"}),$viewlist_diff{"Innodb_log_writes"},$viewlist2{"Innodb_os_log_pending_writes"}{"Value"},&fun_format_bytes($viewlist_diff{"Innodb_os_log_written"})) ;	
	 	
	}
     $print_not_first=1;
}

sub print_top_sql {

	my ($countStar,$sumTimerWait,$sumLockTime,$sumRowsAffected,$sumRowsSent,$sumRowsExamined,$sumCreatedTmpTables,$sumSelectFullJoin,$sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan );
	my $topnum=0;
	my $topevent=shift;
	my $checktime;
	my $hashkeystr="DIGEST";	
	my $sql;

	$checktime=strftime "%Y-%m-%d %H:%M:%S", localtime;		
	$snap_time = strftime "%m%d %H%M%S", localtime;
		

	$sql="SELECT  SCHEMA_NAME,DIGEST,COUNT_STAR,SUM_TIMER_WAIT,SUM_LOCK_TIME,SUM_ROWS_AFFECTED,SUM_ROWS_SENT,SUM_ROWS_EXAMINED,SUM_CREATED_TMP_TABLES,SUM_SELECT_FULL_JOIN,SUM_SELECT_FULL_RANGE_JOIN,SUM_SELECT_RANGE,SUM_SORT_SCAN  FROM events_statements_summary_by_digest where DIGEST is not null and COUNT_STAR>0 and LAST_SEEN>DATE_ADD(\'$checktime\',INTERVAL -2 HOUR)";
	
	%viewlist1=%viewlist2; 		 	
	&get_ps_info($sql,$hashkeystr);
	

	if($print_not_first){	
	 	foreach (keys %viewlist2) {
	 		if("topsql_latency" eq $topevent){
		 		if(defined $viewlist1{"$_"}{"SUM_TIMER_WAIT"}){
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"}-$viewlist1{"$_"}{"SUM_TIMER_WAIT"};
		 		}else{
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_TIMER_WAIT"};
		 		}		 			
	 		}elsif("topsql_exe" eq $topevent){
		 		if(defined $viewlist1{"$_"}{"COUNT_STAR"}){
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"COUNT_STAR"}-$viewlist1{"$_"}{"COUNT_STAR"};
		 		}else{
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"COUNT_STAR"};
		 		}
	 		}elsif("topsql_lock" eq $topevent){
		 		if(defined $viewlist1{"$_"}{"SUM_LOCK_TIME"}){
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_LOCK_TIME"}-$viewlist1{"$_"}{"SUM_LOCK_TIME"};
		 		}else{
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_LOCK_TIME"};
		 		}		 			
	 		}elsif("topsql_examined" eq $topevent){
		 		if(defined $viewlist1{"$_"}{"SUM_ROWS_EXAMINED"}){
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_ROWS_EXAMINED"}-$viewlist1{"$_"}{"SUM_ROWS_EXAMINED"};
		 		}else{
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_ROWS_EXAMINED"};
		 		}			 				 			
	 		}elsif("topsql_tmptab" eq $topevent){
		 		if(defined $viewlist1{"$_"}{"SUM_CREATED_TMP_TABLES"}){
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_CREATED_TMP_TABLES"}-$viewlist1{"$_"}{"SUM_CREATED_TMP_TABLES"};
		 		}else{
		 			$viewlist_diff{"$_"}=$viewlist2{"$_"}{"SUM_CREATED_TMP_TABLES"};
		 		}		 		
	 		}			
	 	}
	 	
 		if("topsql_latency" eq $topevent){
			printf("%11s %8s | %7s %7s | %7s %7s %7s |%5s %6s %6s %6s %6s| %32s\n",
			" Time ", "Latency","Count","Lockt","RowsA","RowsS","RowsE","CTmpT","SltFJ","SltFRJ","SltR","SortS","Digest") ;		 		 			
 		}elsif("topsql_exe" eq $topevent){
			printf("%11s %7s | %8s %7s | %7s %7s %7s |%5s %6s %6s %6s %6s| %32s\n",
			" Time ", "Count","Latency","Lockt","RowsA","RowsS","RowsE","CTmpT","SltFJ","SltFRJ","SltR","SortS","Digest") ;		 			
  		}elsif("topsql_lock" eq $topevent){
			printf("%11s %7s | %8s %7s | %7s %7s %7s |%5s %6s %6s %6s %6s| %32s\n",
			" Time ","Lockt", "Latency","Count","RowsA","RowsS","RowsE","CTmpT","SltFJ","SltFRJ","SltR","SortS","Digest") ;		
 		}elsif("topsql_examined" eq $topevent){
			printf("%11s %8s | %8s %7s %7s | %7s %7s |%5s %5s %6s %6s %6s| %32s\n",
			" Time ", "RowsE","Latency","Count","Lockt","RowsA","RowsS","CTmpT","SltFJ","SltFRJ","SltR","SortS","Digest") ;	
 		}elsif("topsql_tmptab" eq $topevent){
			printf("%11s %6s | %8s %7s %7s | %7s %7s %7s | %5s %5s %6s %6s| %32s\n",
			" Time ","CTmpT", "Latency","Count","Lockt","RowsA","RowsS","RowsE","SltFJ","SltFRJ","SltR","SortS","Digest") ;							
 		}
		 
		foreach my $key (sort  { $viewlist_diff{$b} <=> $viewlist_diff{$a} } keys %viewlist_diff){     
            if($viewlist_diff{"$key"}>0){
				$countStar=$viewlist2{"$key"}{"COUNT_STAR"}-$viewlist1{"$key"}{"COUNT_STAR"};
				$sumTimerWait=$viewlist2{"$key"}{"SUM_TIMER_WAIT"}-$viewlist1{"$key"}{"SUM_TIMER_WAIT"};
				$sumLockTime=$viewlist2{"$key"}{"SUM_LOCK_TIME"}-$viewlist1{"$key"}{"SUM_LOCK_TIME"};
				$sumRowsAffected=$viewlist2{"$key"}{"SUM_ROWS_AFFECTED"}-$viewlist1{"$key"}{"SUM_ROWS_AFFECTED"};
				$sumRowsSent =$viewlist2{"$key"}{"SUM_ROWS_SENT"}-$viewlist1{"$key"}{"SUM_ROWS_SENT"};
				$sumRowsExamined =$viewlist2{"$key"}{"SUM_ROWS_EXAMINED"}-$viewlist1{"$key"}{"SUM_ROWS_EXAMINED"};
								
				$sumCreatedTmpTables=$viewlist2{"$key"}{"SUM_CREATED_TMP_TABLES"}-$viewlist1{"$key"}{"SUM_CREATED_TMP_TABLES"};
				$sumSelectFullJoin=$viewlist2{"$key"}{"SUM_SELECT_FULL_JOIN"}-$viewlist1{"$key"}{"SUM_SELECT_FULL_JOIN"};
				$sumSelectFullRangeJoin=$viewlist2{"$key"}{"SUM_SELECT_FULL_RANGE_JOIN"}-$viewlist1{"$key"}{"SUM_SELECT_FULL_RANGE_JOIN"};
				$sumSelectRange=$viewlist2{"$key"}{"SUM_SELECT_RANGE"}-$viewlist1{"$key"}{"SUM_SELECT_RANGE"};
				$sumSortScan=$viewlist2{"$key"}{"SUM_SORT_SCAN"}-$viewlist1{"$key"}{"SUM_SORT_SCAN"};				

		 		if("topsql_latency" eq $topevent){
				    printf "%11s %8s | %7s %7s | %7s %7s %7s |%5s %6s %6s %6s %6s| %32s\n",
					 $snap_time,&fun_format_time($viewlist_diff{"$key"}),$countStar,,&fun_format_time($sumLockTime),
					 $sumRowsAffected,$sumRowsSent,$sumRowsExamined,$sumCreatedTmpTables,$sumSelectFullJoin,
					 $sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan,$key;
		 		}elsif("topsql_exe" eq $topevent){
				    printf "%11s %7s | %8s %7s | %7s %7s %7s |%5s %6s %6s %6s %6s| %32s\n",
					 $snap_time,$countStar,&fun_format_time($sumTimerWait),&fun_format_time($sumLockTime),
					 $sumRowsAffected,$sumRowsSent,$sumRowsExamined,$sumCreatedTmpTables,$sumSelectFullJoin,
					 $sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan,$key;
		 		}elsif("topsql_lock" eq $topevent){
				    printf "%11s %7s | %8s %7s | %7s %7s %7s |%5s %6s %6s %6s %6s| %32s\n",
					 $snap_time,&fun_format_time($sumLockTime),&fun_format_time($sumTimerWait),$countStar,
					 $sumRowsAffected,$sumRowsSent,$sumRowsExamined,$sumCreatedTmpTables,$sumSelectFullJoin,
					 $sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan,$key;
		 		}elsif("topsql_examined" eq $topevent){
				    printf "%11s %8s | %8s %7s %7s | %7s %7s |%5s %5s %6s %6s %6s| %32s\n",
					 $snap_time,$sumRowsExamined,&fun_format_time($sumTimerWait),$countStar,&fun_format_time($sumLockTime),
					 $sumRowsAffected,$sumRowsSent,$sumCreatedTmpTables,$sumSelectFullJoin,
					 $sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan,$key;
		 		}elsif("topsql_tmptab" eq $topevent){
				    printf "%11s %6s | %8s %7s %7s | %7s %7s %7s | %5s %5s %6s %6s| %32s\n",
					 $snap_time,$sumCreatedTmpTables,&fun_format_time($sumTimerWait),$countStar,&fun_format_time($sumLockTime),
					 $sumRowsAffected,$sumRowsSent,$sumRowsExamined,$sumSelectFullJoin,
					 $sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan,$key;					 					 					 
		 		}
		 				    
			    $topnum++;
			    last if $topnum>=$topn;				
            }
		 }
		 print "\n"	;	
		
	}
     $print_not_first=1;
}

sub print_sql_detail {

	my ($countStar,$sumTimerWait,$sumLockTime,$sumRowsAffected,$sumRowsSent,$sumRowsExamined,$sumCreatedTmpTables,$sumSelectFullJoin,$sumSelectFullRangeJoin,$sumSelectRange,$sumSortScan );
	my $topnum=0;
	my $sqlid=shift;
	my $sql;

	$sql="SELECT  SCHEMA_NAME,DIGEST,DIGEST_TEXT,COUNT_STAR,SUM_TIMER_WAIT,AVG_TIMER_WAIT,SUM_LOCK_TIME,SUM_ROWS_AFFECTED,SUM_ROWS_SENT,
	SUM_ROWS_EXAMINED,SUM_CREATED_TMP_TABLES,SUM_CREATED_TMP_DISK_TABLES,SUM_NO_INDEX_USED,SUM_SORT_ROWS,SUM_SELECT_FULL_JOIN,FIRST_SEEN,LAST_SEEN
	FROM events_statements_summary_by_digest 	where DIGEST = \'$sqlid\'  and COUNT_STAR>0";
	
	my $dbh = &get_connect();
	if(not $dbh) {
		exit;
	}

	my	$sth = $dbh->prepare($sql);
	$sth->execute();
	while( my $hash_ref = $sth -> fetchrow_hashref() )	{
		printf("%70s \n","******************************** SQL SUM INFO ********************************") ;
		printf("%22s : %-s \n","DIGEST", $hash_ref->{"DIGEST"}) ;
		printf("%22s : %-s \n","SCHEMA_NAME", $hash_ref->{"SCHEMA_NAME"}) ;
		printf("%22s : %-s \n","COUNT_STAR", $hash_ref->{"COUNT_STAR"}) ;	
		printf("%22s : %-s \n","SUM_TIMER_WAIT", $hash_ref->{"SUM_TIMER_WAIT"}) ;
		printf("%22s : %-s \n","SUM_LOCK_TIME", $hash_ref->{"SUM_LOCK_TIME"}) ;
		printf("%22s : %-s \n","SUM_ROWS_AFFECTED", $hash_ref->{"SUM_ROWS_AFFECTED"}) ;
		printf("%22s : %-s \n","SUM_ROWS_SENT", $hash_ref->{"SUM_ROWS_SENT"}) ;
		printf("%22s : %-s \n","SUM_ROWS_EXAMINED", $hash_ref->{"SUM_ROWS_EXAMINED"}) ;
		printf("%22s : %-s \n","SUM_CRD_TMP_TABLES", $hash_ref->{"SUM_CREATED_TMP_TABLES"}) ;	
		printf("%22s : %-s \n","SUM_CRD_T_DISK_TABLES", $hash_ref->{"SUM_CREATED_TMP_DISK_TABLES"}) ;
		printf("%22s : %-s \n","SUM_NO_INDEX_USED", $hash_ref->{"SUM_NO_INDEX_USED"}) ;
		printf("%22s : %-s \n","SUM_SORT_ROWS", $hash_ref->{"SUM_SORT_ROWS"}) ;
		printf("%22s : %-s \n","SUM_SELECT_FULL_JOIN", $hash_ref->{"SUM_SELECT_FULL_JOIN"}) ;
		printf("%22s : %-s \n","FIRST_SEEN", $hash_ref->{"FIRST_SEEN"}) ;
		printf("%22s : %-s \n","LAST_SEEN", $hash_ref->{"LAST_SEEN"}) ;			
		printf("%70s \n","******************************** SQL AVG INFO ********************************") ;
		printf("%22s : %-s \n","AVG_TIMER_WAIT", &fun_format_time($hash_ref->{"SUM_TIMER_WAIT"}/$hash_ref->{"COUNT_STAR"}) );
		printf("%22s : %-s \n","AVG_ROWS_AFFECTED", &fun_format_number($hash_ref->{"SUM_ROWS_AFFECTED"}/$hash_ref->{"COUNT_STAR"}) );
		printf("%22s : %-s \n","AVG_ROWS_SENT", &fun_format_number($hash_ref->{"SUM_ROWS_SENT"}/$hash_ref->{"COUNT_STAR"}) );
		printf("%22s : %-s \n","AVG_ROWS_EXAMINED", &fun_format_number($hash_ref->{"SUM_ROWS_EXAMINED"}/$hash_ref->{"COUNT_STAR"}) );
		printf("%22s : %-s \n","AVG_SORT_ROWS", &fun_format_number($hash_ref->{"SUM_SORT_ROWS"}/$hash_ref->{"COUNT_STAR"}) );

		printf("%70s \n","******************************** SQL TEXT INFO ********************************") ;
		printf("%22s : %-s \n","DIGEST_TEXT", $hash_ref->{"DIGEST_TEXT"});
		
		printf("%70s \n","******************************** SQL INFO END ********************************") ;			
			
		last;
	}
	
    $sth->finish;
	$dbh->disconnect();		

}

sub get_long_op {
	my $sql="select p.id,p.time,p.user,p.db,p.host,p.state,left(p.info,150) as qry_sql,p.command from information_schema.PROCESSLIST p 
		where time > $interval and command<>'Sleep' order by time desc";
	my $topnum=0;
	
	my $dbh = &get_connect();
	if(not $dbh) {
		exit;
	}

	my	$sth = $dbh->prepare($sql);
	$sth->execute();
	while( my $hash_ref = $sth -> fetchrow_hashref() )	{
		$topnum++;
		last if $topnum>$topn;	
		
		printf("%70s \n","******************************** $topnum row ********************************") ;
		printf("%10s : %-s \n","id", $hash_ref->{"id"}) ;
		printf("%10s : %-s \n","time", $hash_ref->{"time"}) ;
		printf("%10s : %-s \n","user", $hash_ref->{"user"}) ;	
		printf("%10s : %-s \n","db", $hash_ref->{"db"}) ;
		printf("%10s : %-s \n","host", $hash_ref->{"host"}) ;
		printf("%10s : %-s \n","state", $hash_ref->{"state"}) ;
		printf("%10s : %-s \n","command", $hash_ref->{"command"}) ;
		printf("%10s : %-s \n","qry_sql", $hash_ref->{"qry_sql"}) ;
	}
	
    $sth->finish;
	$dbh->disconnect();		

}

sub get_blocking_tree {
	my $sql='SELECT 	r.trx_id AS waiting_trx_id,r.trx_mysql_thread_id AS waiting_pid,b.trx_id AS blocking_trx_id,b.trx_mysql_thread_id AS blocking_pid,LEFT(b.trx_query,150) AS blocking_query,bl.lock_id AS blocking_lock_id,bl.lock_mode AS blocking_lock_mode,b.trx_started AS blocking_trx_started,TIMEDIFF(NOW(), b.trx_started) AS blocking_trx_age,b.trx_rows_locked AS blocking_trx_rows_locked,b.trx_rows_modified AS blocking_trx_rows_modified,rl.lock_table AS locked_table,rl.lock_index AS locked_index,rl.lock_type AS locked_type
	FROM information_schema.innodb_lock_waits w  INNER JOIN information_schema.innodb_trx b    ON b.trx_id = w.blocking_trx_id  INNER JOIN information_schema.innodb_trx r    ON r.trx_id = w.requesting_trx_id  INNER JOIN information_schema.innodb_locks bl ON bl.lock_id = w.blocking_lock_id   INNER JOIN information_schema.innodb_locks rl ON rl.lock_id = w.requested_lock_id ';
	
	my $topnum=0;
	my $rootblockid;
	
	my $dbh = &get_connect();
	if(not $dbh) {
		exit;
	}

	my	$sth = $dbh->prepare($sql);
	$sth->execute();
	while( my $hash_ref = $sth -> fetchrow_hashref() )	{
		
		$viewlist1{$hash_ref->{"waiting_trx_id"}}=1; 
		unless($viewlist2{$hash_ref->{"blocking_trx_id"}}){
			$viewlist2{$hash_ref->{"blocking_trx_id"}}=$hash_ref->{"waiting_trx_id"}; 
		}else{
			$viewlist2{$hash_ref->{"blocking_trx_id"}}=$viewlist2{$hash_ref->{"blocking_trx_id"}} . "," . $hash_ref->{"waiting_trx_id"}; 
		} 
		$viewlist_diff{$hash_ref->{"blocking_trx_id"}}=$hash_ref;  
	}

    $sth->finish;
	$dbh->disconnect();	
		
	foreach my $bkey ( keys %viewlist2){
		my $rootflag=1;
		my $wkey;			
		foreach $wkey ( keys %viewlist1){ 
           	if ($bkey eq $wkey){
           		$rootflag=0;
           		last;
           	}    
		}
		if($rootflag==1){
			$topnum++;
			printf("%70s \n","******************************** Chain $topnum ********************************") ;
			printf("%20s | %-s \n","root_blocker", "blocking_trx_id:" . $viewlist_diff{"$bkey"}{"blocking_trx_id"} . ";  blocking_pid:"
			. $viewlist_diff{"$bkey"}{"blocking_pid"} .";  blocking_lock_id:". $viewlist_diff{"$bkey"}{"blocking_lock_id"} ) ;
			printf("%20s | %-s \n","waiters(trx_ids)", $viewlist2{$bkey} ) ;	
			printf("%20s | %-s \n","blocking_query", $viewlist_diff{"$bkey"}{"blocking_query"} ) ;
			printf("%20s | %-s \n","root_blocker_info", "lock_mode:" . $viewlist_diff{"$bkey"}{"blocking_lock_mode"} . ";  trx_rows_locked:"
			. $viewlist_diff{"$bkey"}{"blocking_trx_rows_locked"} . ";  trx_rows_modified:" . $viewlist_diff{"$bkey"}{"blocking_trx_rows_modified"} .";  blocking_trx_age:". $viewlist_diff{"$bkey"}{"blocking_trx_age"} ) ;				
			printf("%20s | %-s \n","locked_inf", "locked_table:" . $viewlist_diff{"$bkey"}{"locked_table"} . ";  locked_index:"
			. $viewlist_diff{"$bkey"}{"locked_index"} .";  locked_type:". $viewlist_diff{"$bkey"}{"locked_type"} ) ;
			printf("%20s | %-s \n","kill_sql", "KILL QUERY / KILL " . $viewlist_diff{"$bkey"}{"blocking_pid"} ) ;
			printf("%70s \n\n","******************************** Chain $topnum ********************************") ;
		}

	}

}

sub get_ps_info {
	my $sql=shift;
	my $hashkeystr=shift;
	my @hkeys = split( /,/, $hashkeystr );
	my $hashkey;

	my $dbh = &get_connect();
	if(not $dbh) {
		exit;
	}

	my	$sth = $dbh->prepare($sql);
	$sth->execute();
	while( my $hash_ref = $sth -> fetchrow_hashref() )	{
		undef $hashkey;
		
		foreach my $keycol (@hkeys) {
			if( !(defined $hashkey)){
				$hashkey=$hash_ref->{$keycol};
			}else{
				$hashkey=$hashkey . '.' . $hash_ref->{$keycol} ;
			}
		}	
		
		$viewlist2{"$hashkey"}=$hash_ref;
	}
	
    $sth->finish;
	$dbh->disconnect();		

}

sub init_mysql_version {
	my $dbh = &get_connect();
	if(not $dbh) {
		exit;
	}
    
    unless($mysqlversion){
    	($mysqlversion)=$dbh->selectrow_array("select LEFT(TRIM(VERSION()),3) AS MYVN");
    }    

	$dbh->disconnect();		

}

sub get_connect{
    my $_dbh;
    eval {
        $_dbh = DBI->connect( "DBI:mysql:database=performance_schema;host=$host;port=$PORT;mysql_connect_timeout=5","$user", "$password", { 'RaiseError' => 1 ,AutoCommit => 1} );
    };
	if ( $@ ) {
     	print("connect to ($host:$PORT) failed:$@");  	
    	return undef;
   }else{
  		return $_dbh;
  	}	
	
}

sub fun_format_time(){
	my $picoseconds=shift;
	
	if ($picoseconds == 0) {
		return "--";
	}elsif($picoseconds >= 3600000000000000) {
		return int($picoseconds/36000000000000+0.5)/100 . "h";
	}elsif($picoseconds >= 60000000000000) {
		return int($picoseconds/600000000000+0.5)/100 . "m";
	}elsif($picoseconds >= 1000000000000) {
		return int($picoseconds/10000000000+0.5)/100  . "s";
	}elsif ($picoseconds >= 1000000000) {
		return int($picoseconds/10000000+0.5)/100 . "ms";
	}elsif ($picoseconds >= 1000000) {
		return int($picoseconds/10000+0.5)/100 . "us";
	}elsif ($picoseconds >= 1000) {
		return int($picoseconds/10+0.5)/100 . "ns"
	}else{
		return int($picoseconds+0.5) . "ps";
	}	
}

sub fun_format_bytes(){
	my $bytes=shift;
	
	if (!(defined $bytes)) {
		return "--";
	}elsif($bytes >= 1125899906842624) {
		return int(($bytes*100)/1125899906842624+0.5)/100 . "PB";
	}elsif($bytes >= 1099511627776) {
		return int(($bytes*100)/1099511627776+0.5)/100 . "TB";
	}elsif($bytes >= 1073741824) {
		return int(($bytes*100)/1073741824+0.5)/100  . "GB";
	}elsif ($bytes >= 1048576) {
		return int(($bytes*100)/1048576+0.5)/100 . "MB";
	}elsif ($bytes >= 1024) {
		return int(($bytes*100)/1024+0.5)/100 . "KB";
	}else{
		return int($bytes+0.5) . "B";
	}	
}

sub fun_format_number(){
	my $numbers=shift;
	
	if (!(defined $numbers)) {
		return "--";
	}elsif($numbers >= 1000000) {
		return int(($numbers*100)/1000000+0.5)/100 . "M";		
	}elsif($numbers >= 10000) {
		return int(($numbers*100)/10000+0.5)/100 . "W";
	}elsif ($numbers >= 1000) {
		return int(($numbers*100)/1000+0.5)/100 . "K";
	}else{
		return int($numbers+0.5);
	}	
}

sub print_usage {
	
	print <<EOF;
==========================================================================================
Info  :
        Created By noodba (www.noodba.com) .
   References: https://github.com/sjmudd/ps-top by Simon J Mudd  
Usage :
Command line options :

   --help             Print Help Info. 
   -i,--interval       Time(second) Interval(default 5).  
   -n,--topn           Top Numbers(default 5).
   -u,--user
   -p,--password
   -h,--host
   -P,--PORT           
   -v,--topview   Determine the view you want to see when pstop starts (default: 'sys_stats')
                  Possible values: 'table_io_latency', 'table_io_ops', 'file_io_latency', 
                  'table_lock_latency','top_sql_latency', 'top_sql_exe' , 'top_sql_lock', 
                  'top_sql_examined','top_sql_tmptab', 'sys_stats' ,'top_mutex_latency',
                  'top_event','stages_latency','blocking_tree','long_op' and 'sql:DIGEST_VALUE'
  
Sample :
   shell> perl pstop.pl  --topview=sys_stats -i 5 -n 10
==========================================================================================
EOF
	exit;
}

sub get_options {

	GetOptions(
		\%opt,
		'help',         
		'i|interval=i',  
		'n|topn=i',       
		'v|topview=s',  
		'u|user=s',        
		'p|password=s',    
		'P|PORT=s',     
		'h|host=s',      	
	) or print_usage();

	if ( !scalar(%opt) ) {
		&print_usage();
	}

	$opt{'help'}  and print_usage();
	$opt{'n'}  and $topn = $opt{'n'};
	$opt{'i'}  and $interval = $opt{'i'};
	$opt{'v'}  and $topview = $opt{'v'};	
	$opt{'u'}  and $user = $opt{'u'};
	$opt{'p'}  and $password = $opt{'p'};
	$opt{'P'}  and $PORT = $opt{'P'};
	$opt{'h'}  and $host = $opt{'h'};

	if (
		!(
			defined $password
			and defined $user
			and defined $PORT
			and defined $host
		)
	  )
	{
		&print_usage();
	}					 

}
