## Distributed CI Testing
I have written and setup a distributed CI testing environment to run with any GO Lang Project. This can be modified to run with other languages as well.
The below script is dynamic enough that whenever you make a code change or add a new test case, none of this code will need to be changed, it will simply pull in the changes as they are committed on runtime.

### Dockerfile
Per request I have created a basic Dockerfile, which pulls in the latest GOLang image and runs all the test cases.
Link: https://cloud.docker.com/repository/docker/coultenholt/learn-go-with-tests
Example Run:
```bash
$ docker run -it --rm coultenholt/learn-go-with-tests
=== RUN   TestRecordingWinsAndRetrievingThem
--- PASS: TestRecordingWinsAndRetrievingThem (0.00s)
=== RUN   TestGETPlayers
=== RUN   TestGETPlayers/returns_Pepper's_score
=== RUN   TestGETPlayers/returns_Floyd's_score
=== RUN   TestGETPlayers/returns_404_on_missing_players
--- PASS: TestGETPlayers (0.00s)
    --- PASS: TestGETPlayers/returns_Pepper's_score (0.00s)
    --- PASS: TestGETPlayers/returns_Floyd's_score (0.00s)
    --- PASS: TestGETPlayers/returns_404_on_missing_players (0.00s)
=== RUN   TestStoreWins
=== RUN   TestStoreWins/it_records_wins_on_POST
--- PASS: TestStoreWins (0.00s)
    --- PASS: TestStoreWins/it_records_wins_on_POST (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.011s
```

### Running Parallel via Kubernetes
I have set this up to take advantage of Kubernetes `jobs`. I have written `run_tests.sh` which will interrogate the code passed to it, find the test cases, then spawn off multiple `jobs` that spawn `pods` which will run each test case parallel. Aggregating the output to std.out. You can run on a local cluster. Like below. 
```bash
$ ./run_tests.sh https://github.com/quii/learn-go-with-tests.git http-server/v5/
Cloning remote repo https://github.com/quii/learn-go-with-tests.git ...
Cloning into 'learn-go-with-tests'...
remote: Enumerating objects: 119, done.
remote: Counting objects: 100% (119/119), done.
remote: Compressing objects: 100% (79/79), done.
remote: Total 3601 (delta 42), reused 101 (delta 36), pack-reused 3482
Receiving objects: 100% (3601/3601), 3.84 MiB | 5.35 MiB/s, done.
Resolving deltas: 100% (1984/1984), done.

Creating job testrecordingwinsandretrievingthem.
job.batch/unittest-testrecordingwinsandretrievingthem created
Creating job testgetplayers.
job.batch/unittest-testgetplayers created
Creating job teststorewins.
job.batch/unittest-teststorewins created

Waiting for jobs to complete...
=== RUN   TestRecordingWinsAndRetrievingThem
--- PASS: TestRecordingWinsAndRetrievingThem (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.038s
job.batch "unittest-testrecordingwinsandretrievingthem" deleted

=== RUN   TestGETPlayers
=== RUN   TestGETPlayers/returns_Pepper's_score
=== RUN   TestGETPlayers/returns_Floyd's_score
=== RUN   TestGETPlayers/returns_404_on_missing_players
--- PASS: TestGETPlayers (0.00s)
    --- PASS: TestGETPlayers/returns_Pepper's_score (0.00s)
    --- PASS: TestGETPlayers/returns_Floyd's_score (0.00s)
    --- PASS: TestGETPlayers/returns_404_on_missing_players (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.028s
job.batch "unittest-testgetplayers" deleted

=== RUN   TestStoreWins
=== RUN   TestStoreWins/it_records_wins_on_POST
--- PASS: TestStoreWins (0.00s)
    --- PASS: TestStoreWins/it_records_wins_on_POST (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.008s
job.batch "unittest-teststorewins" deleted

All unit tests complete.
```

## Templating
This script will use the below `job-template.yaml` to generate the job for each test case, replacing the different vars surrounded with {{}} with the proper value.
```bash
apiVersion: batch/v1
kind: Job
metadata:
  name: unittest-{{job_name}}
  labels:
    jobgroup: unittest
spec:
  template:
    metadata:
      name: unittest
      labels:
        jobgroup: unittest
    spec:
      containers:
      - name: unittest
        image: golang
        volumeMounts:
        - mountPath: /go/src/{{repo_name}}
          name: src-code-volume
        command: ["bash"]
        args: ["-c",  "cd /go/src/{{path_name}}; go test -v -run {{test_name}}"]
      volumes:
      - name: src-code-volume
        hostPath:
          path: {{volume_path}}
      restartPolicy: Never
```
