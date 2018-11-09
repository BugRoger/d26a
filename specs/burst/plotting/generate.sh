#!/bin/bash

cat plots_0.txt | while read line
do
  OUT=$(echo $line | cut -d " " -f 1 ) 
  CMD=$(echo $line | cut -d " " -f 2- )
  NAME=$(echo $line | cut -d "_" -f 2 )

  cat <<EOF > $OUT.yaml
apiVersion: batch/v1
kind: Job

metadata:
  name: plot-$NAME
spec:
  template:
    metadata:
      name: plot-$NAME
    spec:
      restartPolicy: Never
      containers:
        - name: plotter 
          image: bugroger/omdcct:v201707081812
          command: 
            - /bin/sh
            - -c 
          args:
            - $CMD
          volumeMounts:
            - name: burst-plots-0
              mountPath: /plots/0
              subPath: burst/plots
            - name: burst-plots-1
              mountPath: /plots/1
      volumes:
        - name: burst-plots-0
          persistentVolumeClaim:
            claimName: shared-media
        - name: burst-plots-1
          persistentVolumeClaim:
            claimName: burst-plots-1
EOF

done

