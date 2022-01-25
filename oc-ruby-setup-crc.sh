#!/bin/bash

oc new-project resource-demo
oc new-app --name=ruby-hello-world https://github.com/openshift/ruby-hello-world.git
sleep 5
oc expose service/ruby-hello-world

