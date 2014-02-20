#!/usr/bin/perl

use strict;
package MyBot;
use base qw( Bot::BasicBot );
use XML::LibXML;
	
	#List of global vars
our $inrace = -1;   #-1 = no race || 1 = race started || 2 = race inprogress || 3 = race finished ||
our $sets = 1;
our @entrants;		#array of entrants [name]
our @ready;			#array of ppl .ready [name]
our @finished;		#array of ppl .doned [name,time]
our @inset;			#array used for multiple set races [name,set#,time]
our @mods = ['dram','dram55','bram','Sluip', 'something915','MSDS3170','Minion','neskamikaze','prier','theJUICE'];	
our $channel = '#teamfit';
our $start;			#start timer
our $workout = '';	#current workout
our $amount = 0;	#num of repetitions
our $rest = 0;


# Create an instance of the bot and start it running. Connect
# to the main perl IRC server, and join some channels.
our $bot = MyBot->new(
  server => 'irc2.speedrunslive.com',
  channels => [$channel],
  nick => 'fitBot',
);
	
$bot->run();

#This is automatically called 5 seconds after bot start
#Use it to Auth - then return 0 so it doesn't happen again
sub tick {
		#authenticate
	$bot->say(
	who => "nickserv",
	channel => "msg",
	body => "IDENTIFY theunderground",
	address => "msg");
	return 0;
}
	
	
sub said {
  my ($self, $message) = @_;
  my $out;
  my $address  = $message->{address};
  my $body = $message->{body};
  my $said = $message->{who};
  
  #check if current line is command '.'
  if (substr($body,0,1) eq '.') {
	  my $strip = substr($body,1);
	  my $extra = substr($strip,(index($strip,' ')+1));
	  my $cmd = (split(/\s/, $strip, 2))[0];
	  my $timer = Time::HiRes::gettimeofday();
	  #call validate to run the command
	  validate($cmd,$said,$extra,$timer,$address);
    }
	return;
}

