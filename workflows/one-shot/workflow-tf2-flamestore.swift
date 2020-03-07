
/** WORKFLOW SWIFT */

import io;
import sys;
import flamestore;

printf("WORKFLOW PWD: " + getenv("PWD"));

string run_nt3_tf2 = getenv("THIS") / "run-nt3-tf2.sh";
string workspace = argv("workspace");

app (void v) nt3_tf2()
{
  run_nt3_tf2 ;
}

file o1<"out-master.txt">;
file e1<"err-master.txt">;
o1, e1 = flamestore_run_master(workspace);

file o2<"out-storage.txt">;
file e2<"err-storage.txt">;
sleep(30) => o2, e2 = flamestore_format_and_run_storage(workspace, "/dev/shm", 1073741824);

nt3_tf2() => flamestore_shutdown(workspace);
