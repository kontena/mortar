#!/bin/sh

set -ue

brew install squashfs
curl -sL https://github.com/kontena/ruby-packer/releases/download/2.6.0-0.6.0/rubyc-2.6.0-0.6.0-osx-amd64.gz | gunzip > /usr/local/bin/rubyc
chmod +x /usr/local/bin/rubyc
version=${TRAVIS_TAG#"v"}
package="mortar-darwin-amd64-${version}"
rubyc -o $package mortar
./$package --version

# ship to github
curl -sL https://github.com/aktau/github-release/releases/download/v0.7.2/darwin-amd64-github-release.tar.bz2 | tar -xjO > /usr/local/bin/github-release
chmod +x /usr/local/bin/github-release
/usr/local/bin/github-release upload \
    --user kontena \
    --repo mortar \
    --tag $TRAVIS_TAG \
    --name $package \
    --file ./$package

mkdir -p upload
mv $package upload/
