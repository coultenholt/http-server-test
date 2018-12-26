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
  jobname=$(echo "$test" | tr '[:upper:]' '[:lower:]')
  echo "Creating job $jobname."
  sed -e "s/{{job_name}}/$jobname/" -e "s/{{test_name}}/$test/" -e "s:{{repo_name}}:$reponame:" -e "s:{{volume_path}}:$srccodepath:" -e "s:{{path_name}}:$pathname:" job-template.yaml | kubectl create -f -
  (( totaljobs++ ))
done;

echo "\nWaiting for jobs to complete..."

while [ $totaljobs != 0 ] ; do
  for pod in $(kubectl get pods -l jobgroup=unittest | grep -v NAME | awk '{print$1}'); do
    if [ $(kubectl get pods $pod | grep -v NAME | awk '{print $3}') = "Completed" ] ; then 
      kubectl logs $pod
      jobname="unittest-"$(echo $pod | cut -f2 -d"-")
      kubectl delete job $jobname
      (( totaljobs-- ))
      echo
    fi
  done;
done;

rm -Rf $reponame

echo "All unit tests complete."

