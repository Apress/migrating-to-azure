FROM jenkins/jenkins:lts

USER root
ENV JENKINS_HOME /var/lib/jenkins
ENV COPY_REFERENCE_FILE_LOG=/var/lib/jenkins/copy_reference_file.log

RUN groupmod -g 800 jenkins
RUN usermod -u 800 jenkins

RUN mkdir "${JENKINS_HOME}"
RUN usermod -d "${JENKINS_HOME}" jenkins
RUN chown jenkins:jenkins "${JENKINS_HOME}"
VOLUME /var/lib/jenkins

USER jenkins