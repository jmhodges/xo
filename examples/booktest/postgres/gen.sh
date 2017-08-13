#!/bin/bash

set -o errexit

DBUSER=xouser
DBHOST=localhost
DBNAME=booktest

DB=postgres://$DBUSER@$DBHOST/$DBNAME?sslmode=disable

EXTRA=$1

SRC=$(realpath $(cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd ))

XOBIN=$(which xo)
if [ -e $SRC/../../../xo ]; then
  XOBIN=$SRC/../../../xo
fi

DEST=$SRC/models

set -x

mkdir -p $DEST
rm -f $DEST/*.go
rm -f $SRC/postgres

psql -U postgres -h $DBHOST -c "drop database if exists ${DBNAME};"
psql -U postgres -h $DBHOST -c "create database ${DBNAME} owner ${DBUSER};"

psql -U $DBUSER -h $DBHOST $DBNAME << 'ENDSQL'
CREATE TABLE authors (
  author_id SERIAL PRIMARY KEY,
  name text NOT NULL DEFAULT ''
);

CREATE INDEX authors_name_idx ON authors(name);

CREATE TYPE book_type AS ENUM (
  'FICTION',
  'NONFICTION'
);

CREATE TABLE books (
  book_id SERIAL PRIMARY KEY,
  author_id integer NOT NULL REFERENCES authors(author_id),
  isbn text NOT NULL DEFAULT '' UNIQUE,
  booktype book_type NOT NULL DEFAULT 'FICTION',
  title text NOT NULL DEFAULT '',
  year integer NOT NULL DEFAULT 2000,
  available timestamp with time zone NOT NULL DEFAULT 'NOW()',
  tags varchar[] NOT NULL DEFAULT '{}'
);

CREATE INDEX books_title_idx ON books(title, year);

CREATE FUNCTION say_hello(text) RETURNS text AS $$
BEGIN
  RETURN CONCAT('hello ', $1);
END;
$$ LANGUAGE plpgsql;

CREATE INDEX books_title_lower_idx ON books(title);

ENDSQL

$XOBIN $DB -o $SRC/models -j $EXTRA

$XOBIN $DB -N -M -B -T AuthorBookResult --query-type-comment='AuthorBookResult is the result of a search.' -o $SRC/models $EXTRA << ENDSQL
SELECT
  a.author_id::integer AS author_id,
  a.name::text AS author_name,
  b.book_id::integer AS book_id,
  b.isbn::text AS book_isbn,
  b.title::text AS book_title,
  b.tags::text[] AS book_tags
FROM books b
JOIN authors a ON a.author_id = b.author_id
WHERE b.tags && %%tags StringSlice%%::varchar[]
ENDSQL

pushd $SRC &> /dev/null

go build
./postgres $EXTRA

popd &> /dev/null

psql -U $DBUSER -h $DBHOST <<< 'select * from books;'
