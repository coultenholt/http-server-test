## Option 2 w/ Test-Controller
I implemented a test-controller implementation from this implementation https://srossross.github.io/k8s-test-controller/.

### Setup
Deploy the `test-controller`.
```bash
$ kubectl create -f https://srossross.github.io/k8s-test-controller/controller.yaml
```

### Running
This follows the same basic idea as the other implementation, with the exception of using jobs. I am not using the custom types `TestTemplate` and `TestRun`. The script will go through and create multiple `TestTemplate` then create a `TestRun` which triggers off all the tests. Below is an example run. Be sure to use the `run-script.sh` in the `test-controller` directory. 
```bash
$ ./run_tests.sh https://github.com/quii/learn-go-with-tests.git http-server/v5/
Cloning remote repo https://github.com/quii/learn-go-with-tests.git ...
Cloning into 'learn-go-with-tests'...
remote: Enumerating objects: 119, done.
remote: Counting objects: 100% (119/119), done.
remote: Compressing objects: 100% (79/79), done.
remote: Total 3601 (delta 42), reused 101 (delta 36), pack-reused 3482
Receiving objects: 100% (3601/3601), 3.84 MiB | 5.31 MiB/s, done.
Resolving deltas: 100% (1984/1984), done.

Creating TestTemplate testrecordingwinsandretrievingthem.
testtemplate.srossross.github.io/test-testrecordingwinsandretrievingthem created
Creating TestTemplate testgetplayers.
testtemplate.srossross.github.io/test-testgetplayers created
Creating TestTemplate teststorewins.
testtemplate.srossross.github.io/test-teststorewins created
Creating TestRun ...
testrun.srossross.github.io/test-20181226132035 created

Waiting for jobs to complete...
=== RUN   TestStoreWins
=== RUN   TestStoreWins/it_records_wins_on_POST
--- PASS: TestStoreWins (0.00s)
    --- PASS: TestStoreWins/it_records_wins_on_POST (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.035s
pod "test-teststorewins-c5z82" deleted

=== RUN   TestRecordingWinsAndRetrievingThem
--- PASS: TestRecordingWinsAndRetrievingThem (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.008s
pod "test-testrecordingwinsandretrievingthem-cmw5m" deleted

=== RUN   TestGETPlayers
=== RUN   TestGETPlayers/returns_Pepper's_score
=== RUN   TestGETPlayers/returns_Floyd's_score
=== RUN   TestGETPlayers/returns_404_on_missing_players
--- PASS: TestGETPlayers (0.00s)
    --- PASS: TestGETPlayers/returns_Pepper's_score (0.00s)
    --- PASS: TestGETPlayers/returns_Floyd's_score (0.00s)
    --- PASS: TestGETPlayers/returns_404_on_missing_players (0.00s)
PASS
ok  	learn-go-with-tests/http-server/v5	0.010s
pod "test-testgetplayers-d5l5p" deleted

LAST SEEN   FIRST SEEN   COUNT     NAME                  KIND      SUBOBJECT   TYPE      REASON           SOURCE                                                         MESSAGE
18s         18s          1         test-run-events6xxf   TestRun               Normal    TestStart        test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Starting test test-teststorewins
17s         17s          1         test-run-eventzp98n   TestRun               Normal    TestStart        test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Starting test test-testrecordingwinsandretrievingthem
16s         16s          1         test-run-eventtbtxj   TestRun               Normal    TestStart        test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Starting test test-testgetplayers
4s          4s           1         test-run-eventw77xh   TestRun               Normal    TestSuccess      test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Test pod 'test-teststorewins-c5z82' exited with status 'Succeeded'
3s          3s           1         test-run-eventsnkrc   TestRun               Normal    TestSuccess      test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Test pod 'test-testrecordingwinsandretrievingthem-cmw5m' exited with status 'Succeeded'
2s          2s           1         test-run-eventg6dq8   TestRun               Normal    TestRunSuccess   test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Ran 3 tests, 0 failures
2s          2s           1         test-run-event2cfdh   TestRun               Normal    TestSuccess      test-controller, test-controller-deployment-6dbc4ff74d-9c6wj   Test pod 'test-testgetplayers-d5l5p' exited with status 'Succeeded'

Cleaning Up ...
testrun.srossross.github.io "test-20181226132035" deleted
testtemplate.srossross.github.io "test-testgetplayers" deleted
testtemplate.srossross.github.io "test-testrecordingwinsandretrievingthem" deleted
testtemplate.srossross.github.io "test-teststorewins" deleted
All unit tests complete.
```

## Templating
Templating is the same as prior instead of using `kind: Job` we are using `kind: TestTemplate`.
```bash
apiVersion: srossross.github.io/v1alpha1
kind: TestTemplate
metadata:
  name: test-{{test_template_name}}
  labels:
    app: mytest
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
