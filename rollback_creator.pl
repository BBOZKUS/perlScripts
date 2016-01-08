#!/usr/bin/perl

######################################################################
# Created by : Berkin Bozkus										 #		
# Version     Date		     Modified        Description 			 #
# ---------   ----------     ----------      ----------------------  #
# 1.0         04/11/2014     Berkin Bozkus   Initial Version		 #	
######################################################################

use File::Basename qw( fileparse );
use File::Path qw( make_path );
use File::Spec;


print "Please enter the directory where DDL files stored (Please enter full path like C:\\Users\\Berkin\\ddls ):\n";

$directory = <STDIN>;
chomp ($directory);

# Prompt user for inputs

print "Rollbacks will be created under the folder:\n".$directory."\\rollbacks\n";
print "Grant scripts will be created under the folder:\n".$directory."\\dcls\n";
print "Revoke scripts be created under the folder:\n".$directory."\\dcl-rollbacks\n";


print "Plesae enter grant options seperated with comma ( SELECT, INSERT, DELETE ):\n";
$grant_options = <STDIN>;
chomp($grant_options);
print "Please enter user for grant scripts (DWH_SELECT_ROLE, SRV_127063_SO ) : \n";
$grant_user = <STDIN>;
chomp($grant_user);


# Open directory and get .ddl files

opendir ( DIR,$directory) or die "COULD NOT OPEN ".$directory;

@files;

while (my $file = readdir(DIR)){
	push @files,$file if ($file =~m/.*\.ddl$/);
} 

# For each file if it is table creation script generate files.

foreach $file (@files){
		
		# Getting the content of ddl file.
		
		$filename = $directory.'\\'.$file;
		open ( FILE, '<', $filename) or die "COULD NOT OPEN ".$filename;

		my $file_content = '';

		while( <FILE> ) {
			$file_content = $file_content.$_;
		}
		
		close(FILE);
		
		
		if ( $file_content =~m/\W*CREATE\W*TABLE\W*(\w*\.\w*)\W*\(/ ){
			# if it is a create script parse table name.
			$table_name = $1;
		
			@table_props = split ('\.',$table_name);

			#Generate rollback files
			
			$rollback_folder = $directory.'\\rollbacks';
			
			if ( !-d $rollback_folder ) {
				make_path $rollback_folder or die "Failed to create path: $rollback_folder";
			}
			
			$rollback_file = $directory.'\\rollbacks\\DROP_'.$table_props[0].'_'.$table_props[1].'.ddl';

			open (FILEOUT, '>' , $rollback_file) or die "COULD NOT OPEN ".$rollback_file;

			print FILEOUT "DROP TABLE ".$table_name.";";
			
			close(FILEOUT);

			#Generate grant scripts.
			
			$grant_folder = $directory.'\\dcls';
			
			if ( !-d $grant_folder ) {
				make_path $grant_folder or die "Failed to create path: $grant_folder";
			}
			
			$grant_file = $directory.'\\dcls\\GRANT_'.$table_props[0].'_'.$table_props[1].'.dcl';
			
			open (FILEOUT1 , '>' , $grant_file) or die "COULD NOT OPEN ".$grant_file;
			
			print FILEOUT1 "GRANT ".$grant_options." ON ".$table_name." TO ".$grant_user.";";

			close(FILEOUT1);
			
			#Generate revoke scripts.
			
			$revoke_folder = $directory.'\\dcl-rollbacks';
			
			if ( !-d $revoke_folder ) {
				make_path $revoke_folder or die "Failed to create path: $revoke_folder";
			}
			
			$revoke_file = $directory.'\\dcl-rollbacks\\REVOKE_'.$table_props[0].'_'.$table_props[1].'.dcl';
			
			open (FILEOUT2 , '>' , $revoke_file) or die "COULD NOT OPEN ".$revoke_file;
			
			print FILEOUT2 "REVOKE ".$grant_options." ON ".$table_name." FROM ".$grant_user.";";

			close(FILEOUT2);
		}
		

}



