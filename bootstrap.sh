#!/usr/bin/env bash

set -o errexit
set -o pipefail

export KUBERNETES_VERSION=${KUBERNETES_VERSION:-v1.1.1}

# The CIDR network to use for service cluster IPs. 
#
# Each service will be assigned a cluster IP out of this range.  This must not
# overlap with any IP ranges assigned to other existing network infrastructure.
# Routing to these IPs is handled by a proxy service local to each node, and
# are not required to be routable between nodes.
export SERVICE_CLUSTER_IP_RANGE=${SERVICE_CLUSTER_IP_RANGE:-10.0.0.0/16}

# The IP address of the cluster DNS service.  
#
# This IP must be in the range of the SERVICE_IP_RANGE and cannot be the first
# IP in the range.  This same IP must be configured on all worker nodes to
# enable DNS service discovery.
export CLUSTER_DNS=${CLUSTER_DNS:=10.0.254.254}

export CA_CERT=$(cat <<EOF
-----BEGIN CERTIFICATE-----
MIID0jCCArygAwIBAgIIZvC1rVR9LygwCwYJKoZIhvcNAQELMHcxCzAJBgNVBAYT
AkRFMQ8wDQYDVQQKEwZTQVAgU0UxNTAzBgNVBAsTLE1vbnNvb24gS3ViZXJuZXRl
cyBDQSBSb290IENlcnRpZmljYXRlOiBkMjZhMQ8wDQYDVQQHEwZCZXJsaW4xDzAN
BgNVBAgTBkJlcmxpbjAeFw0xNTExMTQyMjM3MDBaFw0yMDExMTIyMjM3MDBaMHcx
CzAJBgNVBAYTAkRFMQ8wDQYDVQQKEwZTQVAgU0UxNTAzBgNVBAsTLE1vbnNvb24g
S3ViZXJuZXRlcyBDQSBSb290IENlcnRpZmljYXRlOiBkMjZhMQ8wDQYDVQQHEwZC
ZXJsaW4xDzANBgNVBAgTBkJlcmxpbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
AQoCggEBAMJKunUtQghMWqvMc4TGEr6+WgKTfbhl8+BconWfHUVlo0dA0xOeQrZy
LV1QoKXZmDR49w96V9gqfXlZwKIw9chvftZK99622o7sC8Vno1F2sTLn4sPDuK0n
CQsoh2p1pt2tGdbXJ9Z9RabAkie6tamK2ovf2Sd7ZcyCV2qab3FJWm+0z2RuffkZ
pUQGXIPTKiCDDWmVvdkdQFXfQ7ypOV2+9fy2KU2ylyBR0cdYjqM2csqLntlYiDQJ
jLTm4v3zFLhenLbQfbukqSjI/HTGKt+HTor83RInWxviRhO1SG3slgcDbl/r0MvY
6dorYzlqrrSzAY0omFMU+nbdakSo6mUCAwEAAaNmMGQwDgYDVR0PAQH/BAQDAgAG
MBIGA1UdEwEB/wQIMAYBAf8CAQIwHQYDVR0OBBYEFPVs5aLML6ObNPTQaGK874Oy
y6uIMB8GA1UdIwQYMBaAFPVs5aLML6ObNPTQaGK874Oyy6uIMAsGCSqGSIb3DQEB
CwOCAQEAdR7fZLDd04qZ7qX/3JiKnz6C+KHlKyFDOH2AVlo7mn9smzJMZixRP2uH
J3QPtqPMPOhsv7bRccmkO/Y0B1E76DIAJKIiiGaYwlarEGQ7IHG2Jd2tv021/+D8
DmIEAGAOTC6qjwuJdBEkZwridqMyC0TuAD+9+Qiu8RkJdXNSjPxVpp6tmm8vZwRr
65jr8ni16oyCGIE59ZKDK3VH9KZMrF0pvkwgSQ4CZ88cj2WrdvzE77HRxPrWnKba
wSTkhwnL/6fip29VX6Jk4qJXzV7bg3FSKho5gp5bGPKA3ItMJjenuZAUeZfUA+vf
6oRrwZd3t7f9kTNdRYx31w9WGZpfEA==
-----END CERTIFICATE-----
EOF
)

