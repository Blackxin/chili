ps -ef | awk '{if( == bash) print /bin/bash}'
awk 'BEGIN { for(i=1;i<100;i++) print "Raiz", i, "eh", i*i;}'
awk '$1 ~ /^[b,c]/ { print $0}' ~/.bashrc
awk '{print substr($0, 4)}' /var/cache/fetch/search/packages-split.csv 
df | awk 'NR==2, NR==5 {print NR, $0}'
df | awk 'NR==2, NR==5 {print $0}'