sub validate{

	my $command = $_[0];
	my $who = $_[1];
	my $extra = $_[2];

	#only check mod functions if allowed

	if ($command eq 'theunderground')
	{
		if ($who ~~ @mods)
		{
			shutDown();
		}
	}
	
	elsif ($command eq 'all')
	{
		if ($who ~~ @mods)
		{
		$bot->forkit(
		channel => "$channel",
		run     => \&showAll);
		return;
		}
	}
	
	elsif ($command eq 'ping')
	{
		if ($who~~@mods)
		{
			$bot->notice(
        channel => $channel,
        body => 'Down for a #teamfit race?'
    );
			
		}
	}

	elsif ($command eq 'lb')
	{
		$bot->forkit(
		channel => "$channel",
		run     => \&leaderboard,
		arguments => [$extra]);
		return;
	}
	
	
	elsif ($command eq 'progress')
	{
	  my $thegoal= substr($extra,(index($extra,' ')+1));
	  my $player = (split(/\s/, $extra, 2))[0];
		$bot->forkit(
		channel => "$channel",
		run     => \&getProgress,
		arguments => [$thegoal,$player]);
		return;
	}
	
	elsif ($command eq 'getavg')
	{
	
	  my $thegoal= substr($extra,(index($extra,' ')+1));
	  my $player = (split(/\s/, $extra, 2))[0];
		$bot->forkit(
		channel => "$channel",
		run     => \&getAvg,
		arguments => [$thegoal,$player]);
		return;
	}
	
	elsif ($command eq 'goallist')
	{
		$bot->forkit(
		channel => "$channel",
		run     => \&goalList,
		arguments => [$extra]);
		return;
	}
	
	elsif ($command eq 'end')
	{
		if ($who ~~ @mods)
		{
			$bot->say(
			channel => "$channel",
			body => "Race Ended.");
			endRace();
			return;
		}
	}
	
	elsif ($command eq 'totals')
	{

		$bot->forkit(
		channel => "$channel",
		run     => \&getTotals);
		return;
	}
	
	if ($command eq 'remove')
	{
		if ($inrace == 2 )
		{
		return;
		}
		
		if ($who ~~ @mods)
		{
			remove($extra);
			allDone();
			return;
		}
	}
	
	elsif ($command eq 'startrace')
	{
		if($inrace == -1)
		{
			$inrace = 1;
			$bot->say(
				channel => "$channel",
				body => "Race Started! To do multiple sets use .sets");
				return;
		}
		return;

	}
	
	#only look at race commands if the race has been started
	elsif($inrace == 1 || $inrace == 4)
		{

			if ($command eq 'join')
			{
				if(inRace($who) == 0)
				{
					push(@entrants,$who);
					$bot->say(
					channel => "$channel",
					body => "$who has joined the race!");
					return;
				}
				return;
			}
			
			elsif ($command eq 'setgoal')
			{
					
					my @breakup = split(/ /, $extra,2);
					my $thenumber = @breakup[0];
					my $theworkout = @breakup[1];

					if(int($thenumber) eq $thenumber && int($thenumber) > 0)
						{
						$amount = int($thenumber);
						}
					else 
					{
					$bot->say(
					channel => "$channel",
					body => "Goal must be in proper format (Example: 50 pushups)");
						return;
					}					
					
					
					if (int($theworkout) ne $theworkout)
					{
						if (length($theworkout) < 28)
						{
							$workout = $theworkout;
							
							#Reach here on successful goal swap - read back the goal.
							if ($inrace == 4)
							{
								$bot->say(
								channel => "$channel",
								body => "$sets sets of $amount $workout - $rest second rest per set.");
								return;
							}
							else
							{
								$bot->say(
								channel => "$channel",
								body => "$amount $workout");
								return;
							}
						}
						else
						{
							$bot->say(
							channel => "$channel",
							body => "Workout cannot exceed 27 characters.");
							return;
						}
						
					}
					else 
					{
						$bot->say(
						channel => "$channel",
						body => "Goal must be in proper format (Example: 50 pushups)");
						return;
					}	

			}

			elsif ($command eq 'goal')
			{
				if ($inrace == 4)
				{
					$bot->say(
					channel => "$channel",
					body => "$sets sets of $amount $workout - $rest second rest per set.");
					return;
				}
				else
				{
					$bot->say(
					channel => "$channel",
					body => "$amount $workout");
					return;
				}
			}
			
			
			elsif ($command eq 'sets')
			{

				if (int($extra) == 1)
				{
					$inrace = 1;
					$rest = 0;
					$sets = int($extra);
					$bot->say(
					channel => "$channel",
					body => "$sets set.");
					return;
				}
			
				elsif (int($extra) > 1 && int($extra) <= 10)
				{
					if ($rest == 0)
					{
						$rest = 10;
					}
					$inrace = 4;
					$sets = int($extra);
					$bot->say(
					channel => "$channel",
					body => "$sets sets - $rest second rest per set.");
					return;
				}
				
				else
				{
					$bot->say(
					channel => "$channel",
					body => "Sets must be a valid number between 1-10.");
					return;
				}

			}
			
			elsif ($command eq 'rest')
			{

				if (int($extra) == 0)
				{

					$rest = int($extra);
					$bot->say(
					channel => "$channel",
					body => "No rest.");
					return;
				}
			
				elsif (int($extra) > 0 && int($extra) <= 240)
				{
					if ($inrace !=4)
					{
						$bot->say(
						channel => "$channel",
						body => "Can't set rest for race with 1 set.");
						return;
					}
					
					$rest = int($extra);
					$bot->say(
					channel => "$channel",
					body => "$rest second rest each set.");
					return;
				}
				
				else
				{
					$bot->say(
					channel => "$channel",
					body => "Rest must be a valid number between 0-240.");
					return;
				}

			}	
			
			

			elsif ($command eq 'unjoin')
			{
				if(inRace($who) == 1)
				{
				
					if(inReady($who)==0)
					{
					
						my $index = 0;
						$index++ until $entrants[$index] eq $who;
						splice(@entrants, $index, 1);
						
						$bot->say(
						channel => "$channel",
						body => "$who has left the race!");
						return;
					}
					
				else
					{
						$bot->say(
						channel => "$channel",
						body => "$who - please unready before unjoining!");
						return;
					}
				
				}
			return;
			}
			
			
			elsif ($command eq 'entrants')
			{
			my $someNames;
				foreach my $entrant (@entrants)
				{
					if ($entrant~~@ready)
					{
						$someNames = $someNames . "$entrant(rdy), ";
					}
					else
					{
						$someNames = $someNames . "$entrant, ";
					}
					
				}
				$someNames = $someNames . join(', ', @entrants); 
				$bot->say(
				channel => "$channel",
				body => "Current Entrants: $someNames");
				return;
			}
			
			elsif ($command eq 'ready')
			{
			
			if ($workout eq '' || $amount == 0)
				{
					$bot->say(
					channel => "$channel",
					body => "Set goal before readying up! (.setgoal)");
					return;
				}

			elsif(inRace($who) == 1)
				{
					
					if(inReady($who)==0)
					{
						my $allentrants = @entrants ;
						my $allready = (@ready) + 1;
						push(@ready,$who);						
						$bot->say(
						channel => "$channel",
						body => "$who is ready! ($allready/$allentrants)");
						
						#start race if everyone is ready
						if (allReady() == 1)
						{
							startRace();
						}
						return;
					}
					return;

				}
				return;
			}

			elsif ($command eq 'unready')
			{
				if(inRace($who) == 1)
				{
				
					if(inReady($who)==1)
					{
						my $index = 0;
						$index++ until $ready[$index] eq $who;
						splice(@ready, $index, 1);
						
						$bot->say(
						channel => "$channel",
						body => "$who is not ready!");
						return;
					}
					return;
					
				}
				return;
			}
			return; #(break - if inRace is 1 or 4 and the code gets here, there is no reason to continue. 

		} #inrace = 1 (race created)
		
		#race in progress
		elsif ($inrace == 2 || $inrace == 5)
		{
		
			if($command eq 'done')
			{
			
				if(inReady($who)==1)
				{
				my $thetime = getTime($_[3]);
					
					if ($inrace == 5)
					{
						
						my $check = checkSet($who,$thetime);
						
						#if the guy isn't done yet - call seperate rest routine & return
						if ($check != 1)
						{
							my $starttimer = $_[3];
							$bot->forkit(
							channel => "$channel",
							run     => \&restforset,
							arguments => [$who,$rest,$starttimer]);
							return;
						}
						
				#else he's done - the program should proceed and finish him normally	
					}


					push (@finished,[$who,$thetime]);

					$bot->say(
					channel => "$channel",
					body => "$who has finished with a time of $thetime!");
					
					allDone();
					
					return;
					#if everyone has finished the race - call finished routine
				}
				return;
			}
		
		
			elsif ($command eq 'time')
			{
				my $time = getTime($_[3]);			
				$bot->say(
				channel => "$channel",
				body => "$time");
				return;
			}	


			elsif ($command eq 'entrants')
			{
				my $someNames = join(', ', @entrants); 
				$bot->say(
				channel => "$channel",
				body => "Current Entrants: $someNames");
				return;
			}
	
			elsif ($command eq 'goal')
			{
				my $tempgoal = "$amount $workout";
				if ($inrace == 5)
				{
					$tempgoal = "$sets sets of " . $tempgoal . " - $rest second rest per set.";
				}
				$bot->say(
				channel => "$channel",
				body => "$tempgoal");
				return;
			}
	
	
		return;
	
		} #$inrace == 2   race in progress

		elsif ($inrace == 3 || $inrace == 6)
		{	
		
			if ($command eq 'yes')
			{
				getResults();
				instaRematch();
				return;
			}
		
			elsif ($command eq 'no')
			{
				getResults();
				doneRace();
				return;
			}
			
			return;
		
		}
		
return;
		
}


