require 'pry'

require 'time'
require 'date'
require 'yaml'
require 'json'
require 'ostruct'
require 'logger'
require 'fileutils'
require 'logger'
require 'thor'
require 'erb'
require 'aws-sdk-iam'
require 'aws-sdk-eks'
require 'kubeclient'
require 'rack'
require 'rack/server'
require 'prometheus/client'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

module Cloudsap
  DATETIME_FMT = '%Y-%m-%dT%H:%M:%S.%9N %z'
  PROGRAM_NAME = 'cloudsap'
  API_GROUP    = 'k8s.groundstate.io'
  API_VERSION  = 'v1alpha1'
end

require 'cloudsap/version'
require 'cloudsap/cli'
require 'cloudsap/common'
require 'cloudsap/abonas/kubeclient'
require 'cloudsap/kubernetes/sa'
require 'cloudsap/aws/iam'
require 'cloudsap/csa'
require 'cloudsap/metrics'
require 'cloudsap/watcher'

include Cloudsap
