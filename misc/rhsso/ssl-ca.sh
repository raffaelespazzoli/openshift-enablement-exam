#WORK_DIR=$HOME/ssl_ca

# 1) Blow away any existing SSL related files
echo -en "Deleting: $WORK_DIR"
rm -rf $WORK_DIR

# 2) Create directory structure that facilitates generation of keys, keystores and self-signed certs.
echo -en "\nCreating: $WORK_DIR"
mkdir -p $WORK_DIR/certs $WORK_DIR/newcerts $WORK_DIR/private $WORK_DIR/crl

# 3) Create files that assist a Certificate Authority(CA) sign a Certificate Signing Request (CSR)
echo -en "\nAdding: index.txt, serial and ca.cnf to $WORK_DIR\n"

touch $WORK_DIR/index.txt
chmod 0664 $WORK_DIR/index.txt

echo "01" > $WORK_DIR/serial
chmod 0664 $WORK_DIR/serial

cat <<EOF > $WORK_DIR/ca.cnf
[ ca ]
default_ca = acme_ca

[ acme_ca ]
dir             = .                         # Where everything is kept
certs           = $WORK_DIR/certs           # Where the issued certs are kept
crl_dir         = $WORK_DIR/crl             # Where the issued crl are kept
database        = $WORK_DIR/index.txt       # database index file.
#unique_subject  = no                       # Set to 'no' to allow creation of
                                            # several certificates with same subject.
new_certs_dir   = $WORK_DIR/newcerts        # default place for new certs.
certificate     = $WORK_DIR/acme-ca.crt     # The CA certificate
serial          = $WORK_DIR/serial          # The current serial number
crlnumber       = $WORK_DIR/crlnumber       # the current crl number
crl             = $WORK_DIR/acme-ca.crl         # The current CRL
private_key     = $WORK_DIR/private/acme-ca.key # The private key
RANDFILE        = $WORK_DIR/private/.rand    # private random number file
x509_extensions = usr_cert                  # The extentions to add to the cert
default_days    = 365                       # how long to certify for
default_crl_days= 30                        # how long before next CRL
default_md      = sha256                    # use SHA-256 by default
preserve        = no                        # keep passed DN ordering
policy          = acme_policy
x509_extensions = certificate_extensions

[ acme_policy ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ certificate_extensions ]
basicConstraints=CA:false
EOF

chmod 0664 $WORK_DIR/ca.cnf