sub startRace {
	
	#if multi race
	if ($inrace == 4 && $sets > 1)
	{
	$inrace = 5;
	$bot->say(
	channel => "$channel",
	body => "Race starting in 5 seconds - $sets sets of $amount $workout - $rest second rest per set.");

	}

	else{
	 #startrace
	#disable all commands except .done
	$inrace = 2;
	#race starting in 10
	$| = 1;
	
	$bot->say(
	channel => "$channel",
	body => "Race starting in 5 seconds - $amount $workout");
	}


	#first nickflash everyone
	my $someNames = join(', ', @ready); 
	$bot->say(
	channel => $channel,
	body => "$someNames");

	my $count = 5;

	#countdown -> GO
	while($count != 0)
		{
			sleep(1);
			$bot->say(
			channel => "$channel",
			body => "\x02" . $count . "\x02");
			$count--;
		}
		
	sleep(1);
	#GO - start timer
	$bot->say(
	channel => "$channel",
	body => "\x02\x034GO!!!\x03\x02");

	$start = Time::HiRes::gettimeofday();
	$start = $start + 9.3;
	return;
}

sub getSet{

my $racer = $_[0];
	foreach my $row (@inset){
		my $racerin = @$row[0];
			if ($racerin eq $racer)
			{
			
				return @$row[1];
			}
			
		}

}

