FROM jess/ab
LABEL tag="ab:latest"
RUN apk --update-cache add bash python libffi openssl gnuplot curl zip
VOLUME [ "/mnt/jmg" ]

WORKDIR /tmp/ab

COPY Urls.txt .
COPY exec.sh .
COPY plot.gp .

ENTRYPOINT [ "/bin/bash","/tmp/ab/exec.sh" ]