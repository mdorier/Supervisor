
/** WORKFLOW SWIFT */

import io;
import sys;

printf("WORKFLOW PWD: " + getenv("PWD"));

string run_nt3_tf2 = getenv("THIS") / "run-nt3-tf2.sh";
string workspace = argv("workspace");

app (file out, file err) flamestore_run_master (string workspace) {
    "flamestore" "run" "--master" "--debug" "--workspace" workspace @stdout=out @stderr=err
}

app (file out, file err) flamestore_run_storage (string workspace, string storagespace, int size) {
    "/projects/radix-io/flamestore/Supervisor/workflows/one-shot/run-flamestore-storage.sh" workspace storagespace size @stdout=out @stderr=err
}

app (file out, file err) flamestore_shutdown (string workspace) {
    "flamestore" "shutdown" "--workspace" workspace "--debug" @stdout=out @stderr=err
}

app (void v) nt3_tf2()
{
  run_nt3_tf2 ;
}

file o1<"out-master.txt">;
file e1<"err-master.txt">;
o1, e1 = flamestore_run_master(workspace);

file o2<"out-storage.txt">;
file e2<"err-storage.txt">;
sleep(30) => o2, e2 = flamestore_run_storage(workspace, "/dev/shm", 1073741824);

nt3_tf2() => flamestore_shutdown(workspace);