export CA_KEY=$(cat <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAzJnK6i8nqlyKxDBF/2/jL1XsL72Jzrq4aADwBxuKf0tWaOnT
9H+4CalIuNvq41uT8Hq4fuNNFhGCb2+WsI+MgwtR3H5pFExtUsm6seIU3EPweiF2
n0n8C92EaIPICZ5pWfFww+9Lw69FNThMTRHFbEkwvl468ZMdkOD1oTOTWq91aCje
zly4m+fN2WfcNCzDABua/ZpE931J9i7eS6fLqb//rDkGF0cgfOSOW8qFKPdyXV7W
ZGyN4mLnr3tfBOsF+s9QjEnRpmTG8qS9nPTrnjHJvbMLvWo0KPiPqOALz2rDDsC0
d0uWSa8DPujXDGnJ0V3cR8l9oMtM6A+VhpJk4QIDAQABAoIBAEKnH2mnLv7a4wIC
z+rlIle7YBQ1ZP2J6qVHGOrX2AicHGxVMI2IRgYvtdczHZQvs0Q2VoBPwD8eOSXg
bnDacuYF/Acez1CjjUHZIg7tHeqb322KFUDTM18SLR53P+WSS7PXaesKu93l7V/n
FUROM8iRF2YNAJrOWGVoQ9zeFnUF+rADxKGymMx6bJz6XqKqRU3AVSW6EyCqH9Pl
7rGn9UYL5bou1MV8HJn8DVoHYqXvi6hDszNtIvz0ilWif0V0ZV7O6+3Tu0G7yggm
JKbV7Xy5ZEuo3DwNLgKfWcoHKdX7RYDCapM9lvEy+dpUrqkEKRkTtHr2R5/F3yt2
u26zkAECgYEA71FYPcGbGstLSB8tSFav4GCBfuJHAK/SFfAQbFCHIUTTJ0rAL9g9
GByE3jq7Md8cyy12m5GaOpZnhD7d7NC7NLkGpkY08ayf7ex8sZjuFipbuJdRgeBK
x94ZinBLIF+seCHge+P3Z0eyV1xMk7pdTqTzGm09y0/K7s/hfcK7GCECgYEA2tzr
MU208sqmPuTbEJpzB4GhOLES18GAp5C7x3qm8xTWcw8W9Tnrq+ErWEjoa2v6JTYB
j3bA4tLVlBiFmQ3YQH3aeXBdVVKI+CcIW6t0+dMB3lhR87TE8OMiyVjlpGoL5viU
ZnStxoMOHf8R2u8FMIFG7z4Cx82Q8HXHtMDOtMECgYEAw+sAJm6dH+5WDxEW7SWq
jjHzUYDFR9aoUrVZfJLgTWgexQf5FjIcseSHEbdbEJTq6ZqqgulMLbJ7xFQDMqAe
4ianPvAy37bGpuz3mBzurM64kAGxBHYuQjmdByyvFC2+8Aor0MDsBW04nzQ8rKPh
R0TakEPmVs9X/vHIVEBbEoECgYA+5LdNjsgN8UA+2KM/LTMbGBxNX01L5RZkkMn1
dACf4AAURmTRiZh45xb+oszvebMDmHZwVK7vP6kSis1xgzH+rmvm8+xORY6IySa0
uRu/YuypiXXbc7oYgx0PAVXUnojXEd4LZ0I8xpJ6+j6WTJOQMcZBn+9KnX8mKqJ+
Bd4gwQKBgQDUUgJZtN74XN9cgWmB1xWx0Xwpz+mw4hi3mVsoYg1SDLZaOVcz5SY/
CAGsd5tD21x8FH24wWR6/z4q/0wpaLrJ/1CZt2Nzfz1D7mfY1tZgEGwgLgRsPIG4
o5PeMcKC5xTZ2X1VbezqTvhzirzzS86qwvIOfE64lutWvmx/OpyHmg==
-----END RSA PRIVATE KEY-----
EOF
)

