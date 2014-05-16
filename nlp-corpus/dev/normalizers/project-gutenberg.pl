#!/usr/bin/perl
#use Tie::File;
#use Data::Dumper;
$| = 1;
my $triggerPhrase = 'PROJECT GUTENBERG EBOOK';
my $workingDir = '/root/high/nlp-corpus/nlp-corpus/dev/normalizers/test-corpus/';
my $moveTo = '/root/high/nlp-corpus/nlp-corpus/dev/normalizers/normalized/';
my %fileCharHash;
my $PercentageThreshold = 80;

system('mkdir -p ' . $moveTo);

open(FILE,">fileResults");

init($workingDir);

sub init {
    $workingDir = shift;
    opendir(DIR, $workingDir);
    my @dir = readdir(DIR);
    my $numberFiles = $#dir;
    $numberFiles -= 1; # base 1, remove . & ..
    my $fileNumber = 0;
    for (0 .. $#dir) {
        my $fileName = $dir[$_];
        if (-e $workingDir.$fileName) {
            if (!(-d $workingDir.$fileName)) {
                $fileNumber++;
                print "($fileNumber/$numberFiles) Working on $fileName\n";
                if (fileAnalyze($workingDir.$fileName)) {
                    if (-e $workingDir.$fileName) {
                        system('mv ' . $workingDir.$fileName . ' ' . $moveTo.$fileName);
                    }
                }
            } else {
                if ($fileName ne "." && $fileName ne "..") {
                    init($workingDir);
                }
            }
        }
    }
}

sub displayInfo {
	my $chars = shift;
	my $fileName = shift;
	my %hash = @_;

	print FILE $fileName . "\n";
	foreach (sort { ($hash{$b} <=> $hash{$a}) || ($hash{$b} cmp $hash{$a}) } keys %hash) {
        my $percentage = (($hash{$_} / $chars) * 100);
        if ($_ eq 'alphabet') {
            if ($percentage <= $PercentageThreshold) {
                unlink $fileName;
            }
        }
		print FILE "\t$_: " . $percentage . "%\n";
	}
}


sub fileAnalyze {
	my $file = shift;
	my @a;
	my @b;
	my $f;
	my $startDelete = 0;
	my $title;

	open(F, "$file");
#tie @a, 'Tie::File', $file or die $!;
while (my $l = <F>) {
chomp($l);
push @a, $l;
}
	close(F);

	my $linea = 0;
	my $lineb = 0;
	my $deleter = 1;
	while ($linea < $#a ) {
		$a[$linea] =~ s/\r//;
		if ($a[$linea] =~ /^Online.+Distributed.+Proofreading.+Team./i){
			splice @a, $linea, 1;
		} elsif ($a[$linea] =~ /^End of.*\Q$triggerPhrase\E/i) {
			splice @a, $linea, 1;
		} elsif ($a[$linea] =~ /^Produced by/) {
			splice @a, $linea, 1;
		} else {
			if ($a[$linea] =~ /\*{3,}.*\Q$triggerPhrase\E/i) {
				splice @a, $linea, 1;
				if ($deleter) {
					$deleter = 0;
				} else {
					$deleter = 1;
				}

			} else {
				if ($deleter) {
					splice @a, $linea, 1;
				} else {
					$linea++;
				}
			}
		}
	}

    $f = join ' ', @a; 
open (F, ">$file");
print F $f;
close(F);
    splice @a;
    $a[0] = $f;
    &gatherCharHash($f,$file);
    return 1;
}


sub gatherCharHash {
	my $f = shift;
    my $fileName = shift;
	my $count = 0;
	my %hash;
	foreach (split(//, $f)) {
		$_ =~ tr/[A-Z]/[a-z]/;
        $_ =~ s/[a-z]/alphabet/;
        $_ =~ s/[',!\?\.]/alphabet/;
		$count++;
		if (defined $hash{$_}) {
			$hash{$_}++;
		} else {
			$hash{$_} = 0;
		}
	}
	displayInfo($count, $fileName, %hash);
}
