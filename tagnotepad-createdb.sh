#!/bin/bash

SQLITECMD=/usr/bin/sqlite3
DB=tagnotepad.db
 
function usage () {
  echo "Usage: $0 [options] [textfiles...]"
  echo "Options:"
  echo "  -a          Add the files to an existing database"
  echo "  -t <tag>    Add add a tag to the note(s) (can be specified multiple times)"
  echo "  -h          Display this help and quit"
  exit 1
}

function initdb () {
  # Checks if dbfile already exists
  if [ -e $DB ] ; then
    echo "Error: $DB already exists"
    exit 1
  fi
  # create database scheme
  echo "CREATE TABLE android_metadata (locale TEXT);" | $SQLITECMD $DB
  echo "CREATE TABLE notes (_id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT, body TEXT, created INTEGER, modified INTEGER);" | $SQLITECMD $DB
  echo "CREATE TABLE tags (_id INTEGER PRIMARY KEY AUTOINCREMENT, tagname TEXT, UNIQUE(tagname));" | $SQLITECMD $DB
  echo "CREATE TABLE mapping (_id INTEGER PRIMARY KEY AUTOINCREMENT, noteid INTEGER, tagid INTEGER, UNIQUE(noteid, tagid));" | $SQLITECMD $DB
  echo "CREATE TRIGGER mapping_delete AFTER DELETE ON notes BEGIN DELETE FROM mapping  WHERE noteid =old._id; END;" | $SQLITECMD $DB
}

function addfile () {

}

function settag () {

}

# Debug
if [ "$1" == "initdb" ] ; then
  initdb
fi
