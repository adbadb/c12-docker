VERSION="1.2.19"
SHA1="49ba75057d3fdf40d8b6f9406f2027bb6d0f6b08"
TARBALL="apache-cassandra-${VERSION}-bin.tar.gz"
URL="http://archive.apache.org/dist/cassandra/${TARBALL}"
cd /
set -e
set -x

# download the tarball from an Apache mirror
# verify the checksum
# untar in /opt, cleanup, symlink to /opt/cassandra

echo "${SHA1} ${TARBALL}" > ${TARBALL}.sha1
wget ${URL}
sum --check ${TARBALL}.sha1
tar -xzf ${TARBALL} -C /opt
rm -f ${TARBALL} ${TARBALL}.sha1
ln -s /opt/apache-cassandra-$VERSION /opt/cassandra
rm -f $0
