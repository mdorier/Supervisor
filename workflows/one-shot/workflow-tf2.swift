
/** WORKFLOW SWIFT */

import io;
import sys;

printf("WORKFLOW PWD: " + getenv("PWD"));

string run_nt3_tf2 = getenv("THIS") / "run-nt3-tf2.sh";

app nt3_tf2()
{
  run_nt3_tf2 ;
}

nt3_tf2();