#input racer
#checks if guys current set is
sub checkSet{
my $racer = $_[0];
my $thetime = $_[1];

#check if he exists:

my $thecounter = 0;
	foreach my $row (@inset){
		my $racerin = @$row[0];
			if ($racerin eq $racer)
			{
			my $lasttime;
				if (@$row[1] => 2)
				{
					
					my $test = 2;
					while ($test <= @$row[1])
					{
						
						$lasttime += @$row[$test];
						$test++;
					}
				
				
				}
			
				#if he's done
				if (@$row[1] == $sets)
				{


					$lasttime = ($thetime-$lasttime) - ((@$row[1] - 1) * $rest);
					
					#$lasttime = $sprintf("%.2f",$lasttime);
					push @$row,$lasttime;
					return 1;
				}
								
				#not done -increment 1
				else
				{	
					
					my $temp = @$row[1];
					#my $lasttime = @$row[$temp];
					$lasttime = ($thetime - $lasttime) - (($temp - 1) * $rest);
					
					#$lasttime = $sprintf("%.2f",$lasttime);
					$temp++;
					@$row[1] = $temp;
					push @$row,$lasttime;
					return 0;
				}
			
			}
			
			$thecounter++;

		}
		
		
#he's not in so add to array
push(@inset,[$racer,2,$thetime]);
return 0;
}

sub raceFinished{

	if ($inrace==5)
	{
		$inrace = 6;
	}
	
	else {$inrace=3;}

	$bot->say(
	channel => "$channel",
	body => "Race is finished!!");
		
	#gather results	
	my $result_string;
	foreach my $row(@finished){
		foreach my $val(@$row){
			$result_string = $result_string . $val . " ";
		}
	$result_string = $result_string . ", ";
	}


	#print results
	$bot->say(
	channel => "$channel",
	body => "Results: $result_string");
	
		#print results
	$bot->say(
	channel => "$channel",
	body => "Do you want to rematch? (.yes | .no) ");
	return;
}

#removes a person from the @entrants & @ready list (needed incase they DC or something)
sub remove{

my $toremove = $_[0];

#find in the entrants list -> if no exist break
@entrants = grep { $_  ne $toremove } @entrants;

#find in the ready list -> if no exist break
@ready = grep { $_  ne $toremove } @ready;

#find in finished list -> if no exist break
my $iter = 0;
	foreach my $row (@finished){

		my $racer = @$row[0];

		if ($racer eq $toremove)
		{
			splice(@finished, $iter, 1);
		}
		$iter++;
		}

return;
}

