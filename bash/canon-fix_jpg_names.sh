#!/bin/bash -x

echo 'Canon flash card JPG file names will be fixed.'
echo 'Namely, the leading underscore _ will be replaced with I.'
echo 'I.e., _MG will be replaced with IMG in current folder.'

for i in _* ; do mv $i I${i#*_} ; done
