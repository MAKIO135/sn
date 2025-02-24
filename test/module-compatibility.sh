#!/bin/bash
export NODE_ENV=development
NAME=$(jq -r .name package.json)
set -e
node_major_version=$(node --version|sed 's/v\([^.]*\).*/\1/g')
rm -rf e2e
mkdir -p e2e
rm -f $($NAME*.tgz)
npm pack
tarball=($NAME*.tgz)
mv "$tarball" e2e
cd e2e
cp -R ../test/module-compatibility .
cd module-compatibility
npm install "../$tarball" 
echo "testing node commonjs module.exports"
node commonjs-exports.js
echo "testing node commonjs alias"
node commonjs-alias.js
if [ "$node_major_version" -ge 14 ]
  then
  echo "testing typescript"
  cp esm.mjs typescript.ts
  node --loader ts-node/esm  typescript.ts
  echo "testing node esm"
  node esm.mjs
fi
echo "testing webpack commonjs alias"
npx webpack --entry ./commonjs-alias.js && node dist/main.js
echo "testing webpack commonjs module.exports"
npx webpack --entry ./commonjs-exports.js && node dist/main.js
echo "testing webpack esm"
npx webpack --entry ./esm.mjs && node dist/main.js
echo "testing webpack esm with source-map-loader for warnings"
OUT=$(npx webpack --entry ./esm.mjs --config ./webpack.config-sourcemap.js 2>&1)
if [[ "$OUT" == *"WARNING"* ]]; then
  echo $OUT
  exit 1
fi
cd ..

cd ..
rm -rf e2e