#takes user and rests them for 10 seconds then allows them to start racing again
sub restforset{
	shift;
	my $theracer = shift;
	my $break = shift;
	my $begintime = shift;
	$begintime = $begintime + ($break-.8);

	#wait certain amount of seconds
	while (Time::HiRes::gettimeofday() < $begintime){}
	my $currentset = getSet($theracer);
	print STDOUT "$theracer ~GO~ $amount $workout - Start set $currentset \n";
	return 1;

}

#makes sure everyone in entrants is ready
sub allReady{

my $allentrants = @entrants;
my $allready = @ready;

if ($allentrants==$allready){
	return 1;
	}
return 0;
}

#Finishes the race writes to DB and puts the race back in the status of '1' - started. (everyone still needs to ready up)
sub instaRematch{
my $allready = @ready;
	if ($allready == 0)
	{
		doneRace();
		return;
	}

	recordRace();
	
	undef (@ready);
	undef (@finished);
	undef (@entrants);
	undef (@inset);
	$start = undef;

	if ($inrace == 6)
	{
		$inrace = 4;
	}
	else
	{
		$inrace = 1;
	}
	$bot->say(
	channel => "$channel",
	body => "Rematch! Everyone ready up y'all. Goal:$sets sets of $amount $workout - $rest second rest per set.");
	return;
}


#Finishes the race writes to DB and resets all the flags
sub doneRace{

	#write results to DB
	my $allready = @ready;

	if ($allready == 0)
	{
		#change status back to -1
		$bot->say(
		channel => "$channel",
		body => "All racers removed - race not saved.");
		
		#initialize all variables
		endRace();
		return;
	}
	
	recordRace();

	#change status back to -1
	$bot->say(
	channel => "$channel",
	body => "Results saved - stay fit y'all.");
	
	#uninitialize all variables
	endRace();
	return;
}

sub recordRace
{
	my $string = '"num"';
	my $query = '"Select max(raceid) from underground"';
	my $count = `perl sql.pl $string $query`;
	$count++;
	my $thedate = getSQLDate();
	my $place = 1;
	#for each entrant - insert their time into the table
	#maybe should use forkit for this? Don't know if large races would cap memory.
	foreach my $row (@finished){
		my $racer = @$row[0];
		my $time = @$row[1];
		my $burnout = 0;
		if ($inrace > 3){$burnout = @$row[2];}
		my $query = "Insert into underground (date,raceid,place,user,time,sets,amount,workout,rest,burnout) VALUES('$thedate','$count', '$place', '$racer', '$time','$sets','$amount','$workout','$rest','$burnout')";
		`perl sql.pl insert "$query"`;
		$place++;
		}


}

sub getTime{
	my $end = $_[0];
	my $time = $end - $start;

	$time = sprintf("%.2f",$time);
	return $time;
}

sub allDone{

my $doneppl = @finished; #this will give you M
my $allready = @ready;
if ($doneppl==$allready){
	raceFinished();
	}
return;
}


sub endRace {
	#uninitialize all variables
	undef (@entrants);
	undef (@ready);
	undef (@finished);
	undef (@inset);
	$start = undef;
	$amount = 0;
	$workout = '';
	$inrace = -1;
	$sets = 1;
	$rest = 0;
	return;
}


sub leaderboard{
my $thegoal = $_[1];

my $translated = translateGoal($thegoal);

if ($translated eq '' )
{
	return;
}

my $query = "
SELECT date , sets, amount, workout, a.user, 
`time` - ( (sets * rest) - rest ) as `ordertime`, rest
FROM underground a
JOIN (
	SELECT user, min( `time` - ( (
	sets * rest
	) - rest ) ) AS `times` 
	FROM underground b
	WHERE $translated
	GROUP BY user
	ORDER BY 1 DESC)i 
	ON i.user = a.user AND i.times = `time` - ( (sets * rest) - rest ) 
ORDER BY `ordertime` ASC 
LIMIT 0 , 50
";
$| = 1;
my $result =`perl sql.pl lb "$query" "$thegoal"`;
my $paste = `perl pastebin.pl "$result"`;
print $paste;
$| = -1;
return;

}