export SERVER_CERT=$(cat <<EOF
-----BEGIN CERTIFICATE-----
MIIE0jCCA7ygAwIBAgIIXapfxmxL0CkwCwYJKoZIhvcNAQELMIGHMQswCQYDVQQG
EwJERTEPMA0GA1UEChMGU0FQIFNFMUUwQwYDVQQLEzxNb25zb29uIEt1YmVybmV0
ZXMgQ0EgUm9vdCBDZXJ0aWZpY2F0ZToga3ViZXJuZXRlcy5sb2NhbGhvc3QxDzAN
BgNVBAcTBkJlcmxpbjEPMA0GA1UECBMGQmVybGluMB4XDTE1MTEwNjE0MzcwMFoX
DTE5MTEwNTE0MzcwMFowgbExCzAJBgNVBAYTAkRFMQ8wDQYDVQQKEwZTQVAgU0Ux
JjAkBgNVBAsTHU1vbnNvb24gS3ViZXJuZXRlcyBPcGVyYXRpb25zMQ8wDQYDVQQH
EwZCZXJsaW4xDzANBgNVBAgTBkJlcmxpbjFHMEUGA1UEAww+TW9uc29vbiBLdWJl
cm5ldGVzIFNlcnZlciBDZXJ0aWZpY2F0ZTogMTkyLjE2OC4xLjEwMEBsb2NhbGhv
c3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDBEB65Mvw5GB1GLKTG
K3UvkwKkq4thvFDnHMJ3BLXsSCw1gBgIfV2czLH0YUN/QGF2N2lDgq3AUmgLt4Q7
3lY0XvxfNMtq2wPVLIElputhFIM79JFycv796tJfyV8bZdNkn7pcKI4FIEknr/j1
WSFh9lWnBK3xe30YapNz65CFe+FS+q+5XUmlxRlqq6WlSoZH6dEJO7Rl2LkLHreU
lsOZUHnRL5lb9ywcJGUbxhd8OI5Ig2LYEY+DpyCYXltrZfT6cqmVjb+N5c0Nlls5
26RB+q7SliITMzuT74fPs2sPzBTW1S5fb1OUwiZ4WC9zYExXZv8PJ5QrTtAh/czo
ATbnAgMBAAGjggEYMIIBFDAOBgNVHQ8BAf8EBAMCAKAwEwYDVR0lBAwwCgYIKwYB
BQUHAwEwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUJg/FguYcQ1wI0t6hknLl9Hy5
AmIwHwYDVR0jBBgwFoAUk2nfSoc1Ud9qz4duUySf7zDu234wgZ4GA1UdEQSBljCB
k4IJbG9jYWxob3N0gglsb2NhbGhvc3SCCyoubG9jYWxob3N0ggprdWJlcm5ldGVz
ghJrdWJlcm5ldGVzLmRlZmF1bHSCFmt1YmVybmV0ZXMuZGVmYXVsdC5zdmOCJGt1
YmVybmV0ZXMuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbIcEwKgBZIcErBAAAYcE
fwAAATALBgkqhkiG9w0BAQsDggEBALRd33GQU4QxMD6aZ/7n1xueNZD6Cu1c5BoC
nJx5B6KnZ930u4bR9lwUh3CB03VR6ZRtJ4BM3AzHJLYKb8yFut+NGqVDYarXIIfv
YM7ctrWesFmoe/69yhWY1dvGmhnee1Z+qLvna/uJlrldottW7Yg7vAXji48uL3RQ
S8L+lSRNMasUGJAW06TlcBqfpzDdA3Q36gKJx97Wx0arH7y0Y+p0gxfZ0TyN/Hw/
XkExqfrbmZiv6100RiYwOqIDJvzppBvxl1X6D6NsWN1a/n1N9QFS9FOhaRmtk5cK
QEdNATWVRuMlU2II1qhkFO+O+w76Lw3h7gdhLobvPDJs+GeXAaw=
-----END CERTIFICATE-----
EOF
)

