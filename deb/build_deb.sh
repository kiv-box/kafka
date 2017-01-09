#!/bin/bash
#
set -e
set -u

NAME='kafka'
KAFKA_VERSION='0.10.1.1'
SCALA_VERSION='2.11'
DEB_PKG_VERSION='-23'
DEB_PKG_DESCRIPTION='Apache Kafka is a distributed publish-subscribe messaging system.'
DEB_PKG_URL='https://kafka.apache.org/'
DEB_PKG_ARCH='all'
DEB_PKG_SECTION='misc'
DEB_PKG_LICENSE='Apache Software License 2.0'
ORIGDIR="$(pwd)"

PACKAGE_SRC_NAME="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
PACKAGE_SRC_URL="http://apache-mirror.rbc.ru/pub/apache/kafka/${KAFKA_VERSION}/${PACKAGE_SRC_NAME}"

MODULES_LIST='kafka-module-http-metrics-reporter kafka-module-graphite'

apt-get install -f maven ruby
gem install fpm

for MODULE in ${MODULES_LIST}
do
    if [ -d ${MODULE} ]
    then
        cd ${MODULE}
        git pull
    else
        git clone https://github.com/kiv-box/${MODULE}.git
        cd ${MODULE}
    fi
#sed -i "s/0.10.1.1/${version}/" pom.xml
#sed -i "s/2.11/${scala_version}/" pom.xml
mvn clean package
cd ..
done

#_ MAIN _#
rm -rf ${NAME}*.deb
if [[ ! -f "${PACKAGE_SRC_NAME}" ]]; then
  wget ${PACKAGE_SRC_URL}
fi

mkdir -p tmp && pushd tmp
rm -rf kafka
mkdir -p kafka
cd kafka
mkdir -p build/usr/lib/kafka
mkdir -p build/etc/default
mkdir -p build/etc/init
mkdir -p build/etc/kafka
mkdir -p build/var/log/kafka/csv
mkdir -p build/usr/lib/kafka/bin
mkdir -p build/usr/lib/kafka/libs

tar zxf ${ORIGDIR}/${PACKAGE_SRC_NAME}
cd kafka_${SCALA_VERSION}-${KAFKA_VERSION}
mv config/log4j.properties config/server.properties ../build/etc/kafka
mv * ../build/usr/lib/kafka
cd ../build

cp ${ORIGDIR}/files/server.properties_metrics etc/kafka
cp ${ORIGDIR}/files/kafka-broker.default etc/default/kafka-broker
cp ${ORIGDIR}/files/kafka-broker.upstart.conf etc/init/kafka-broker.conf
cp ${ORIGDIR}/files/kafka-topic-list-generator.sh usr/lib/kafka/bin/kafka-topic-list-generator.sh
chmod +x usr/lib/kafka/bin/kafka-topic-list-generator.sh

# Need fix it
cp ${ORIGDIR}/kafka-module-http-metrics-reporter/target/kafka-http-metrics-reporter-*-uber.jar usr/lib/kafka/libs
cp ${ORIGDIR}/kafka-module-graphite/target/kafka-graphite-*.jar usr/lib/kafka/libs

fpm --output-type deb \
    --name ${NAME} \
    --version ${KAFKA_VERSION}${DEB_PKG_VERSION} \
    --description "${DEB_PKG_DESCRIPTION}" \
    --url="${DEB_PKG_URL}" \
    --architecture ${DEB_PKG_ARCH} \
    --category ${DEB_PKG_SECTION} \
    --vendor "" \
    --license "${DEB_PKG_LICENSE}" \
    --maintainer "kiv.box@gmail.com" \
    --before-install ${ORIGDIR}/files/before-install \
    --after-install ${ORIGDIR}/files/after-install \
    --prefix=/ \
    --input-type dir \
    -- .
mv kafka*.deb ${ORIGDIR}
popd