sub getProgress {
my $thegoal = $_[1];
my $theuser = $_[2];

my $theworkout = mergeCheck($thegoal);

my $query = "
SELECT date,SUM(sets * amount), (SUM(time))-(SUM((sets*rest)-rest)), 
SUM(sets * amount)/((SUM(time))-(SUM((sets*rest)-rest))) 
from underground 
where $theworkout and user = '$theuser'	
group by date
";
$| = 1;
my $result = `perl sql.pl progress "$query" "$thegoal" "$theuser"`;
my $paste = `perl pastebin.pl "$result"`;
print $paste;
$| = -1;

return;



}


sub translateGoal{
	my $initialstring = shift;
	my $wherecall = '';
	my $theamount;
	my $theworkout;
	my $theset = 1;
	##first see if it is multiset (contains 'sets of')
	if (index($initialstring, "sets of") != -1)
	{
		my @splitter = split(/ /,$initialstring,5);
		$theset = @splitter[0];
		$theamount =  @splitter[3];
		$theworkout =  @splitter[4];
	}

	else
	{
		my @splitter = split(/ /,$initialstring,2);
		$theamount = @splitter[0];
		$theworkout =  @splitter[1];
	}

	
	#check everything is vaild - if not, return empty string ''
	if((int($theset) ne $theset) || (int($theamount) ne $theamount) || (int($theworkout) eq $theworkout))
	{
		print "Invalid goal. \n";
		return '';
	}


	my $workouts = mergeCheck($theworkout);
	$wherecall = "sets = '$theset' and amount = '$theamount' and $workouts";

	
	return $wherecall;


}

#this method should be called after a race - gets a pastebin of useful info about that race
sub getResults {

my $thedate = getSQLDate();
my $returnstring;
if ($inrace > 3)
	{

		$returnstring = "Results for $sets sets of $amount $workout race - ($thedate)\n\n";	
	
		my $whereclause = translateGoal("$sets sets of $amount $workout");
		my $query = "SELECT concat( user, ': ', min(`time`-((sets*rest)-rest)), '   (', date ,') ') FROM underground b WHERE $whereclause GROUP BY user, date ORDER BY min( `time` - ( ( sets * rest) - rest ) ) ASC  LIMIT 1";
		my $besttime = `perl sql.pl num "$query"`;
		$returnstring = $returnstring . "Best Time - $besttime \n\n\n";

		my $thecount = 1;
		my $rowstring = "";
		
		while ($thecount <= $sets)
		{
			$rowstring = $rowstring  . "set" . $thecount . "\t";
			$thecount++;
		}
		
		$rowstring = $rowstring  . "Time\t";
		$rowstring = $rowstring  . "RTime\t";
		$rowstring = $rowstring  . "Decay\t";
		
		$rowstring = $rowstring  . "PBTime\t";
		$rowstring = $rowstring  . "PBDecay\t";
		my $rowstring2;
		my $thecount = 1;
		while ($thecount <= $sets+5)
		{
			$rowstring2 = $rowstring2  . "----\t";
			$thecount++;
		}
		
		$returnstring = $returnstring . sprintf ("%-20s %s\n","Name",$rowstring);
		$returnstring = $returnstring . sprintf ("%-20s %s\n","----",$rowstring2);
		
		my $bodystring = getBurnout();
		
		$returnstring = $returnstring . $bodystring;
		
		open (FILE,">",'temp.txt');
		print FILE $returnstring;
		close (FILE);
		
		my $paste = `perl pastebin.pl string`;
		
		$bot->say(
		channel => "$channel",
		body => "$paste \n");
	}

else
	{
		#The program doesn't return anything yet (for noset race) until i work in PB's
		#$returnstring = "Results for $amount $workout race - ($thedate)\n";	
		#		$query = "
		#			SELECT concat( user, ": ", min( `time` - ( (
		#			sets * rest) - rest ) ) ) 
		#			FROM underground b
		#			WHERE workout = 'pushups'
		#			AND sets = '2'
		#			AND amount = '25'
		#			GROUP BY user
		#			ORDER BY min( `time` - ( (
		#			sets * rest) - rest ) ) ASC 
		#			LIMIT 1 ";
		#my $besttime = `perl sql.pl num "$query"`;
		#$returnstring = $returnstring . "Current Record - $besttime \n\n";
		
		#$rowstring = $rowstring  . "Time\t";
		#$rowstring = $rowstring  . "PB\t";
		#$returnstring = $returnstring . sprintf ("%-20s %-1s\n","Name",$rowstring);
	}
	
	
	
	
	return;



}