export SERVER_KEY=$(cat <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAwRAeuTL8ORgdRiykxit1L5MCpKuLYbxQ5xzCdwS17EgsNYAY
CH1dnMyx9GFDf0BhdjdpQ4KtwFJoC7eEO95WNF78XzTLatsD1SyBJabrYRSDO/SR
cnL+/erSX8lfG2XTZJ+6XCiOBSBJJ6/49VkhYfZVpwSt8Xt9GGqTc+uQhXvhUvqv
uV1JpcUZaqulpUqGR+nRCTu0Zdi5Cx63lJbDmVB50S+ZW/csHCRlG8YXfDiOSINi
2BGPg6cgmF5ba2X0+nKplY2/jeXNDZZbOdukQfqu0pYiEzM7k++Hz7NrD8wU1tUu
X29TlMImeFgvc2BMV2b/DyeUK07QIf3M6AE25wIDAQABAoIBAAGHZibjT3oIRdsT
aW6kU3Y//MpfDWiFvEJISQX2RJaNb8QwsoAGtiISwOoFhypP0TXFdJDzTPrz7B0D
pAlxVk9t3SPH4ECFYX9jrdYlf0GyjuN/qVM1s+1A2c+mYZlu8gCe/zPRomZJ/ipR
S3Bt90S2VbFP6Sy7ZJ834NkPKYLVF8jIY2aSrAScjDocfYTOc63KiZc5fqzzYGPs
srqU7HncQRbyhRPcD14wHF0WK+LRtWtv3dwpFJRhHdcpwmyyfa+OWlG+6bCgd61y
Wwrr62WzdxKy54YEU3N3MO7ei8Xc5yuWJ532W5O//BXCIMKWLAYbPbr9TEZ6H2EI
gxCizPECgYEAzlGTfstCjlN8T892C2oLR5gjpFaioExnhFqi1Rs5oP836QnZojPd
jDjEEZr/T9pqZBO6c6YX6HqhGcLdp64+sLoUEnUwBV+2Y/e1r1EQL/JN31BCoK0i
kZCkCucjku6+7+Em2Sxtbj+GvF5q1sgBe2pjzhc1m2BME/yipy6WSZ8CgYEA741n
GcQkTiwGRw/B3qXODL9znMjAlpewquwf0RJx0s0IzlYUWZ7oL8v1BHwSwTlvV4OQ
joDs9L4yzfi4pLdGpWZUyWPT5NPXdfPTmwB9XNJ0sNioPGGzNTbFICV9Ruj64KYb
PfVc4dO4yHCim+SfIa67QaAhr+buFtQFw/yRHbkCgYEArMtVpJPHojv5mT4/tz+R
Qt0AvNpySZ6z8/2U8rZihZw6z0oYo+icXJwOWlBeFBrxj++V8NXioCpUUqcJzS36
AzlVJkBPf7CxqPgFildyHzXoUmd95eQbV560RQ1gleaus2j2iFzVKci6p3jMMiZA
V4S7Ihf+Jat5DCRCdZJm/DECgYA4axosJFjUnGPCGsDzOiOkNvb4pwNMtF8kckYw
DGMIXcfEKNvUG6vdjfCf5MTaAzfo6ZCDL3QfVChNAFYkXRHjZI11fPBrxUTKf+mH
aP8dfGeFOxGsXupBDywwHQQ7TiXAAP8LgZ0lhqLPek+h3Z9o5Gkv1JH6hq3ubHML
LJHU6QKBgDhnsbHxaSQIG2p/L2T/F7N0MoJ3GOp4h6KdGl32FSif4od+rsU7dnVj
Vcw5t3BgqGkz3ZSFebS20Auv/GJD7W6bcG/ZL4QcDBPEom4/KZW1rHqDec6Wa1dR
Lk3vGoKDPdWYSZD6QBjglaSMfK7IglwUnWfC2TXSotFulXsAEKF1
-----END RSA PRIVATE KEY-----
EOF
)

