use strict;
use Text::CSV_XS;
my $csv = Text::CSV_XS->new({sep_char => "\t"});



#read all the IDF values
#assign the vector locations to each word
my %vocab;
open(IN,"output/idf.txt");
my $counter=0;
while(my $line = <IN>)
{
    if($csv->parse($line))
    {
        my @cols = $csv->fields();
        $vocab{$cols[0]}=$counter;
        $counter++;
    }
}
close(IN);

#creating vectors from the tf*idf values for each document
opendir(DIR,"output/tfidf");
my @files = readdir(DIR);
my %all_vecs;
foreach my $f (@files)
{
    if($f !~ /^\./)
    {
        print "Processing document: ".$f."\n";
        my @vector;
        print "Converting document to a vector\n";
        open(IN,"output/tfidf/$f");
        while(my $line = <IN>)
        {
            if($csv->parse($line))
            {
                my @cols = $csv->fields();
                $vector[$vocab{$cols[0]}] = $cols[1];
            }
            else
            {
                my $error = $csv->error_input;
                print "Error: ".$error."\n";
            }
        }
        $all_vecs{$f} =  [ @vector ];
        close(IN);
    }
}

#computing pairwise document similarity in all documents
my @vect_list = sort keys %all_vecs;
my %final_sim;
for(my $i=0;$i<=$#vect_list;$i++)
{
    for(my $j=$i+1;$j<=$#vect_list;$j++)
    {
        my @array1 = @{ $all_vecs{$vect_list[$i]}};
        my @array2 = @{ $all_vecs{$vect_list[$j]}};
        my $dot_product=0;
        my $length1=0;
        my $length2=0;
        for(my $k=0;$k<=$#array1;$k++)
        {
            $dot_product=$dot_product + ($array1[$k]*$array2[$k]);
            $length1=$length1 + ($array1[$k] * $array1[$k]);
            $length2=$length2 + ($array2[$k] * $array2[$k]);
        }
        my $sim = $dot_product / (sqrt($length1)*sqrt($length2));
        $final_sim{$vect_list[$i]}{$vect_list[$j]}=$sim;
        $final_sim{$vect_list[$j]}{$vect_list[$i]}=$sim;
    }
}
foreach my $f1 (keys %final_sim)
{
    my @f = keys %{ $final_sim{$f1}};
    foreach my $f2 (@f)
    {
        print $f1."\t".$f2."\t".$final_sim{$f1}{$f2}."\n";
    }
    print "\n";
}