sub getBurnout {

use POSIX qw(floor ceil);

#might as well build string while calcing burnout so no need to go twice

my $firstsets = floor($sets/2);
my $secondsets = floor($sets/2) + ($sets%2);
my $firstavg;
my $secondavg;
my $returnstring;

my $firstsets = floor($sets/2);
my $secondsets = floor($sets/2) + ($sets%2);


#sort inset array:

sortResults();

my $thispastebin;
	foreach my $row (@inset)
	{
	my $thisrowreturned = "";
	my $firstavg;
	my $secondavg;
	my $thecounter = 2;
		while ($thecounter <= ($firstsets+1))
		{	

			$thisrowreturned = $thisrowreturned . sprintf("%.2f" , @$row[$thecounter]) . "\t";
			$firstavg += @$row[$thecounter];
			$thecounter++;
		}
		$firstavg = $firstavg/$firstsets;
		
		while ($thecounter <= ($firstsets+$secondsets+1))
		{
			$thisrowreturned = $thisrowreturned . sprintf("%.2f" , @$row[$thecounter]) . "\t";
			$secondavg += @$row[$thecounter];
			$thecounter++;
		}		
		$secondavg = $secondavg/$secondsets;
		#print "$firstavg $secondavg\n";

		
		
		foreach my $rows (@finished){
			if (@$rows[0] eq @$row[0])
			{
				push @$rows,(($firstavg-$secondavg)/($firstavg))*100;  #`time`-((sets*rest)-rest
				my $alttime = sprintf("%.2f" , @$rows[1]-(($sets*$rest)-$rest));
				$thisrowreturned = $thisrowreturned . $alttime . "\t";
				my $player = @$rows[0];	
				my $whereclause = translateGoal("$sets sets of $amount $workout");
				my $query = "SELECT concat(min(`time`-((sets*rest)-rest)), '\t',burnout) FROM underground b WHERE $whereclause and user = '$player' GROUP BY burnout Order BY min(`time`-((sets*rest)-rest)) ASC Limit 1";

				my $besttime = `perl sql.pl num "$query"`;
				$thisrowreturned = $thisrowreturned . sprintf("%.2f" ,@$rows[1]) . "\t";
				$thisrowreturned = $thisrowreturned . sprintf("%.3g%%" , (($firstavg-$secondavg)/($firstavg))*100) . "\t";
				$thisrowreturned = $thisrowreturned . "$besttime%";
			}

		}

		$thispastebin =  $thispastebin . sprintf ("%-20s %s\n",@$row[0],$thisrowreturned );
	}

	return $thispastebin;


}

sub sortResults {
#sorts the inset array.

if ($sets == 2) {@inset = sort { ($a->[2]+$a->[3]) <=> ($b->[2]+$b->[3]) } @inset;}

elsif ($sets == 3) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]) <=> ($b->[2]+$b->[3]+$b->[4]) } @inset;}