export CLIENT_CERT=$(cat <<EOF
-----BEGIN CERTIFICATE-----
MIIE0jCCA7ygAwIBAgIIdPW6/hwGKFIwCwYJKoZIhvcNAQELMIGHMQswCQYDVQQG
EwJERTEPMA0GA1UEChMGU0FQIFNFMUUwQwYDVQQLEzxNb25zb29uIEt1YmVybmV0
ZXMgQ0EgUm9vdCBDZXJ0aWZpY2F0ZToga3ViZXJuZXRlcy5sb2NhbGhvc3QxDzAN
BgNVBAcTBkJlcmxpbjEPMA0GA1UECBMGQmVybGluMB4XDTE1MTEwNjE0MzcwMFoX
DTE5MTEwNTE0MzcwMFowgbExCzAJBgNVBAYTAkRFMQ8wDQYDVQQKEwZTQVAgU0Ux
JjAkBgNVBAsTHU1vbnNvb24gS3ViZXJuZXRlcyBPcGVyYXRpb25zMQ8wDQYDVQQH
EwZCZXJsaW4xDzANBgNVBAgTBkJlcmxpbjFHMEUGA1UEAww+TW9uc29vbiBLdWJl
cm5ldGVzIENsaWVudCBDZXJ0aWZpY2F0ZTogMTkyLjE2OC4xLjEwMEBsb2NhbGhv
c3QwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDEDZd4X1pFNBCg4GNJ
VHu9aKp4QRMfn8H7alIcXd1APzmC6OJwjFjeE4Rcwj6EIKFfUPrPBF+sNMviTFmr
I19JWvOFT59n3TYWRATs1y1v+/PMrQ4DqTCNRTas+PaKag66sGRD0Z72tD4JWnbz
mLksBdsXASQ5yd+VMgo0E9m9/eZPmyWNPC1SkIqDMkYdTmaTan2tnr0paodUX7VB
qwgKaaHFZldTk7pAVFUfTasPJJGZ0f9/8nCqksFsaFUq8hS5SBRjdVYwX8yGWN5s
cu3b1a2OhgW5YkMk4s/hiXhDEcU1TuG0G0xTZaDEm0Q9mYBwCSB5a1X1IVKfE8uY
pvO7AgMBAAGjggEYMIIBFDAOBgNVHQ8BAf8EBAMCAIAwEwYDVR0lBAwwCgYIKwYB
BQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUkGCm16W3afE8uGepqUxlgAmX
w5YwHwYDVR0jBBgwFoAUk2nfSoc1Ud9qz4duUySf7zDu234wgZ4GA1UdEQSBljCB
k4IJbG9jYWxob3N0gglsb2NhbGhvc3SCCyoubG9jYWxob3N0ggprdWJlcm5ldGVz
ghJrdWJlcm5ldGVzLmRlZmF1bHSCFmt1YmVybmV0ZXMuZGVmYXVsdC5zdmOCJGt1
YmVybmV0ZXMuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbIcEwKgBZIcErBAAAYcE
fwAAATALBgkqhkiG9w0BAQsDggEBAEYkHFTDd2o58d1ne/dxCv6Rht0C07SY7uVR
QdzAhCYfBLoA7+xYBXxTVpAJN3Um5oyExt+zz7LUYo5FJeAv+7GaVlVwzjzzxhj+
z8EzN2/Vs4YPPJpzQtWTObIw/DDYTikdzEuRDOr8WBc1P9Zzs5EHgdCCqMigz7ur
ewqfiwIPrw7Hp5IAdNUKKhGjvFG5MNtmocjUkS+LA6z3lAY/yqytH9i7OvkEXUdd
yfwsAMiqkw9DNTMFMiHMsZOMD8CVQZ5Zccr6v0mnLliVzz47fTY24S14y/ymE3JQ
L74whXBJI3sdSFm59lmKxa25yM8ENLZwuSJyvFX3wnUWXAurA68=
-----END CERTIFICATE-----
EOF
)

