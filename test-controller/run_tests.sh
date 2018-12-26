#!/bin/sh

if [ ! $# -eq 2 ] ; then
  echo "ERROR: Improper argument usage.\n"
  echo "Usage:"
  echo "  ./run_tests.sh <GIT_REPO_URL> <PATH_TO_TESTS>"
  echo "EX:" 
  echo "  ./run_tests.sh https://github.com/quii/learn-go-with-tests.git http-server/v5/"
  echo
  exit 1
elif [ $1 = "-h" ] ; then
  echo "HELP"
  echo "Usage:"
  echo "  ./run_tests.sh <GIT_REPO_URL> <PATH_TO_TESTS>"
  echo "EX:" 
  echo "  ./run_tests.sh https://github.com/quii/learn-go-with-tests.git http-server/v5/"
  echo
  exit 1
fi

totaljobs=0

echo "Cloning remote repo $1 ..."
git clone $1
echo

reponame=$(echo $1 | rev | cut -f1 -d"/" | rev | cut -f1 -d".")
pathname=$reponame/$2
srccodepath=$(pwd)/$reponame

for test in $(bash -c "cd $pathname; go test -list '.*' | grep -v ok"); do 
  testtemplatename=$(echo "$test" | tr '[:upper:]' '[:lower:]')
  echo "Creating TestTemplate $testtemplatename."
  sed -e "s/{{test_template_name}}/$testtemplatename/" -e "s/{{test_name}}/$test/" -e "s:{{repo_name}}:$reponame:" -e "s:{{volume_path}}:$srccodepath:" -e "s:{{path_name}}:$pathname:" test-template.yaml | kubectl create -f -
  (( totaljobs++ ))
done;

testrunname=test-$(date +%Y%m%d%H%M%S)
echo "Creating TestRun ..."
sed -e "s/{{test_run_name}}/$testrunname/" test-run-template.yaml | kubectl create -f -

echo "\nWaiting for jobs to complete..."
sleep 2

while [ $totaljobs != 0 ] ; do
  for pod in $(kubectl get pods -l jobgroup=unittest | grep -v NAME | awk '{print$1}'); do
    if [ $(kubectl get pods $pod | grep -v NAME | awk '{print $3}') = "Completed" ] ; then 
      kubectl logs $pod
      sleep 1
      kubectl delete pod $pod
      (( totaljobs-- ))
      echo
    fi
  done;
done;

kubectl get events -l test-run=$testrunname

echo

#Cleanup
echo "Cleaning Up ..."
kubectl delete testrun --all
kubectl delete testtemplate --all
rm -Rf $reponame

echo "All unit tests complete."