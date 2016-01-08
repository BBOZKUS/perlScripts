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
use Cwd;


## Getting table name from user.
print "Please enter the table name:\n";
$table = <STDIN>;
chomp($table);

## Getting schema name from user.
print "Please enter the schema:\n";
$schema = <STDIN>;
chomp($schema);


## Getting column names from user.
print "Please enter the column name seperated with comma('name,email', and assuming first column as private key for hibernate):\n";
$column_name_str = <STDIN>;
chomp($column_name_str);
@columns = split(/\,/,$column_name_str);

## Getting column types from user.
print "And the types of the fields of course it cannot be that easy, does it? :\):\n";
$column_type_str=<STDIN>;
chomp($column_type_str);
@column_types = split(/\,/,$column_type_str);

## Getting package from user.
## TO-DO folders will be replaced by this format
print "Please enter the package name(com.turkcell.myapp):\n";
$package  = <STDIN>;
chomp($package);

@folders = split(/\./,$package);

foreach $folder ( @folders ) {
	if ( !-d $folder ) {
			make_path $folder or die "Could not create folder $folder\n";
			chdir $folder;
	}
}



## Creating Model File

$model_folder = "model";
$model_file =$table."\.java";

if(!-d $model_folder) {
	make_path $model_folder or die "Could not create folder $model_folder\n";
	chdir $model_folder;
}


unless ( open FILE, '>'.$model_file) {
	die "\nUnable to create file $model_file\.Terminating\.\.\.\n";
}



print FILE "package $package.model;\n\n";

print FILE "import javax.persistence.Column;\n";
print FILE "import javax.persistence.Entity;\n";
print FILE "import javax.persistence.Id;\n";
print FILE "import javax.persistence.Table;\n\n";

print FILE "\@Entity\n";
print FILE "\@Table(name=\"".(uc $table)."\",schema=\"".(uc $schema)."\")\n";
print FILE "public class $table {\n\n";

print FILE "\t\@Id\n";

$index = 0;
foreach $column( @columns ) {
	print FILE "\t\@Column(name=\"".uc($column)."\")\n";
	print FILE "\tprivate $column_types[$index] $column;\n\n";
	$index = $index +1;
}

print FILE "\n\n";


$index = 0;
foreach $column( @columns ) {
	print FILE "\tpublic $column_types[$index] get".(ucfirst $column)."\(\) {\n";
	print FILE "\t\treturn $column;\n";
	print FILE "\t}\n\n";

	print FILE "\tpublic void set".(ucfirst $column)."\($column_types[$index] $column\) {\n";
	print FILE "\t\tthis\.$column \= $column ;\n";
	print FILE "\t}\n\n";
	$index++;
}
print FILE "}";

close FILE;

chdir "..";

##Creating DAO
$dao_folder = "dao";
$dao_file = $table."DAO\.java";

if(!-d $dao_folder) {
	make_path $dao_folder or die "Could not create folder $dao_folder\n";
	chdir $dao_folder;
}


unless ( open FILE, '>'.$dao_file) {
	die "\nUnable to create file $dao_file\.Terminating\.\.\.\n";
}

print FILE "package $package.dao;\n\n";

print FILE "import java.util.List;\n";
print FILE "import $package\.model\.$table;\n\n";

print FILE "public interface ".$table."DAO {\n";

print FILE "\tpublic void add\($table ".(lc $table)."\);\n";
print FILE "\tpublic void update\($table ".(lc $table)."\);\n";
print FILE "\tpublic void delete($column_types[0] $columns[0]);\n";
print FILE "\tpublic $table get($column_types[0] $columns[0]);\n";
print FILE "\tpublic List\<$table\> getAll\(\);\n";
print FILE "}";

close FILE;


##Creating DAOImpl
$dao_impl_file = $table."DAOImpl\.java";

unless ( open FILE, '>'.$dao_impl_file){
	die "\nUnable to create file $dao_impl_file\.Terminating\.\.\.\n";
}

print FILE "package $package\.dao;\n\n";

print FILE "import java.util.List;\n";
print FILE "import org.hibernate.SQLQuery;\n";
print FILE "import org.hibernate.Session;\n";
print FILE "import org.hibernate.SessionFactory;\n";
print FILE "import org.slf4j.Logger;\n";
print FILE "import org.slf4j.LoggerFactory;\n";
print FILE "import org.springframework.stereotype.Repository;\n";
print FILE "import $package\.model.$table;\n\n";

