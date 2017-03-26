#!/bin/bash

SQLITECMD=/usr/bin/sqlite3
DB=tagnotepad.db
 
function usage () {
  echo "Usage: $0 [options] [textfiles...]"
  echo "Options:"
  echo "  -t <taglist>    Add tag(s) to the note(s) (comma separated list)"
  echo "  -h              Display this help and quit"
  echo
  echo "Note that the note will be named according to the filename, stripped of its .txt extension"
  exit 1
}

function filenametonotename () {
  sed -e 's/.txt$//' -e 's@^.*/@@'
}

function initdb () {
  echo "Initializing database in $DB"
  # create database scheme
  echo "CREATE TABLE android_metadata (locale TEXT);" | $SQLITECMD $DB
  echo "INSERT INTO android_metadata VALUES('fr_FR');" | $SQLITECMD $DB
  echo "CREATE TABLE notes (_id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT, body TEXT, created INTEGER, modified INTEGER);" | $SQLITECMD $DB
  echo "CREATE TABLE tags (_id INTEGER PRIMARY KEY AUTOINCREMENT,tagname TEXT, UNIQUE(tagname));" | $SQLITECMD $DB
  echo "CREATE TABLE mapping (_id INTEGER PRIMARY KEY AUTOINCREMENT,noteid INTEGER, tagid INTEGER, UNIQUE(noteid, tagid));" | $SQLITECMD $DB
  echo "CREATE TRIGGER mapping_delete AFTER DELETE ON notes BEGIN DELETE FROM mapping  WHERE noteid =old._id; END;" | $SQLITECMD $DB
}

function addtag () {
  TAGNAME="$1"
  TAGID=$(echo "SELECT _id FROM "tags" WHERE tagname='${TAGNAME}';" | $SQLITECMD $DB)
  if [ -z "$TAGID" ] ; then
    echo "Adding tag ${TAGNAME}"
    echo "INSERT INTO tags (tagname) VALUES('${1}');" | $SQLITECMD $DB
  fi
}

function addnotefromfile () {
  FILENAME="${1}"
  NOTENAME="$(echo ${FILENAME} | filenametonotename)"
  #Here, replacing single quotes with double single quotes as detailed here: http://stackoverflow.com/questions/603572/how-to-properly-escape-a-single-quote-for-a-sqlite-database
  NOTECONTENT="$(cat "${FILENAME}" | sed -e "s/'/\'\'/g")"
  TIMESTAMP="$(date +%s%3N)"
  NOTEID=$(echo "SELECT _id FROM notes WHERE title='${NOTENAME}';" | $SQLITECMD $DB)
  if [ -z "$NOTEID" ] ; then 
    echo "Adding $FILE to the database"
    echo "INSERT INTO 'notes' (title, body, created, modified) VALUES ('${NOTENAME}', '${NOTECONTENT}', '${TIMESTAMP}', '${TIMESTAMP}');" | $SQLITECMD $DB 
  else
    echo "Note ${NOTENAME} already existing... Skipping."
  fi
}

function settag () {
  TAGNAME="$1"
  NOTENAME="$(echo ${FILENAME} | filenametonotename)"
  TAGID=$(echo "SELECT _id FROM tags WHERE tagname='${TAGNAME}';" | $SQLITECMD $DB)
  NOTEID=$(echo "SELECT _id FROM notes WHERE title='${NOTENAME}';" | $SQLITECMD $DB)
  if [ -z $(echo "SELECT _id FROM mapping WHERE tagid='${TAGID}' AND noteid='${NOTEID}';" | $SQLITECMD $DB) ] ; then
    echo "Setting tag '${TAGNAME}' to note '${NOTENAME}'"
    echo "INSERT INTO mapping (noteid, tagid) VALUES ('${NOTEID}', '${TAGID}');" | $SQLITECMD $DB 
  else
    echo "Note $NOTENAME already tagged with $TAGNAME"
  fi
}

# Parse commandline options
#
# Adapted from http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
# 
# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )

# Initialize empty vars

NOINITDB=
SETTAG=
TAGLIST=
FILELIST=

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--tag)
    SETTAG=1
    TAGLIST="${2}"
    shift # past argument
    ;;
    -h|--help)
    usage
    ;;
    *) # Assume the rest of the arguments as filenames
      if [ -z "${FILELIST}" ] ; then
        FILELIST="${1}"
      else
        FILELIST="${FILELIST}|${1}" # Add the filename to the pipe separated list 
      fi
    ;;
esac
shift # past argument or value
done

# Create db if necessary 
if [ -e $DB ] ; then
  echo "File $DB already exists, skipping database initialization"
else 
  initdb
fi

# First, add the tags if present
if [ -n "$SETTAG" ] ; then
  IFS=','
  for TAG in $TAGLIST ; do
    addtag $TAG;
  done
fi

# Then add notes to the database
IFS='|'
for FILE in $FILELIST ; do
  addnotefromfile $FILE
  # tag the file if the switch is present
  if [ -n "$SETTAG" ] ; then
    IFS=','
    for TAG in $TAGLIST ; do
      settag $TAG $FILE;
    done
  fi
done

