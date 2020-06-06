#!/usr/bin/env bash
if ! minikube version > /dev/null 2>&1
then
  echo "ERROR: \"minikube\" required."
  exit 1
fi


if minikube status | grep Stopped > /dev/null 2>&1
then
  echo "Starting minikube..."
  minikube start > /dev/null 2>&1
fi

if ! kubectl version > /dev/null 2>&1
then
  echo "ERROR: \"kubectl\" required."
  exit 1
fi

if ! helm version > /dev/null 2>&1
then
  echo "ERROR: \"helm\" required."
  exit 1
fi

export FISSION_NAMESPACE=fission-local-suu

if ! kubectl get namespace | grep $FISSION_NAMESPACE > /dev/null 2>&1
then
  echo "No proper fission namespace... Installing Fission as ${FISSION_NAMESPACE}..."
  kubectl create namespace $FISSION_NAMESPACE > /dev/null 2>&1
  helm install --namespace $FISSION_NAMESPACE --name-template fission https://github.com/fission/fission/releases/download/1.9.0/fission-all-1.9.0.tgz > /dev/null 2>&1
fi

if ! fission > /dev/null 2>&1
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

  curl -Lo fission https://github.com/fission/fission/releases/download/1.9.0/fission-cli-${FISSION_OS_NAME} > /dev/null 2>&1 \
    && chmod +x fission && sudo mv fission /usr/local/bin/
fi

echo "Fission is ready to use"

# example fission run and answer
if ! fission env list | grep nodejs
then
  echo "FISSION: Creating nodejs env"
  if ! fission env create --name nodejs --image fission/node-env:1.9.0
  then
    echo
    echo "Error while creating environment"
    exit 1
  fi
fi

if ! fission function list | grep hello > /dev/null 2>&1
then
  echo "FISSION: Creating example function named\"hello\""
  curl -LO https://raw.githubusercontent.com/fission/fission/master/examples/nodejs/hello.js
  if ! fission function create --name hello --env nodejs --code hello.js
  then
    echo
    echo "Error while creating function"
    exit 1
  fi
fi

fission function test --name hello