export CLIENT_KEY=$(cat <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAxA2XeF9aRTQQoOBjSVR7vWiqeEETH5/B+2pSHF3dQD85guji
cIxY3hOEXMI+hCChX1D6zwRfrDTL4kxZqyNfSVrzhU+fZ902FkQE7Nctb/vzzK0O
A6kwjUU2rPj2imoOurBkQ9Ge9rQ+CVp285i5LAXbFwEkOcnflTIKNBPZvf3mT5sl
jTwtUpCKgzJGHU5mk2p9rZ69KWqHVF+1QasICmmhxWZXU5O6QFRVH02rDySRmdH/
f/JwqpLBbGhVKvIUuUgUY3VWMF/MhljebHLt29WtjoYFuWJDJOLP4Yl4QxHFNU7h
tBtMU2WgxJtEPZmAcAkgeWtV9SFSnxPLmKbzuwIDAQABAoIBAQCOd3ICvwfSEiuj
PGvp9cKVuWFnUaKb8HP+Rxy0EGGfNlKMlr82GkbZ2kTtQxo62ZtqsGYR2ZPMh/FA
2Uqv2lx76ePclCe6Sj3roDIUCamzHtvjeD4e2uu1PP6mY6SEoN1jPJsfzUw+6mvK
UDrweaLWIss6xFGWzOP0fxB7F5G7RWg5ITZPtm0hlQa+mdF51vsEJLRhKyiKzWPS
LkJfSikWVYVLtfAPXVYqvU9OuxWahBcSa7vxUbPDW8NlhjMqFMnVHXq0SamNQ39W
oTWcWGyh55lvUQvxanjehmOjnTw7xtNVXdq35SKAzaZSeZcpRVtyFbDP09l0coCo
q5NTeDxBAoGBANjFo0jCdcioeWrdsiS7YljIFTA2hfDGeP7yv/7dN4elrqAG0QfY
nnheS7GMWkSAI4xhKoMsxEBdKoYJ+IQb53gIxXaAfaVkNYBI2Wo9GcdgttqRe/u9
rfDnwAOer0kTYT3+tljc/MaRMfbkvoeJEjDT19jYHWwcekUorP47l2ttAoGBAOeI
HIElh6sEpOeM5kNr8IAJsJillg73iCN0Ubj8W7fzjX1UeeWewD9NZRXmEFGV9iHI
nW5+Xl5J+Cvldb9W/JJmw0uGfIpFqoJ0zCY7kmH8PLyW5Hq5qNO3kipXk0W29lPj
NKMKo2P4CpmTUQKHDK68p3AcGO0c676puZsC8vrHAoGBANiVX3erE5PRAL9Nklgx
ASpDfygU0e6n3uycDkjPLlRRrhAlv2RfgrYxQN+8o9QdU2dHDfrSF6NXcs1J2Qvl
9XdxDBpCd0dwwCPUpaYINmGGuCvZgE8eTVSNuMPlIK2at2YBwJ847TZYi9tq4RL6
WTp/7wGxrHQAYAoJgg7h64BhAoGAL6IeEyfQeIu1DXo8aUSMrxrPPShb7epZFMo6
ge9RQ1AVHOLDTU1SyfM3R8EUPGS4xYyLbw8KhSV8rDNB/UJ9JfWEWkZp2tyoTryO
v5Lj88q8CCSXDvShWiVbKeDoiKAyn2GQE7b9lHSUYbIgKX/1SQHBBNyS+D1J9uje
KZj6ukMCgYALDsW48FYZhOAnwSMUB3sSWzuWhTSA6GzNM9TVjB12dL76WZdF20Zk
UbX+k22SqVNOZq03iIriTM6AS0leBT9NHifDoCQDJEAtyytPwhNQ7zKsJIWPkh6I
N2k1tURHADc6CSLYDWQYTNtfKiPn3ZPx0iJDCEmjsKh2hRhQnJuYkQ==
-----END RSA PRIVATE KEY-----
EOF
)

function verify {
    local REQUIRED=( 'ADVERTISE_IP'  'SERVICE_CLUSTER_IP_RANGE' 'CLUSTER_DNS' 'KUBERNETES_VERSION' )

    if [ -z $ADVERTISE_IP ]; then
        export ADVERTISE_IP=$(awk -F= '/COREOS_PUBLIC_IPV4/ {print $2}' /etc/environment)
    fi

    for REQ in "${REQUIRED[@]}"; do
        if [ -z "$(eval echo \$$REQ)" ]; then
            echo "Missing required config value: ${REQ}"
            exit 1
        fi
    done
}

function wait_for_cloudinit {
  echo "Waiting for CloudInit..."
  until systemctl -q is-active 'user-cloudinit@var-lib-coreos\x2dvagrant-vagrantfile\x2duser\x2ddata.service'
  do
      sleep 1
  done
}

