#!/bin/sh

value=`tr -d '\n' < abi`
sed "s/ABI/$value/g" index.html > index2.html

value=`tr -d '\n' < abi2`
sed "s/IBA/$value/g" index2.html > index3.html

sed -i.bak "s/ETH/$1/g" index3.html

sed -i.bak "s/GP/$2/g" index3.html

