#!/bin/bash 

echo '本日の作業ディレクトリを作成します'

date=$(date +%Y%m%d)

mkdir -p "$date"

touch "$date/prompt.md"

echo "Created $date/prompt.md"