function wait_for_kubernetes_api {
    echo "Waiting for Kubernetes API..."
    until curl --silent "http://127.0.0.1:8080/version" &> /dev/null
    do
        sleep 1
    done
    echo "Cluster Online. Ready for your orders, sir!"
}

function download_kubernetes {
    mkdir -p /opt/bin
    source /etc/environment
    export https_proxy

    if ! kubelet --version=true 2> /dev/null | grep -q ${KUBERNETES_VERSION}
    then
      echo "Downloading Kubelet ${KUBERNETES_VERSION}..."
      systemctl stop kubelet &> /dev/null || true
      wget -N -q -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubelet
      chmod +x /opt/bin/kubelet
    fi

    if ! kubectl version -c 2> /dev/null | grep -q ${KUBERNETES_VERSION}
    then
      echo "Downloading Kubectl ${KUBERNETES_VERSION}..."
      wget -N -q -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
      chmod +x /opt/bin/kubectl
    fi
}

function generate_certificates {
  mkdir -p /etc/kubernetes/ssl
  echo "$CA_CERT"     > /etc/kubernetes/ssl/ca.pem
  echo "$CA_KEY"      > /etc/kubernetes/ssl/ca-key.pem
  echo "$SERVER_CERT" > /etc/kubernetes/ssl/server.pem
  echo "$SERVER_KEY"  > /etc/kubernetes/ssl/server-key.pem
  echo "$CLIENT_CERT" > /etc/kubernetes/ssl/client.pem
  echo "$CLIENT_KEY"  > /etc/kubernetes/ssl/client-key.pem
}

function setup_kubernetes {
    local TEMPLATE=/etc/kubernetes/kubeconfig
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
apiVersion: v1
kind: Config
clusters:
  - name: local
    cluster:
       certificate-authority: /etc/kubernetes/ssl/ca.pem
       server: "https://127.0.0.1:6443"
contexts:
  - name: local 
    context:
      cluster: local
      user: local 
current-context: local
users:
  - name: local
    user:
      client-certificate: /etc/kubernetes/ssl/client.pem
      client-key: /etc/kubernetes/ssl/client-key.pem
EOF
    }

    local TEMPLATE=/etc/systemd/system/kubelet.service
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
[Service]
ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
ExecStart=/opt/bin/kubelet \
  --api_servers=http://127.0.0.1:8080 \
  --register-node=true \
  --allow-privileged=true \
  --hostname-override=${ADVERTISE_IP} \
  --config=/etc/kubernetes/manifests \
  --cluster_dns=${CLUSTER_DNS} \
  --cluster_domain=cluster.local \
  --cadvisor-port=0
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    }

    local TEMPLATE=/run/systemd/system/etcd2.service.d/20-cluster.conf
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
[Service]
Environment=ETCD_INITIAL_CLUSTER=$(ETCD= ;for i in $(seq 1 $NODE_COUNT); do ETCD="$ETCD,node$(expr $i - 1)=http://192.168.1.$(expr 99 + $i):2380"; done; echo $ETCD | cut -c 2-)
Environment=ETCD_NAME=%H
Environment=ETCD_ADVERTISE_CLIENT_URLS=http://${ADVERTISE_IP}:2379
Environment=ETCD_INITIAL_ADVERTISE_PEER_URLS=http://${ADVERTISE_IP}:2380
Environment=ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379,http://0.0.0.0:4001
Environment=ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
EOF
        systemctl daemon-reload
        systemctl enable kubelet
        systemctl enable etcd2 
        systemctl start kubelet
        systemctl start etcd2
    }

    local TEMPLATE=/etc/kubernetes/templates/kube-system.manifest
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
EOF
    }

    local TEMPLATE=/etc/kubernetes/templates/kube-scheduler.manifest
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
apiVersion: v1
kind: Pod
metadata:
  name: kube-scheduler
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
    - name: kube-scheduler
      image: gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION}
      args: 
        - /hyperkube
        - scheduler
        - --kubeconfig=/etc/kubernetes/kubeconfig
        - --v=2
      livenessProbe:
        httpGet:
          path: /healthz
          port: 10251
        initialDelaySeconds: 15
        timeoutSeconds: 1
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: etc-kubernetes
          readOnly: true
  volumes:
    - name: etc-kubernetes
      hostPath:
        path: /etc/kubernetes
