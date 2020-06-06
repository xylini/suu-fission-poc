#!/usr/bin/env bash
minikube version > /dev/null 2>&1

if [ $? -ne 0 ]
then
  echo "ERROR: \"minikube\" required."
  exit 1
fi
minikube start

kubectl version > /dev/null 2>&1

if [ $? -ne 0 ]
then
  echo "ERROR: \"kubectl\" required."
  exit 1
fi

helm version > /dev/null 2>&1

if [ $? -ne 0 ]
then
  echo "ERROR: \"helm\" required."
  exit 1
fi

export FISSION_NAMESPACE=fission-local-suu

kubectl get namespace | grep $FISSION_NAMESPACE > /dev/null 2>&1

if [ $? -ne 0 ]
then
  echo "No proper fission namespace... Installing Fission as ${FISSION_NAMESPACE}..."
  kubectl create namespace $FISSION_NAMESPACE
  helm install --namespace $FISSION_NAMESPACE --name-template fission \
    https://github.com/fission/fission/releases/download/1.9.0/fission-all-1.9.0.tgz
fi

fission version > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "No fission CLI - installing..."
  case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
      export FISSION_OS_NAME=linux
      ;;
    darwin*)
      export FISSION_OS_NAME=osx
      ;;
  esac

  curl -Lo fission https://github.com/fission/fission/releases/download/1.9.0/fission-cli-${FISSION_OS_NAME} \
    && chmod +x fission && sudo mv fission /usr/local/bin/
fi

echo "Fission is ready to use"


# example fission run and answer
echo "CREATING AND RUNNING EXAMPLE FUNCTION"

fission env list | grep nodejs > /dev/null 2>&1
if [ $? -ne 0 ]
then
  fission env create --name nodejs --image fission/node-env:1.9.0
fi

fission function list | grep hello > /dev/null 2>&1
if [ $? -ne 0 ]
then
  curl -LO https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js
  fission function create --name hello --env nodejs --code hello.js
fi

fission function test --name hello