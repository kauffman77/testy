# minimal working example of how to get around python
# multiprocessing's corruption of stdin file table; MUST dup2() the
# incoming pipe to fd 0, NOT sys.stdin.fileno()

import os
import sys
import multiprocessing

# create  a child
def runchild(x):
  print(f"Parent pid: {os.getpid()}")
  print(f"stdin: {sys.stdin}")
  (to_child_r,to_child_w) = os.pipe()         # for communication between parent and child
  (fr_child_r,fr_child_w) = os.pipe()
  pid = os.fork()

  # CHILD PROCESS
  if pid == 0:                  
    print(f"stdin: {sys.stdin.fileno()}")
    os.close(to_child_w)
    os.close(fr_child_r)
    # print("redirecting child output",flush=True)
    # os.dup2(to_child_r, sys.stdin.fileno())  # causes hangs
    os.dup2(to_child_r, 0)      # BLACK MAGIC BULLSHIT: must select fd 0 for stdin as python didn't properly maintain stdin
    os.dup2(fr_child_w, sys.stdout.fileno())
    os.dup2(fr_child_w, sys.stderr.fileno())
    cmd = ["seq","5"]           # okay
    cmd = ['bash']              # causes hangs
    os.execvp(cmd[0],cmd)

  # PARENT PROCESS
  print(f"Child PID {pid}")
  os.close(fr_child_w)
  os.close(to_child_r)
  print("parent writing")
  os.write(to_child_w,bytes('seq 5','utf-8'))
  print("parent closing")
  os.close(to_child_w)
  print("parent reading")     # getting a hang here on reading
  stdout_bytes = os.read(fr_child_r,8192)
  print("parent waiting")
  os.waitpid(pid,0)           # or getting a hang here on waiting
  stdout_str = stdout_bytes.decode(encoding='utf-8', errors='strict')
  print(f"Length of output: {len(stdout_str)}")
  print(f"Output:\n{(stdout_str)}")
  return len(stdout_str)

print("########## PART 1 ###############")
print("works when doing a plain fork()")
runchild(1)

print("########## PART 2 ###############")
print("under multiprocessing, Broken, hangs for bash processes")
p = multiprocessing.Process(target=runchild,args=(1,))
p.start()
p.join()

print("########## PART 3 ###############")
with multiprocessing.Pool(os.cpu_count()) as pool:
  for i in pool.imap(runchild, range(12), 1):
    print(f"Done {i}")


