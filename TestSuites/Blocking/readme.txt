this test causes blocking to test pssdiag

1. connection 1 periodically open a tran and sits on it for 20 seconds
2. ostress spawn 50 threads to try to read from the table repeatedly
3. another ostress spawns 5 threads to cause errors like table doesn't exist repeatedly
