#!/bin/sh

cat ./build/contracts/Plantoid.json | python -c 'import json,sys;obj=json.load(sys.stdin); print(json.dumps(obj["abi"], indent=4));' > abi
cat ./build/contracts/GenesisProtocol.json | python -c 'import json,sys;obj=json.load(sys.stdin); print(json.dumps(obj["abi"], indent=4));' > abi2
cat ./build/contracts/AbsoluteVote.json | python -c 'import json,sys;obj=json.load(sys.stdin); print(json.dumps(obj["abi"], indent=4));' > abi4
cat ./build/contracts/Proxy.json | python -c 'import json,sys;obj=json.load(sys.stdin); print(json.dumps(obj["abi"], indent=4));' > abi3


value=`tr -d '\040\011\012\015' < abi`
sed "s/ABI/$value/g" index.html > index2.html

value=`tr -d  '\040\011\012\015' < abi2`
sed "s/IBA/$value/g" index2.html > index3.html

value=`tr -d  '\040\011\012\015' < abi3`
sed "s/PROX/$value/g" index3.html > index4.html

value=`tr -d '\040\011\012\015' < abi4`
sed "s/ABS/$value/g" index4.html > index5.html

sed -i.bak "s/ETHHH/$1/g" index5.html

sed -i.bak "s/GPPP/$2/g" index5.html

sed -i.bak "s/BSOLUTE/$3/g" index5.html

echo "deployed! :)"
