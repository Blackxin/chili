#!/usr/bin/env bash

echo ==========================================================================
var=5
python2 << EOF
print $var
EOF
echo ==========================================================================
python << EOF
print($var)
EOF
echo ==========================================================================
#normalmente
echo
echo 'echo "scale=3; sqrt(2)" | bc'
echo "scale=3; sqrt(2)" | bc
echo ==========================================================================
#preferivel
echo
echo 'bc <<< "scale=3; sqrt(2)"'
bc <<< "scale=3; sqrt(2)"
echo ==========================================================================
echo
echo 'echo AEIOU | tr A-Z a-z'
echo AEIOU | tr A-Z a-z
echo ==========================================================================
echo
echo 'tr A-Z a-z <<< AEIOU'
tr A-Z a-z <<< AEIOU
echo ==========================================================================
echo
echo 'echo a b c | read v1 v2 v3'
echo a b c | read v1 v2 v3
echo ==========================================================================
echo
echo 'read v1 v2 v3 <<< "a b c"'
read v1 v2 v3 <<< "a b c"
echo $v1 $v2 $v3
echo ==========================================================================
echo
echo 'echo a b c | read v1 v2 v3; echo $v1 - $v2 - $v3'
echo a b c | read v1 v2 v3; echo $v1 - $v2 - $v3
echo ==========================================================================
echo
#subshell
echo 'echo a b c | (read v1 v2 v3; echo $v1 - $v2 - $v3)'
echo a b c | (read v1 v2 v3; echo $v1 - $v2 - $v3)
echo ==========================================================================
echo
echo 'echo $BASHPID; echo a b c | read v1 v2 v3; echo $v1 - $v2 - $v3; echo $BASHPID'
echo $BASHPID; echo a b c | read v1 v2 v3; echo $v1 - $v2 - $v3; echo $BASHPID
echo ==========================================================================
echo
echo 'echo $BASHPID; echo a b c | (read v1 v2 v3; echo $v1 - $v2 - $v3; echo $BASHPID)'
echo $BASHPID; echo a b c | (read v1 v2 v3; echo $v1 - $v2 - $v3; echo $BASHPID)
echo ==========================================================================
#expansao de chaves e substituiçao de metacaracteres
touch arq arq1 arq11 arq13 arq3 arq5 arq7 arq9  # gerando exemplares
ls arq*
ls arq?
echo arq??
echo arq[1-7]
ls arq[1-13]
echo arq1*
ls arq{1..13..2} # listar 1 ate 13, de 2 em 2
echo {e..m}
echo {a..z}
mkdir {a..z} 2>&-   # 2>&- tranca saida de erro do mkdir, qdo ja existe o diretorio
echo ==========================================================================
#zeropad
echo
echo 'echo arq{01..15..2}'
echo arq{01..15..2}

echo 'echo arq{001..15..2}'
echo arq{001..15..2}

echo 'echo arq{0001..15..2}'
echo arq{0001..15..2}

echo 'echo pe{itu,la,ga}da'
echo pe{itu,la,ga}da

echo 'echo {z..a..2}'
echo {z..a..2}

echo 'echo {a..z..2}'
echo {a..z..2}

echo 'echo {1..1000..100}'
echo {1..1000..100}

echo
echo 'echo {0..1000..100}'
echo {0..1000..100}

echo
echo 'mkdir /tmp/{var,data,bin} 2>&-'
mkdir /tmp/{var,data,bin} 2>&-
echo ==========================================================================
echo 'Num=5'
echo 'echo a variavel $Num tem $Num'
Num=5
echo a variavel '$Num' tem $Num
echo ==========================================================================
echo '#subshell'
echo 'pwd ## onde estou'
pwd ## onde estou
echo '(cd /; ls; pwd); pwd'
(cd /; ls; pwd); pwd
echo 'Var=5; (echo 1:$Var; Var=3; echo 2:$Var); echo 3:$var'
Var=5; (echo 1:$Var; Var=3; echo 2:$Var); echo 3:$var
echo ==========================================================================
echo 'sed -r 's/(^[^ ]+).*/\1/' <<< "Vilmar Catafesta"'
sed -r 's/(^[^ ]+).*/\1/' <<< "Vilmar Catafesta"
