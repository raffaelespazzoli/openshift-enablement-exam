#!/bin/bash
set -e
cp $COOKIES_DIR/cookies.txt $INSTALL_DIR_BINARIES/
curl --location -c $INSTALL_DIR_BINARIES/cookies.txt -b $INSTALL_DIR_BINARIES/cookies.txt --insecure "http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_grid_1of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_grid_1of2.zip
curl --location -c $INSTALL_DIR_BINARIES/cookies.txt -b $INSTALL_DIR_BINARIES/cookies.txt --insecure "http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_grid_2of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_grid_2of2.zip
curl --location -c $INSTALL_DIR_BINARIES/cookies.txt -b $INSTALL_DIR_BINARIES/cookies.txt --insecure "http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_1of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_database_1of2.zip
curl --location -c $INSTALL_DIR_BINARIES/cookies.txt -b $INSTALL_DIR_BINARIES/cookies.txt --insecure "http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_2of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_database_2of2.zip 
    