print FILE "\@Repository\n";
print FILE "public class ".$table."DAOImpl implements ".$table."DAO {\n";

print FILE "\tprivate static final Logger logger = LoggerFactory.getLogger(".$table."DAOImpl\.class\);\n";
print FILE "\tprivate SessionFactory sessionFactory;\n\n";

print FILE "\tpublic void setSessionFactory(SessionFactory sf){\n";
print FILE "\t\tthis\.sessionFactory \= sf;\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\tpublic void add\($table ".(lc $table)."\) {\n";
print FILE "\t\tSession session \= this\.sessionFactory\.getCurrentSession\(\);\n";
print FILE "\t\tsession.persist\(".(lc $table)."\);\n";
print FILE "\t\tlogger.info\(\"Insert on $table is succesful.\"\);\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\tpublic void update\($table ".(lc $table)."\) {\n";
print FILE "\t\tSession session \= this\.sessionFactory\.getCurrentSession\(\);\n";
print FILE "\t\tsession.update\(".(lc $table)."\);\n";
print FILE "\t\tlogger.info\(\"Update on $table is succesful.\"\);\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\tpublic void delete\($column_types[0] $columns[0]\) {\n";
print FILE "\t\tSession session \= this\.sessionFactory\.getCurrentSession\(\);\n";
print FILE "\t\t$table ".(lc $table)." \= \($table\) session\.load\($table\.class,$columns[0]\);\n";
print FILE "\t\tif\(null != ".(lc $table)."\) {\n";
print FILE "\t\t\tsession.delete\(".(lc $table)."\);\n";
print FILE "\t\t}\n";
print FILE "\t\tlogger.info\(\"Delete on $table is succesful.\"\);\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\tpublic $table get($column_types[0] $columns[0]) {\n";
print FILE "\t\t$table ".(lc $table)." = new $table\(\);\n";
print FILE "\t\tSession session \= this\.sessionFactory\.getCurrentSession\(\);\n";
print FILE "\t\t".(lc $table)." \= \($table\)session.get\($table\.class,$columns[0]\);\n";
print FILE "\t\tlogger.info\(\"Select on $table is succesful.\"\);\n";
print FILE "\t\treturn ".(lc $table).";\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\tpublic List\<$table\> getAll\(\) { \n";
print FILE "\t\tSession session \= this\.sessionFactory\.getCurrentSession\(\);\n";
print FILE "\t\tList\<$table\> result = session.createQuery\(\"from $table\"\).list\(\);\n";
print FILE "\t\tlogger.info\(\"Select all on $table is succesful.\"\);\n";
print FILE "\t\treturn result;\n";
print FILE "\t}\n\n";

print FILE "}";

chdir "..";

#creating Service

$service_folder = "service";
$service_file = $table."Service\.java";

if(!-d $service_folder) {
	make_path $service_folder or die "Could not create folder $service_folder\n";
	chdir $service_folder;
}


unless ( open FILE, '>'.$service_file) {
	die "\nUnable to create file $service_file\.Terminating\.\.\.\n";
}

print FILE "package $package.service;\n\n";

print FILE "import java.util.List;\n";
print FILE "import $package\.model\.$table;\n\n";

print FILE "public interface ".$table."Service {\n";

print FILE "\tpublic boolean add\($table ".(lc $table)."\);\n";
print FILE "\tpublic boolean update\($table ".(lc $table)."\);\n";
print FILE "\tpublic boolean delete($column_types[0] $columns[0]);\n";
print FILE "\tpublic $table get($column_types[0] $columns[0]);\n";
print FILE "\tpublic List\<$table\> getAll\(\);\n";
print FILE "}";

close FILE;

#creating ServiceImpl

$service_impl_file = $table."ServiceImpl\.java";

unless ( open FILE, '>'.$service_impl_file) {
	die "\nUnable to create file $service_file\.Terminating\.\.\.\n";
}

