#!/bin/sh

value=`tr -d '\n' < abi`
sed "s/ABI/$value/g" index.html > index2.html
sed -i.bak "s/ETH/$1/g" index2.html