elsif ($sets == 4) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]) } @inset;}

elsif ($sets == 5) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]+$a->[6]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]+$b->[6]) } @inset;}

elsif ($sets == 6) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]+$a->[6]+$a->[7]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]+$b->[6]+$b->[7]) } @inset;}

elsif ($sets == 7) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]+$a->[6]+$a->[7]+$a->[8]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]+$b->[6]+$b->[7]+$b->[8]) } @inset;}

elsif ($sets == 8) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]+$a->[6]+$a->[7]+$a->[8]+$a->[9]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]+$b->[6]+$b->[7]+$b->[8]+$b->[9]) } @inset;}

elsif ($sets == 9) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]+$a->[6]+$a->[7]+$a->[8]+$a->[9]+$a->[10]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]+$b->[6]+$b->[7]+$b->[8]+$b->[9]+$b->[10]) } @inset;}

elsif ($sets == 10) {@inset = sort { ($a->[2]+$a->[3]+$a->[4]+$a->[5]+$a->[6]+$a->[7]+$a->[8]+$a->[9]+$a->[10]+$a->[11]) <=> ($b->[2]+$b->[3]+$b->[4]+$b->[5]+$b->[6]+$b->[7]+$b->[8]+$b->[9]+$b->[10]+$b->[11]) } @inset;}

}

sub mergeCheck {
	my $theworkout = shift;

	if ($theworkout eq 'pushups' || $theworkout eq 'push ups' || $theworkout eq 'pressups' || $theworkout eq 'press ups')
	{
		$theworkout = "workout in ('pushups','push ups' ,'pressups' ,'press ups')";
	}
	
	elsif ($theworkout eq 'situps' || $theworkout eq 'sit ups')
	{
		$theworkout = "workout in ('situps','sit ups')";
	}
	
	else
	{
		$theworkout = "workout = '$theworkout'";
	}

}



sub inReady{
	my $who = $_[0];

	if ($who~~@ready)
	{
		return 1;
	}
	else
	{
		return 0;
	}

}


sub inRace{
	my $who = $_[0];

	if ($who~~@entrants)
	{
		return 1;
	}
	else
	{
		return 0;
	}


}

sub getSQLDate {
use Time::localtime;
my $theyear= localtime->year()+1900;
my $themonth = sprintf("%02d", localtime->mon()+1);
my $theday = sprintf("%02d", localtime->mday());
return "$theyear-$themonth-$theday";


}

sub shutDown{

  $bot->shutdown("Stay Ripped...");

}


sub showAll{


my $string = '"select"';
my $query = '"Select date,raceid,place,sets,amount,workout,user,time from underground"';
$| = 1;
my $result = `perl sql.pl $string $query`;
my $paste = `perl pastebin.pl "$result"`;
print $paste;
$| = -1;
}



sub goalList{
my $thegoal = $_[1];
my $query = "
SELECT sets,amount,workout, count( raceid ) 
FROM underground
WHERE place =1
GROUP BY sets,amount,workout 
ORDER BY count( raceid ) DESC 
LIMIT 0 , 50
";
$| = 1;
my $result = `perl sql.pl agg "$query"`;
my $paste = `perl pastebin.pl "$result"`;
print $paste;
$| = -1;
}


sub getTotals{
$| = 1;
my $query = "Select MAX(raceid),SUM(sets*amount),SUM(time), COUNT(DISTINCT user) from underground";
my $result = `perl sql.pl totals "$query"`;
print "Totals: $result\n";
$| = -1;

}


sub getAvg{

my @params;
my $racer = $_[2];
my $cat = $_[1];
my $translated = translateGoal($cat);
if ($translated eq '' )
{
	return;
}

my $quers = "SELECT AVG( time ) FROM underground where $translated and user = '$racer'";

my $avg = `perl sql.pl num "$quers"`;

print "$avg \n";

}