print FILE "package $package\.service;\n\n";
print FILE "import java.sql.SQLException;\n";
print FILE "import java.util.List;\n";
print FILE "import org.hibernate.JDBCException;\n";
print FILE "import org.slf4j.Logger;\n";
print FILE "import org.slf4j.LoggerFactory;\n";
print FILE "import org.springframework.stereotype.Service;\n";
print FILE "import org.springframework.transaction.annotation.Transactional;\n\n";
print FILE "import $package\.model.$table;\n";
print FILE "import $package\.dao.$table"."DAO;\n\n";

print FILE "\@Service\n";
print FILE "public class $table"."ServiceImpl implements $table"."Service {\n\n";

print FILE "\tprivate $table"."DAO ".(lc $table)."DAO;\n\n";
print FILE "\tprivate static final Logger logger \= LoggerFactory.getLogger\($table"."ServiceImpl\.class\);\n";

print FILE "\tpublic void set$table"."DAO\($table"."DAO ".(lc $table)."DAO\) {\n";
print FILE "\t\tthis\.".(lc $table)."DAO \= ".(lc $table)."DAO;\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\t\@Transactional\n";
print FILE "\tpublic boolean add\($table ".(lc $table)."\) {\n";
print FILE "\t\ttry {\n";
print FILE "\t\t\tthis\.".(lc $table)."DAO.add\(".(lc $table)."\);\n";
print FILE "\t\t\treturn true;\n";
print FILE "\t\t} catch (JDBCException e) { \n";
print FILE "\t\t\tSQLException cause = (SQLException) e.getCause();\n";
print FILE "\t\t\tlogger.info\(\"Exception while inserting a record to $table: \"\+cause\);\n";
print FILE "\t\t\treturn false;\n";
print FILE "\t\t}\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\t\@Transactional\n";
print FILE "\tpublic boolean update\($table ".(lc $table)."\) {\n";
print FILE "\t\ttry {\n";
print FILE "\t\t\tthis\.".(lc $table)."DAO.update\(".(lc $table)."\);\n";
print FILE "\t\t\treturn true;\n";
print FILE "\t\t} catch (JDBCException e) { \n";
print FILE "\t\t\tSQLException cause = (SQLException) e.getCause();\n";
print FILE "\t\t\tlogger.info\(\"Exception while updating a record from $table: \"\+cause\);\n";
print FILE "\t\t\treturn false;\n";
print FILE "\t\t}\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\t\@Transactional\n";
print FILE "\tpublic boolean delete\($column_types[0] $columns[0]\) {\n";
print FILE "\t\ttry {\n";
print FILE "\t\t\tthis\.".(lc $table)."DAO.delete\($columns[0]\);\n";
print FILE "\t\t\treturn true;\n";
print FILE "\t\t} catch (JDBCException e) { \n";
print FILE "\t\t\tSQLException cause = (SQLException) e.getCause();\n";
print FILE "\t\t\tlogger.info\(\"Exception while deleting a record from $table: \"\+cause\);\n";
print FILE "\t\t\treturn false;\n";
print FILE "\t\t}\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\t\@Transactional\n";
print FILE "\tpublic $table get\($column_types[0] $columns[0]\) {\n";
print FILE "\t\ttry {\n";
print FILE "\t\t\treturn this\.".(lc $table)."DAO.get\($columns[0]\);\n";
print FILE "\t\t} catch (JDBCException e) { \n";
print FILE "\t\t\tSQLException cause = (SQLException) e.getCause();\n";
print FILE "\t\t\tlogger.info\(\"Exception while getting a record from $table: \"\+cause\);\n";
print FILE "\t\t\treturn null;\n";
print FILE "\t\t}\n";
print FILE "\t}\n\n";

print FILE "\t\@Override\n";
print FILE "\t\@Transactional\n";
print FILE "\tpublic List\<$table\> getAll\(\) {\n";
print FILE "\t\ttry {\n";
print FILE "\t\t\treturn this\.".(lc $table)."DAO.getAll\(\);\n";
print FILE "\t\t} catch (JDBCException e) { \n";
print FILE "\t\t\tSQLException cause = (SQLException) e.getCause();\n";
print FILE "\t\t\tlogger.info\(\"Exception while getting a record from $table: \"\+cause\);\n";
print FILE "\t\t\treturn null;\n";
print FILE "\t\t}\n";
print FILE "\t}\n\n";

print FILE "}";


close FILE;

chdir "..";
