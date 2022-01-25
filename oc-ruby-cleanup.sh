#!/bin/bash

oc delete deployment.apps/ruby-hello-world service/ruby-hello-world imagestream.image.openshift.io/ruby-27 imagestream.image.openshift.io/ruby-hello-world buildconfig.build.openshift.io/ruby-hello-world build.build.openshift.io/ruby-hello-world-1