EOF
    }

    local TEMPLATE=/etc/kubernetes/templates/kube-controller-manager.manifest
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
apiVersion: v1
kind: Pod
metadata:
  name: kube-controller-manager
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
    - name: kube-scheduler
      image: gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION}
      args:
        - /hyperkube
        - controller-manager
        - --kubeconfig=/etc/kubernetes/kubeconfig
        - --service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem
        - --root-ca-file=/etc/kubernetes/ssl/ca.pem
        - --v=2
      livenessProbe:
        httpGet:
          path: /healthz
          port: 10252
        initialDelaySeconds: 15
        timeoutSeconds: 1
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: etc-kubernetes
          readOnly: true
        - mountPath: /etc/ssl/certs
          name: etc-ssl-certs 
          readOnly: true
  volumes:
    - name: etc-kubernetes
      hostPath:
        path: /etc/kubernetes
    - name: etc-ssl-certs 
      hostPath:
        path: /etc/ssl/certs/
EOF
    }

    local TEMPLATE=/etc/kubernetes/manifests/kubernetes.manifest
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        cat << EOF > $TEMPLATE
apiVersion: v1
kind: Pod
metadata: 
  name: kubernetes
  namespace: kube-system
spec: 
  hostNetwork: true
  containers: 
    - name: kube-apiserver
      image: gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION}
      args: 
        - /hyperkube
        - apiserver
        - --allow-privileged=true
        - --etcd-servers=http://127.0.0.1:2379
        - --bind-address=0.0.0.0
        - --insecure-bind-address=0.0.0.0
        - --secure_port=6443
        - --service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE}
        - --advertise-address=${ADVERTISE_IP}
        - --kubelet-https=true
        - --kubelet-certificate-authority=/etc/kubernetes/ssl/ca.pem
        - --kubelet-client-certificate=/etc/kubernetes/ssl/client.pem
        - --kubelet-client-key=/etc/kubernetes/ssl/client-key.pem
        - --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota
        - --tls-cert-file=/etc/kubernetes/ssl/server.pem
        - --tls-private-key-file=/etc/kubernetes/ssl/server-key.pem
        - --client-ca-file=/etc/kubernetes/ssl/ca.pem
        - --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem
        - --v=2
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: etc-kubernetes
          readOnly: true
        - mountPath: /etc/ssl/certs
          name: etc-ssl-certs 
          readOnly: true
    - name: "kube-proxy"
      image: "gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION}"
      args:
        - "/hyperkube"
        - "proxy"
        - "--master=http://127.0.0.1:8080"
        - "--v=2"
      securityContext:
        privileged: true
    - name: scheduler-elector
      image: gcr.io/google_containers/podmaster:1.1
      command:
        - /podmaster
        - --etcd-servers=http://127.0.0.1:2379
        - --key=scheduler
        - --source-file=/etc/kubernetes/templates/kube-scheduler.manifest
        - --dest-file=/etc/kubernetes/manifests/kube-scheduler.manifest
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: etc-kubernetes
    - name: controller-manager-elector
      image: gcr.io/google_containers/podmaster:1.1
      command:
        - /podmaster
        - --etcd-servers=http://127.0.0.1:2379
        - --key=controller
        - --source-file=/etc/kubernetes/templates/kube-controller-manager.manifest
        - --dest-file=/etc/kubernetes/manifests/kube-controller-manager.manifest
      terminationMessagePath: /dev/termination-log
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: etc-kubernetes
  volumes:
    - name: etc-kubernetes
      hostPath:
        path: /etc/kubernetes
    - name: etc-ssl-certs 
      hostPath:
        path: /etc/ssl/certs/
EOF
    }
}

function install_cluster_addons {
  # TODO: Use CURL to push this in. Remove kubectl from downloads
  echo "Installing cluster addons..."
  if ! kubectl get namespace kube-system &> /dev/null 
  then
    kubectl create -f /etc/kubernetes/templates/kube-system.manifest -- &> /dev/null || true
  fi
}


wait_for_cloudinit
verify
download_kubernetes
generate_certificates
setup_kubernetes
# wait_for_kubernetes_api
install_cluster_addons

